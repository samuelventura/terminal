defmodule InputTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Input

  test "basic input check" do
    initial = Input.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             password: false,
             text: "",
             cursor: 0,
             on_change: &Input.nop/1
           }

    # getters/setters
    assert Input.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Input.visible(%{visible: :visible}) == :visible
    assert Input.focusable(%{initial | enabled: false}) == false
    assert Input.focusable(%{initial | visible: false}) == false
    assert Input.focusable(%{initial | on_change: nil}) == false
    assert Input.focusable(%{initial | findex: -1}) == false
    assert Input.focused(%{focused: false}) == false
    assert Input.focused(%{focused: true}) == true
    assert Input.focused(initial, true) == %{initial | focused: true}
    assert Input.refocus(:state, :dir) == :state
    assert Input.findex(%{findex: 0}) == 0
    assert Input.children(:state) == []
    assert Input.children(:state, []) == :state

    # update
    on_change = fn value -> value end
    assert Input.update(initial, focused: :any) == initial
    assert Input.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Input.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Input.update(initial, visible: false) == %{initial | visible: false}
    assert Input.update(initial, enabled: false) == %{initial | enabled: false}
    assert Input.update(initial, findex: 1) == %{initial | findex: 1}
    assert Input.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Input.update(initial, password: true) == %{initial | password: true}
    assert Input.update(initial, text: "text") == %{initial | text: "text", cursor: 4}
    assert Input.update(initial, text: "text", cursor: 1) == %{initial | text: "text", cursor: 4}
    assert Input.update(initial, cursor: 1, text: "text") == %{initial | text: "text", cursor: 4}
    assert Input.update(initial, cursor: -1) == initial
    assert Input.update(initial, cursor: 1) == initial
    assert Input.update(initial, on_change: on_change) == %{initial | on_change: on_change}
    assert Input.update(initial, on_change: nil) == initial

    # navigation
    assert Input.handle(%{}, {:key, :any, "\t"}) == {%{}, {:focus, :next}}
    assert Input.handle(%{}, {:key, :any, @arrow_down}) == {%{}, {:focus, :next}}
    assert Input.handle(%{}, {:key, @alt, "\t"}) == {%{}, {:focus, :prev}}
    assert Input.handle(%{}, {:key, @alt, @arrow_up}) == {%{}, {:focus, :prev}}
    assert Input.handle(%{}, {:key, :any, "\r"}) == {%{}, {:focus, :next}}

    # triggers
    sample = Input.init(size: {10, 1}, on_change: on_change)

    assert Input.handle(sample, {:key, 0, "a"}) ==
             {%{sample | text: "a", cursor: 1}, {:text, "a", "a"}}

    assert Input.handle(%{sample | text: "a", cursor: 1}, {:key, 0, "b"}) ==
             {%{sample | text: "ab", cursor: 2}, {:text, "ab", "ab"}}

    assert Input.handle(%{sample | text: "a", cursor: 0}, {:key, 0, "b"}) ==
             {%{sample | text: "ba", cursor: 1}, {:text, "ba", "ba"}}

    assert Input.handle(%{sample | text: "ab", cursor: 1}, {:key, 0, "c"}) ==
             {%{sample | text: "acb", cursor: 2}, {:text, "acb", "acb"}}

    assert Input.handle(%{sample | text: "abc", cursor: 1}, {:key, 0, @delete}) ==
             {%{sample | text: "ac", cursor: 1}, {:text, "ac", "ac"}}

    assert Input.handle(%{sample | text: "abc", cursor: 1}, {:key, 0, @backspace}) ==
             {%{sample | text: "bc", cursor: 0}, {:text, "bc", "bc"}}

    # retriggers
    assert Input.handle(%{sample | text: "abc", cursor: 1}, {:key, @alt, "\r"}) ==
             {%{sample | text: "abc", cursor: 1}, {:text, "abc", "abc"}}

    # mouse
    assert Input.handle(%{sample | text: "abc"}, {:mouse, :any, 2, :any, @mouse_down}) ==
             {%{sample | text: "abc", cursor: 2}, nil}

    assert Input.handle(%{sample | text: "abc"}, {:mouse, :any, 4, :any, @mouse_down}) ==
             {%{sample | text: "abc", cursor: 3}, nil}

    # nops
    assert Input.handle(%{}, :any) == {%{}, nil}
    assert Input.handle(%{}, {:mouse, @wheel_up, :any, :any, :any}) == {%{}, nil}
    assert Input.handle(%{}, {:mouse, @wheel_down, :any, :any, :any}) == {%{}, nil}
    assert Input.handle(%{}, {:mouse, :any, :any, :any, @mouse_up}) == {%{}, nil}
    assert Input.handle(initial, {:key, :any, @arrow_left}) == {initial, nil}
    assert Input.handle(initial, {:key, :any, @arrow_right}) == {initial, nil}
    assert Input.handle(initial, {:key, :any, @delete}) == {initial, nil}
    assert Input.handle(initial, {:key, :any, @backspace}) == {initial, nil}
    assert Input.handle(initial, {:key, :any, @home}) == {initial, nil}
    assert Input.handle(initial, {:key, :any, @hend}) == {initial, nil}
    assert Input.handle(initial, {:key, :any, "a"}) == {initial, nil}

    assert Input.handle(%{initial | size: {10, 1}, text: "a"}, {:key, :any, @backspace}) ==
             {%{initial | size: {10, 1}, text: "a"}, nil}

    assert Input.handle(%{initial | size: {10, 1}, text: "a", cursor: 1}, {:key, :any, @delete}) ==
             {%{initial | size: {10, 1}, text: "a", cursor: 1}, nil}
  end
end
