defmodule CheckboxTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Checkbox

  test "basic checkbox check" do
    initial = Checkbox.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {3, 1},
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             text: "",
             checked: false,
             on_change: &Checkbox.nop/1
           }

    # control getters/setters
    assert Checkbox.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Checkbox.focusable(%{enabled: false}) == false
    assert Checkbox.focusable(%{visible: false}) == false
    assert Checkbox.focusable(%{on_change: nil}) == false
    assert Checkbox.focusable(%{findex: -1}) == false
    assert Checkbox.focused(%{focused: false}) == false
    assert Checkbox.focused(%{focused: true}) == true
    assert Checkbox.focused(initial, true) == %{initial | focused: true}
    assert Checkbox.refocus(:state, :dir) == :state
    assert Checkbox.findex(%{findex: 0}) == 0
    assert Checkbox.children(:state) == []
    assert Checkbox.children(:state, []) == :state

    # react update
    on_change = fn checked -> checked end
    assert Checkbox.update(initial, focused: true) == initial
    assert Checkbox.update(initial, visible: false) == %{initial | visible: false}
    assert Checkbox.update(initial, enabled: false) == %{initial | enabled: false}
    assert Checkbox.update(initial, findex: 1) == %{initial | findex: 1}
    assert Checkbox.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Checkbox.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Checkbox.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Checkbox.update(initial, text: "text") == %{initial | text: "text"}
    assert Checkbox.update(initial, on_change: on_change) == %{initial | on_change: on_change}

    # triggers and navigation
    assert Checkbox.handle(%{}, {:key, :any, "\t"}) == {%{}, {:focus, :next}}
    assert Checkbox.handle(%{}, {:key, :any, @arrow_down}) == {%{}, {:focus, :next}}
    assert Checkbox.handle(%{}, {:key, :any, @arrow_right}) == {%{}, {:focus, :next}}
    assert Checkbox.handle(%{}, {:key, :any, "\r"}) == {%{}, {:focus, :next}}
    assert Checkbox.handle(%{}, {:key, @alt, "\t"}) == {%{}, {:focus, :prev}}
    assert Checkbox.handle(%{}, {:key, @alt, @arrow_up}) == {%{}, {:focus, :prev}}
    assert Checkbox.handle(%{}, {:key, @alt, @arrow_left}) == {%{}, {:focus, :prev}}

    assert Checkbox.handle(%{on_change: on_change, checked: false}, {:key, :any, " "}) ==
             {%{on_change: on_change, checked: true}, true}

    assert Checkbox.handle(
             %{on_change: on_change, checked: false},
             {:mouse, :any, :any, :any, @mouse_down}
           ) ==
             {%{on_change: on_change, checked: true}, true}
  end
end
