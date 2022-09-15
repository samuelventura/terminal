defmodule FrameTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Frame
  alias Terminal.Theme

  test "basic frame check" do
    theme = Theme.get(:default)

    initial = Frame.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             bracket: false,
             style: :single,
             text: "",
             back: theme.back_readonly,
             fore: theme.fore_readonly
           }

    # control getter/setters
    assert Frame.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Frame.visible(%{visible: :visible}) == :visible
    assert Frame.focusable(%{}) == false
    assert Frame.focused(%{}) == false
    assert Frame.focused(%{}, false) == %{}
    assert Frame.focused(%{}, true) == %{}
    assert Frame.refocus(:state, :dir) == :state
    assert Frame.findex(%{findex: 0}) == -1
    assert Frame.shortcut(:state) == nil
    assert Frame.children(:state) == []
    assert Frame.children(:state, []) == :state
    assert Frame.modal(:state) == false

    # update
    assert Frame.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Frame.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Frame.update(initial, visible: false) == %{initial | visible: false}
    assert Frame.update(initial, bracket: true) == %{initial | bracket: true}
    assert Frame.update(initial, style: :double) == %{initial | style: :double}
    assert Frame.update(initial, text: "text") == %{initial | text: "text"}
    assert Frame.update(initial, back: @red) == %{initial | back: @red}
    assert Frame.update(initial, fore: @red) == %{initial | fore: @red}

    # nops
    assert Frame.handle(%{}, :any) == {%{}, nil}
  end
end
