defmodule Terminal.Checkbox do
  @behaviour Terminal.Control
  use Terminal.Const
  alias Terminal.Check
  alias Terminal.Checkbox
  alias Terminal.Canvas
  alias Terminal.Theme

  def init(opts \\ []) do
    text = Keyword.get(opts, :text, "")
    origin = Keyword.get(opts, :origin, {0, 0})
    size = Keyword.get(opts, :size, {String.length(text) + 3, 1})
    visible = Keyword.get(opts, :visible, true)
    enabled = Keyword.get(opts, :enabled, true)
    findex = Keyword.get(opts, :findex, 0)
    theme = Keyword.get(opts, :theme, :default)
    checked = Keyword.get(opts, :checked, false)
    on_change = Keyword.get(opts, :on_change, &Checkbox.nop/1)

    state = %{
      focused: false,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      theme: theme,
      text: text,
      checked: checked,
      on_change: on_change
    }

    check(state)
  end

  def nop(_), do: nil

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

  def update(state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused])
    state = Map.merge(state, props)
    check(state)
  end

  def handle(state, {:key, @alt, "\t"}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, "\t"}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_down}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_up}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, @arrow_right}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_left}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, "\r"}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, " "}), do: toggle(state)
  def handle(state, {:mouse, @wheel_up, _, _, _}), do: {state, nil}
  def handle(state, {:mouse, @wheel_down, _, _, _}), do: {state, nil}
  def handle(state, {:mouse, _, _, _, @mouse_down}), do: toggle(state)
  def handle(state, _event), do: {state, nil}

  def render(%{visible: false}, canvas), do: canvas

  def render(state, canvas) do
    %{
      text: text,
      theme: theme,
      checked: checked,
      focused: focused,
      size: {width, _},
      enabled: enabled
    } = state

    theme = Theme.get(theme)

    canvas =
      case {enabled, focused} do
        {false, _} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_disabled)
          Canvas.color(canvas, :back, theme.back_disabled)

        {true, true} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_focused)
          Canvas.color(canvas, :back, theme.back_focused)

        _ ->
          canvas = Canvas.color(canvas, :fore, theme.fore_editable)
          Canvas.color(canvas, :back, theme.back_editable)
      end

    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, "[")
    canvas = Canvas.write(canvas, if(checked, do: "x", else: " "))
    canvas = Canvas.write(canvas, "]")
    text = String.pad_trailing(text, width - 3)
    Canvas.write(canvas, text)
  end

  defp toggle(%{on_change: on_change, checked: checked} = state) do
    state = Map.put(state, :checked, !checked)
    {state, on_change.(!checked)}
  end

  defp check(state) do
    Check.assert_boolean(:focused, state.focused)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_gte(:findex, state.findex, -1)
    Check.assert_atom(:theme, state.theme)
    Check.assert_string(:text, state.text)
    Check.assert_boolean(:checked, state.checked)
    Check.assert_function(:on_change, state.on_change, 1)
    state
  end
end
