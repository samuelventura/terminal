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
    assert Panel.findex(%{findex: 0}) == 0
    # refocus
    # get children
    # set children

    # update
    assert Panel.update(initial, focused: :any) == initial
    assert Panel.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Panel.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Panel.update(initial, visible: false) == %{initial | visible: false}
    assert Panel.update(initial, enabled: false) == %{initial | enabled: false}
    assert Panel.update(initial, findex: -1) == %{initial | findex: -1}
    assert Panel.update(initial, root: :any) == initial
    assert Panel.update(initial, index: :any) == initial
    assert Panel.update(initial, children: :any) == initial
    assert Panel.update(initial, focus: :any) == initial
  end
end
