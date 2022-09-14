defmodule PanelTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Panel

  test "basic panel check" do
    initial = Panel.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             enabled: true,
             findex: 0,
             root: false,
             index: [],
             children: %{},
             focus: nil
           }

    # control getters/setters
    assert Panel.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Panel.focusable(%{enabled: false}) == false
    assert Panel.focusable(%{visible: false}) == false
    assert Panel.focusable(%{findex: -1}) == false
    assert Panel.focused(%{focused: false}) == false
    assert Panel.focused(%{focused: true}) == true
    assert Panel.focused(initial, true) == %{initial | focused: true}
    # assert Panel.refocus(:state, :dir) == :state
    assert Panel.findex(%{findex: 0}) == 0
    # assert Panel.children(:state) == []
    # assert Panel.children(:state, []) == :state
  end
end
