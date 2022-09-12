defmodule Terminal.Select do
  @behaviour Terminal.Window
  use Terminal.Const
  alias Terminal.Check
  alias Terminal.Select
  alias Terminal.Canvas
  alias Terminal.Theme

  def init(opts \\ []) do
    items = Keyword.get(opts, :items, [])
    size = Keyword.get(opts, :size, {0, 0})
    visible = Keyword.get(opts, :visible, true)
    focused = Keyword.get(opts, :focused, false)
    enabled = Keyword.get(opts, :enabled, true)
    origin = Keyword.get(opts, :origin, {0, 0})
    selected = Keyword.get(opts, :selected, 0)
    theme = Keyword.get(opts, :theme, :default)
    offset = Keyword.get(opts, :offset, 0)
    findex = Keyword.get(opts, :findex, 0)
    on_change = Keyword.get(opts, :on_change, &Select.nop/2)

    {count, map} = to_map(items)

    state = %{
      focused: focused,
      count: count,
      map: map,
      items: items,
      offset: offset,
      size: size,
      theme: theme,
      visible: visible,
      findex: findex,
      enabled: enabled,
      origin: origin,
      selected: selected,
      on_change: on_change
    }

    state = offset_update(state)
    check(state)
  end

  def nop(_index, _value), do: nil

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
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
          {count, map} = to_map(items)
          props = Map.put(props, :map, map)
          props = Map.put(props, :count, count)
          props = Map.put(props, :selected, 0)
          props = Map.put(props, :offset, 0)
          %{props | items: items}

        _ ->
          props
      end

    state = Map.merge(state, props)
    state = offset_update(state)
    check(state)
  end

  def handle(state, {:key, _, @arrow_down}) do
    %{count: count, selected: selected} = state
    next = min(selected + 1, count - 1)
    state = %{state | selected: next}
    state = offset_update(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
    end
  end

  def handle(state, {:key, _, @arrow_up}) do
    %{selected: selected} = state
    next = max(0, selected - 1)
    state = %{state | selected: next}
    state = offset_update(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
    end
  end

  def handle(state, {:key, _, @page_down}) do
    %{count: count, selected: selected, size: {_, height}} = state
    next = min(selected + height, count - 1)
    state = %{state | selected: next}
    state = offset_update(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
    end
  end

  def handle(state, {:key, _, @page_up}) do
    %{selected: selected, size: {_, height}} = state
    next = max(0, selected - height)
    state = %{state | selected: next}
    state = offset_update(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
    end
  end

  def handle(state, {:key, _, @hend}) do
    %{count: count, selected: selected} = state
    state = %{state | selected: count - 1}
    state = offset_update(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
    end
  end

  def handle(state, {:key, _, @home}) do
    %{selected: selected} = state
    state = %{state | selected: 0}
    state = offset_update(state)

    case state.selected do
      ^selected -> {state, nil}
      _ -> {state, trigger(state)}
    end
  end

  def handle(state, {:key, @alt, "\t"}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, "\t"}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_right}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_left}), do: {state, {:focus, :prev}}
  def handle(state, {:key, @alt, "\r"}), do: {state, trigger(state)}
  def handle(state, {:key, _, "\r"}), do: {state, {:focus, :next}}
  def handle(state, _event), do: {state, nil}

  def render(%{visible: false}, canvas), do: canvas

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

  defp offset_update(
         %{
           selected: selected,
           size: {_, height},
           count: count,
           offset: offset
         } = state
       ) do
    selected = if selected < 0, do: -1, else: selected
    selected = if selected >= count, do: -1, else: selected

    offsel = max(0, selected)
    offmin = max(0, offsel - height + 1)
    offset = if offset < offmin, do: offmin, else: offset
    offset = if offset > offsel, do: offsel, else: offset

    %{state | selected: selected, offset: offset}
  end

  defp trigger(%{selected: selected, map: map, on_change: on_change}) do
    item = map[selected]
    resp = on_change.(selected, item)
    {:item, selected, item, resp}
  end

  defp to_map(map) do
    for item <- map, reduce: {0, %{}} do
      {count, map} ->
        {count + 1, Map.put(map, count, item)}
    end
  end

  defp check(state) do
    Check.assert_map(:map, state.map)
    Check.assert_integer(:count, state.count)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_boolean(:focused, state.focused)
    Check.assert_atom(:theme, state.theme)
    Check.assert_integer(:findex, state.findex)
    Check.assert_integer(:offset, state.offset)
    Check.assert_integer(:selected, state.selected)
    Check.assert_function(:on_change, state.on_change, 2)
    state
  end
end