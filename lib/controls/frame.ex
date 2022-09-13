defmodule Terminal.Frame do
  @behaviour Terminal.Control
  alias Terminal.Check
  alias Terminal.Canvas
  alias Terminal.Theme

  def init(opts \\ []) do
    size = Keyword.get(opts, :size, {0, 0})
    text = Keyword.get(opts, :text, "")
    style = Keyword.get(opts, :style, :single)
    visible = Keyword.get(opts, :visible, true)
    bracket = Keyword.get(opts, :bracket, false)
    origin = Keyword.get(opts, :origin, {0, 0})
    theme = Keyword.get(opts, :theme, :default)
    theme = Theme.get(theme)
    back = Keyword.get(opts, :back, theme.back_readonly)
    fore = Keyword.get(opts, :fore, theme.fore_readonly)

    state = %{
      size: size,
      style: style,
      visible: visible,
      bracket: bracket,
      text: text,
      origin: origin,
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
      bracket: bracket,
      style: style,
      size: {width, height},
      text: text,
      back: back,
      fore: fore
    } = state

    canvas = Canvas.clear(canvas, :colors)
    canvas = Canvas.color(canvas, :back, back)
    canvas = Canvas.color(canvas, :fore, fore)
    last = height - 1

    canvas =
      for r <- 0..last, reduce: canvas do
        canvas ->
          canvas = Canvas.move(canvas, 0, r)
          horizontal = border_char(style, :horizontal)
          vertical = border_char(style, :vertical)

          border =
            case r do
              0 ->
                [
                  border_char(style, :top_left),
                  String.duplicate(horizontal, width - 2),
                  border_char(style, :top_right)
                ]

              ^last ->
                [
                  border_char(style, :bottom_left),
                  String.duplicate(horizontal, width - 2),
                  border_char(style, :bottom_right)
                ]

              _ ->
                [vertical, String.duplicate(" ", width - 2), vertical]
            end

          Canvas.write(canvas, border)
      end

    canvas = Canvas.move(canvas, 1, 0)

    text =
      case bracket do
        true -> "[#{text}]"
        false -> " #{text} "
      end

    Canvas.write(canvas, text)
  end

  defp check(state) do
    Check.assert_string(:text, state.text)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:bracket, state.bracket)
    Check.assert_in_range(:fore, state.fore, 0..15)
    Check.assert_in_range(:back, state.back, 0..7)
    Check.assert_in_list(:style, state.style, [:single, :double])
    state
  end

  # https://en.wikipedia.org/wiki/Box-drawing_character
  defp border_char(style, elem) do
    case style do
      :single ->
        case elem do
          :top_left -> "┌"
          :top_right -> "┐"
          :bottom_left -> "└"
          :bottom_right -> "┘"
          :horizontal -> "─"
          :vertical -> "│"
        end

      :double ->
        case elem do
          :top_left -> "╔"
          :top_right -> "╗"
          :bottom_left -> "╚"
          :bottom_right -> "╝"
          :horizontal -> "═"
          :vertical -> "║"
        end

      _ ->
        " "
    end
  end
end
