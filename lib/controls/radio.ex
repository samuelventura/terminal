defmodule Terminal.Radio do
  @behaviour Terminal.Window
  use Terminal.Const
  alias Terminal.Check
  alias Terminal.Radio
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
    findex = Keyword.get(opts, :findex, 0)
    on_change = Keyword.get(opts, :on_change, &Radio.nop/2)

    {count, map} = to_map(items)

    state = %{
      focused: focused,
      count: count,
      map: map,
      items: items,
      size: size,
      theme: theme,
      visible: visible,
      findex: findex,
      enabled: enabled,
      origin: origin,
      selected: selected,
      on_change: on_change
    }

    check(state)
  end

  def nop(_index, _value), do: nil

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_change: nil}), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def refocus(state, _), do: state
  def focused(%{focused: focused}), do: focused
  def focused(state, focused), do: %{state | focused: focused}
  def findex(%{findex: findex}), do: findex
  def children(_), do: []
  def children(state, _), do: state

  def update(%{items: items} = state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused, :count, :map])

    props =
      case props do
        %{items: ^items} ->
          props

        %{items: items} ->
          {count, map} = to_map(items)
          props = Map.put(props, :map, map)
          props = Map.put(props, :count, count)
          props = Map.put(props, :selected, 0)
          %{props | items: items}

        _ ->
          props
      end

    state = Map.merge(state, props)
    check(state)
  end

  def handle(%{items: []} = state, {:key, _, _}), do: {state, nil}
  def handle(%{items: []} = state, {:mouse, _, _}), do: {state, nil}

  def handle(state, {:key, _, @arrow_right}) do
    %{count: count, selected: selected} = state
    next = min(selected + 1, count - 1)
    state = %{state | selected: next}
    trigger(state, selected)
  end

  def handle(state, {:key, _, @arrow_left}) do
    %{selected: selected} = state
    next = max(0, selected - 1)
    state = %{state | selected: next}
    trigger(state, selected)
  end

  def handle(state, {:mouse, _, mx, _, @mouse_down}) do
    %{count: count, map: map, selected: selected} = state

    list = for i <- 0..(count - 1), do: {i, String.length("#{map[i]}")}

    list =
      for {i, l} <- list, reduce: [] do
        [] -> [{i, 0, l}]
        [{_, _, e} | _] = list -> [{i, e + 1, e + 1 + l} | list]
      end

    Enum.find_value(list, {state, nil}, fn {i, s, e} ->
      case mx >= s && mx < e do
        false -> false
        true -> trigger(%{state | selected: i}, selected)
      end
    end)
  end

  def handle(state, {:key, @alt, "\t"}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, "\t"}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_down}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_up}), do: {state, {:focus, :prev}}
  def handle(state, {:key, @alt, "\r"}), do: {state, trigger(state)}
  def handle(state, {:key, _, "\r"}), do: {state, {:focus, :next}}
  def handle(state, _event), do: {state, nil}

  def render(%{visible: false}, canvas), do: canvas

  def render(state, canvas) do
    %{
      map: map,
      focused: focused,
      enabled: enabled,
      theme: theme,
      count: count,
      selected: selected
    } = state

    theme = Theme.get(theme)

    {canvas, _} =
      for i <- 0..(count - 1), reduce: {canvas, 0} do
        {canvas, x} ->
          prefix =
            case i do
              0 -> ""
              _ -> " "
            end

          canvas = Canvas.move(canvas, x, 0)
          canvas = Canvas.clear(canvas, :colors)
          canvas = Canvas.write(canvas, prefix)

          canvas =
            case {enabled, focused, i == selected} do
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

          item = Map.get(map, i)
          item = "#{item}"
          canvas = Canvas.write(canvas, item)
          len = String.length(prefix) + String.length(item)
          {canvas, x + len}
      end

    canvas
  end

  defp trigger(state, selected) do
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
    Check.assert_integer(:selected, state.selected)
    Check.assert_function(:on_change, state.on_change, 2)
    state
  end
end
