defmodule Terminal.Select do
  @behaviour Terminal.Control
  use Terminal.Const
  alias Terminal.Control
  alias Terminal.Check
  alias Terminal.Select
  alias Terminal.Canvas
  alias Terminal.Theme

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {0, 0})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    theme = Map.get(opts, :theme, :default)
    items = Map.get(opts, :items, [])
    selected = Map.get(opts, :selected, 0)
    offset = Map.get(opts, :offset, 0)
    on_change = Map.get(opts, :on_change, &Select.nop/2)

    {count, map} = internals(items)

    state = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      theme: theme,
      findex: findex,
      items: items,
      selected: selected,
      count: count,
      map: map,
      offset: offset,
      on_change: on_change
    }

    state = recalculate(state)
    check(state)
  end

  def nop(_index, _value), do: nil

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_change: nil}), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(state, focused), do: %{state | focused: focused}
  def refocus(state, _), do: state
  def findex(%{findex: findex}), do: findex
  def children(_), do: []
  def children(state, _), do: state

  def update(%{items: items} = state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused, :count, :map, :offset])

    props =
      case props do
        %{items: ^items} ->
          props

        %{items: items} ->
          {count, map} = internals(items)
          props = Map.put(props, :map, map)
          props = Map.put(props, :count, count)
          props = Map.put(props, :offset, 0)
          props = Map.put_new(props, :selected, 0)
          %{props | items: items}

        _ ->
          props
      end

    props = Control.coalesce(props, :on_change, &Select.nop/2)
    state = Control.merge(state, props)
    state = recalculate(state)
    check(state)
  end

  def handle(%{items: []} = state, {:key, _, _}), do: {state, nil}
  def handle(%{items: []} = state, {:mouse, _, _}), do: {state, nil}

  def handle(state, {:key, _, @arrow_down}) do
    %{count: count, selected: selected} = state
    next = min(selected + 1, count - 1)
    trigger(state, next, selected)
  end

  def handle(state, {:key, _, @arrow_up}) do
    %{selected: selected} = state
    next = max(0, selected - 1)
    trigger(state, next, selected)
  end

  def handle(state, {:key, _, @page_down}) do
    %{count: count, selected: selected, size: {_, height}} = state
    next = min(selected + height, count - 1)
    trigger(state, next, selected)
  end

  def handle(state, {:key, _, @page_up}) do
    %{selected: selected, size: {_, height}} = state
    next = max(0, selected - height)
    trigger(state, next, selected)
  end

  def handle(state, {:key, _, @hend}) do
    %{count: count, selected: selected} = state
    trigger(state, count - 1, selected)
  end

  def handle(state, {:key, _, @home}) do
    %{selected: selected} = state
    trigger(state, 0, selected)
  end

  def handle(state, {:mouse, @wheel_up, _, _, _}) do
    handle(state, {:key, nil, @arrow_up})
  end

  def handle(state, {:mouse, @wheel_down, _, _, _}) do
    handle(state, {:key, nil, @arrow_down})
  end

  def handle(state, {:mouse, _, _, my, @mouse_down}) do
    %{count: count, selected: selected, offset: offset} = state
    next = my + offset
    next = if next >= count, do: selected, else: next
    trigger(state, next, selected)
  end

  def handle(state, {:key, @alt, "\t"}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, "\t"}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_right}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_left}), do: {state, {:focus, :prev}}
  def handle(state, {:key, @alt, "\r"}), do: {state, trigger(state)}
  def handle(state, {:key, _, "\r"}), do: {state, {:focus, :next}}
  def handle(state, _event), do: {state, nil}

  def render(state, canvas) do
    %{
      map: map,
      theme: theme,
      enabled: enabled,
      size: {width, height},
      focused: focused,
      selected: selected,
      offset: offset
    } = state

    theme = Theme.get(theme)

    for i <- 0..(height - 1), reduce: canvas do
      canvas ->
        canvas = Canvas.move(canvas, 0, i)
        canvas = Canvas.clear(canvas, :colors)

        canvas =
          case {enabled, focused, i == selected - offset} do
            {false, _, _} ->
              canvas = Canvas.color(canvas, :fore, theme.fore_disabled)
              Canvas.color(canvas, :back, theme.back_disabled)

            {true, true, true} ->
              canvas = Canvas.color(canvas, :fore, theme.fore_focused)
              Canvas.color(canvas, :back, theme.back_focused)

            {true, false, true} ->
              canvas = Canvas.color(canvas, :fore, theme.fore_selected)
              Canvas.color(canvas, :back, theme.back_selected)

            _ ->
              canvas = Canvas.color(canvas, :fore, theme.fore_editable)
              Canvas.color(canvas, :back, theme.back_editable)
          end

        item = Map.get(map, i + offset, "")
        item = "#{item}"
        item = String.pad_trailing(item, width)
        Canvas.write(canvas, item)
    end
  end

  defp recalculate(
         %{
           selected: selected,
           size: {_, height},
           count: count,
           offset: offset
         } = state
       ) do
    selected = if selected < 0, do: -1, else: selected
    selected = if selected >= count, do: -1, else: selected
    selected = if count > 0, do: selected, else: -1

    offsel = max(0, selected)
    offhei = max(1, height)
    offmin = max(0, offsel - offhei + 1)
    offset = if offset < offmin, do: offmin, else: offset
    offset = if offset > offsel, do: offsel, else: offset

    %{state | selected: selected, offset: offset}
  end

  defp trigger(state, next, selected) do
    state = %{state | selected: next}
    state = recalculate(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
    end
  end

  defp trigger(%{selected: selected, map: map, on_change: on_change}) do
    item = map[selected]
    resp = on_change.(selected, item)
    {:item, selected, item, resp}
  end

  defp internals(map) do
    for item <- map, reduce: {0, %{}} do
      {count, map} ->
        {count + 1, Map.put(map, count, item)}
    end
  end

  defp check(state) do
    Check.assert_boolean(:focused, state.focused)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_gte(:findex, state.findex, -1)
    Check.assert_atom(:theme, state.theme)
    Check.assert_list(:items, state.items)
    Check.assert_integer(:selected, state.selected)
    Check.assert_map(:map, state.map)
    Check.assert_gte(:count, state.count, 0)
    Check.assert_gte(:offset, state.offset, 0)
    Check.assert_function(:on_change, state.on_change, 2)
    state
  end
end
