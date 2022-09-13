defmodule Terminal.Label do
  @behaviour Terminal.Control
  alias Terminal.Check
  alias Terminal.Canvas
  alias Terminal.Theme

  def init(opts \\ []) do
    text = Keyword.get(opts, :text, "")
    origin = Keyword.get(opts, :origin, {0, 0})
    size = Keyword.get(opts, :size, {String.length(text), 1})
    visible = Keyword.get(opts, :visible, true)
    theme = Keyword.get(opts, :theme, :default)
    theme = Theme.get(theme)
    back = Keyword.get(opts, :back, theme.back_readonly)
    fore = Keyword.get(opts, :fore, theme.fore_readonly)

    state = %{
      text: text,
      size: size,
      origin: origin,
      visible: visible,
      back: back,
      fore: fore
    }

    check(state)
  end

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def refocus(state, _), do: state
  def focused(state, _), do: state
  def focused(_), do: false
  def focusable(_), do: false
  def findex(_), do: -1
  def children(_), do: []
  def children(state, _), do: state

  def update(state, props) do
    props = Enum.into(props, %{})
    state = Map.merge(state, props)
    check(state)
  end

  def handle(state, _event), do: {state, nil}

  def render(%{visible: false}, canvas), do: canvas

  def render(state, canvas) do
    %{
      text: text,
      size: {w, _h},
      back: back,
      fore: fore
    } = state

    text = String.pad_trailing(text, w)
    canvas = Canvas.color(canvas, :back, back)
    canvas = Canvas.color(canvas, :fore, fore)
    canvas = Canvas.move(canvas, 0, 0)
    Canvas.write(canvas, text)
  end

  defp check(state) do
    Check.assert_string(:text, state.text)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_in_range(:fore, state.fore, 0..15)
    Check.assert_in_range(:back, state.back, 0..7)
    state
  end
end
