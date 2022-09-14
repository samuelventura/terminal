defmodule ButtonTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Button

  test "basic button check" do
    initial = Button.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {2, 1},
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             text: "",
             on_click: &Button.nop/0
           }

    # control getters/setters
    assert Button.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Button.focusable(%{enabled: false}) == false
    assert Button.focusable(%{visible: false}) == false
    assert Button.focusable(%{on_click: nil}) == false
    assert Button.focusable(%{findex: -1}) == false
    assert Button.focused(%{focused: false}) == false
    assert Button.focused(%{focused: true}) == true
    assert Button.focused(initial, true) == %{initial | focused: true}
    assert Button.refocus(:state, :dir) == :state
    assert Button.findex(%{findex: 0}) == 0
    assert Button.children(:state) == []
    assert Button.children(:state, []) == :state

    # react update
    on_click = fn -> :click end
    assert Button.update(initial, focused: true) == initial
    assert Button.update(initial, visible: false) == %{initial | visible: false}
    assert Button.update(initial, enabled: false) == %{initial | enabled: false}
    assert Button.update(initial, findex: 1) == %{initial | findex: 1}
    assert Button.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Button.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Button.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Button.update(initial, text: "text") == %{initial | text: "text"}
    assert Button.update(initial, on_click: on_click) == %{initial | on_click: on_click}

    # triggers and navigation
    assert Button.handle(%{}, {:key, :any, "\t"}) == {%{}, {:focus, :next}}
    assert Button.handle(%{}, {:key, :any, @arrow_down}) == {%{}, {:focus, :next}}
    assert Button.handle(%{}, {:key, :any, @arrow_right}) == {%{}, {:focus, :next}}
    assert Button.handle(%{}, {:key, @alt, "\t"}) == {%{}, {:focus, :prev}}
    assert Button.handle(%{}, {:key, @alt, @arrow_up}) == {%{}, {:focus, :prev}}
    assert Button.handle(%{}, {:key, @alt, @arrow_left}) == {%{}, {:focus, :prev}}

    assert Button.handle(%{on_click: on_click}, {:key, :any, "\r"}) ==
             {%{on_click: on_click}, :click}
  end
end
