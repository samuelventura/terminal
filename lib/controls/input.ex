defmodule Terminal.Input do
  @behaviour Terminal.Control
  use Terminal.Const
  alias Terminal.Check
  alias Terminal.Input
  alias Terminal.Canvas
  alias Terminal.Theme

  def init(opts \\ []) do
    text = Keyword.get(opts, :text, "")
    size = Keyword.get(opts, :size, {String.length(text), 1})
    visible = Keyword.get(opts, :visible, true)
    focused = Keyword.get(opts, :focused, false)
    enabled = Keyword.get(opts, :enabled, true)
    theme = Keyword.get(opts, :theme, :default)
    cursor = Keyword.get(opts, :cursor, String.length(text))
    origin = Keyword.get(opts, :origin, {0, 0})
    findex = Keyword.get(opts, :findex, 0)
    password = Keyword.get(opts, :password, false)
    on_change = Keyword.get(opts, :on_change, &Input.nop/1)

    state = %{
      focused: focused,
      cursor: cursor,
      findex: findex,
      visible: visible,
      enabled: enabled,
      password: password,
      theme: theme,
      text: text,
      size: size,
      origin: origin,
      on_change: on_change
    }

    check(state)
  end

  def nop(_value), do: nil

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

  def update(%{text: text} = state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:focused, :cursor])

    props =
      case props do
        %{text: ^text} ->
          props

        %{text: text} ->
          cursor = String.length(text)
          props = Map.put(props, :text, text)
          props = Map.put(props, :cursor, cursor)
          %{props | text: text}

        _ ->
          props
      end

    Map.merge(state, props)
  end

  def handle(state, {:key, @alt, "\t"}), do: {state, {:focus, :prev}}
  def handle(state, {:key, _, "\t"}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_down}), do: {state, {:focus, :next}}
  def handle(state, {:key, _, @arrow_up}), do: {state, {:focus, :prev}}
  def handle(state, {:key, @alt, "\r"}), do: {state, trigger(state)}
  def handle(state, {:key, _, "\r"}), do: {state, {:focus, :next}}

  def handle(%{cursor: cursor} = state, {:key, _, @arrow_left}) do
    cursor = if cursor > 0, do: cursor - 1, else: cursor
    state = %{state | cursor: cursor}
    {state, nil}
  end

  def handle(%{cursor: cursor, text: text} = state, {:key, _, @arrow_right}) do
    count = String.length(text)
    cursor = if cursor < count, do: cursor + 1, else: cursor
    state = %{state | cursor: cursor}
    {state, nil}
  end

  def handle(state, {:key, _, @home}) do
    state = %{state | cursor: 0}
    {state, nil}
  end

  def handle(%{text: text} = state, {:key, _, @hend}) do
    count = String.length(text)
    state = %{state | cursor: count}
    {state, nil}
  end

  def handle(%{cursor: cursor, text: text} = state, {:key, _, @backspace}) do
    case cursor do
      0 ->
        {state, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        {prefix, _} = String.split_at(prefix, cursor - 1)
        cursor = cursor - 1
        text = "#{prefix}#{suffix}"
        state = %{state | text: text, cursor: cursor}
        {state, trigger(state)}
    end
  end

  def handle(%{cursor: cursor, text: text} = state, {:key, _, @delete}) do
    count = String.length(text)

    case cursor do
      ^count ->
        {state, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        suffix = String.slice(suffix, 1..String.length(suffix))
        text = "#{prefix}#{suffix}"
        state = %{state | text: text}
        {state, trigger(state)}
    end
  end

  def handle(%{cursor: cursor, text: text} = state, {:key, 0, data}) when is_binary(data) do
    %{size: {width, _}} = state
    count = String.length(text)

    case count do
      ^width ->
        {state, nil}

      _ ->
        {prefix, suffix} = String.split_at(text, cursor)
        text = "#{prefix}#{data}#{suffix}"
        state = %{state | text: text, cursor: cursor + 1}
        {state, trigger(state)}
    end
  end

  def handle(state, {:mouse, @wheel_up, _, _, _}), do: {state, nil}
  def handle(state, {:mouse, @wheel_down, _, _, _}), do: {state, nil}

  def handle(%{text: text} = state, {:mouse, _, mx, _, @mouse_down}) do
    cursor = min(mx, String.length(text))
    state = %{state | cursor: cursor}
    {state, nil}
  end

  def handle(state, _event), do: {state, nil}

  def render(%{visible: false}, canvas), do: canvas

  def render(state, canvas) do
    %{
      focused: focused,
      theme: theme,
      cursor: cursor,
      enabled: enabled,
      password: password,
      size: {width, _},
      text: text
    } = state

    theme = Theme.get(theme)
    canvas = Canvas.clear(canvas, :colors)
    empty = String.length(text) == 0
    dotted = empty && !focused && enabled

    canvas =
      case {enabled, focused, dotted} do
        {_, _, true} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_readonly)
          Canvas.color(canvas, :back, theme.back_readonly)

        {false, _, _} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_disabled)
          Canvas.color(canvas, :back, theme.back_disabled)

        {true, true, _} ->
          canvas = Canvas.color(canvas, :fore, theme.fore_focused)
          Canvas.color(canvas, :back, theme.back_focused)

        _ ->
          canvas = Canvas.color(canvas, :fore, theme.fore_editable)
          Canvas.color(canvas, :back, theme.back_editable)
      end

    text =
      case {password, dotted} do
        {_, true} -> String.duplicate("_", width)
        {true, _} -> String.duplicate("*", String.length(text))
        _ -> text
      end

    text = String.pad_trailing(text, width)
    canvas = Canvas.move(canvas, 0, 0)
    canvas = Canvas.write(canvas, text)

    case {focused, enabled, cursor < width} do
      {true, true, true} ->
        Canvas.cursor(canvas, cursor, 0)

      _ ->
        canvas
    end
  end

  defp trigger(%{on_change: on_change, text: text}) do
    resp = on_change.(text)
    {:text, text, resp}
  end

  defp check(state) do
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_boolean(:focused, state.focused)
    Check.assert_boolean(:password, state.password)
    Check.assert_atom(:theme, state.theme)
    Check.assert_integer(:findex, state.findex)
    Check.assert_string(:text, state.text)
    Check.assert_function(:on_change, state.on_change, 1)
    Check.assert_integer(:cursor, state.cursor)
    state
  end
end
