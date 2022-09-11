defmodule Terminal.Label do
  @behaviour Terminal.Window
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
    bgcolor = Keyword.get(opts, :bgcolor, theme.back_readonly)
    fgcolor = Keyword.get(opts, :fgcolor, theme.fore_readonly)

    state = %{
      text: text,
      size: size,
      origin: origin,
      visible: visible,
      bgcolor: bgcolor,
      fgcolor: fgcolor
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
      bgcolor: bgcolor,
      fgcolor: fgcolor
    } = state

    text = String.pad_trailing(text, w)
    canvas = Canvas.color(canvas, :bgcolor, bgcolor)
    canvas = Canvas.color(canvas, :fgcolor, fgcolor)
    canvas = Canvas.move(canvas, 0, 0)
    Canvas.write(canvas, text)
  end

  defp check(state) do
    Check.assert_string(:text, state.text)
    Check.assert_point2d(:origin, state.origin)
    Check.assert_point2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_inlist(:bgcolor, state.bgcolor, Theme.colors())
    Check.assert_inlist(:fgcolor, state.fgcolor, Theme.colors())
    state
  end
end
