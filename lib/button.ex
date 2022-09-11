defmodule Terminal.Button do
  @behaviour Terminal.Window
  alias Terminal.Check
  alias Terminal.Button
  alias Terminal.Canvas
  alias Terminal.Theme

  def init(opts \\ []) do
    text = Keyword.get(opts, :text, "")
    size = Keyword.get(opts, :size, {String.length(text) + 2, 1})
    visible = Keyword.get(opts, :visible, true)
    focused = Keyword.get(opts, :focused, false)
    enabled = Keyword.get(opts, :enabled, true)
    origin = Keyword.get(opts, :origin, {0, 0})
    theme = Keyword.get(opts, :theme, :default)
    findex = Keyword.get(opts, :findex, 0)
    on_click = Keyword.get(opts, :on_click, &Button.nop/0)

    state = %{
      focused: focused,
      visible: visible,
      enabled: enabled,
      findex: findex,
      theme: theme,
      size: size,
      text: text,
      origin: origin,
      on_click: on_click
    }

    check(state)
  end

  def nop(), do: nil

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{on_click: nil}), do: false
  def focusable(%{findex: findex}), do: findex >= 0
  def focused(%{focused: focused}), do: focused
  def focused(state, focused), do: %{state | focused: focused}
  def refocus(state, _), do: state
  def findex(%{findex: findex}), do: findex
  def children(_), do: []
  def children(state, _), do: state

  def update(state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused])
    state = Map.merge(state, props)
    check(state)
  end

  def handle(state, {:key, _, "\t"}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, :arrow_down}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, :arrow_up}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, :arrow_right}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, :arrow_left}), do: {state, {:focus, :prev}}
  def handle(%{on_click: on_click} = state, {:key, _, "\r"}), do: {state, on_click.()}
  def handle(state, _event), do: {state, nil}

  def render(%{visible: false}, canvas), do: canvas

  def render(state, canvas) do
    %{
      text: text,
      theme: theme,
      focused: focused,
      size: {width, _},
      enabled: enabled
    } = state

    theme = Theme.get(theme)

    canvas =
      case {enabled, focused} do
        {false, _} ->
          canvas = Canvas.color(canvas, :fgcolor, theme.fore_disabled)
          Canvas.color(canvas, :bgcolor, theme.back_disabled)

        {true, true} ->
          canvas = Canvas.color(canvas, :fgcolor, theme.fore_focused)
          Canvas.color(canvas, :bgcolor, theme.back_focused)

        _ ->
          canvas = Canvas.color(canvas, :fgcolor, theme.fore_editable)
          Canvas.color(canvas, :bgcolor, theme.back_editable)
      end

    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, "[")
    canvas = Canvas.write(canvas, String.duplicate(" ", width - 2))
    canvas = Canvas.write(canvas, "]")
    offset = div(width - String.length(text), 2)
    canvas = Canvas.move(canvas, offset, 0)
    Canvas.write(canvas, text)
  end

  defp check(state) do
    Check.assert_string(:text, state.text)
    Check.assert_point2d(:origin, state.origin)
    Check.assert_point2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_boolean(:focused, state.focused)
    Check.assert_atom(:theme, state.theme)
    Check.assert_integer(:findex, state.findex)
    Check.assert_function(:on_click, state.on_click, 0)
    state
  end
end
