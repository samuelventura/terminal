defmodule RadioTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Radio

  test "basic radio check" do
    initial = Radio.init()

    # defaults
    assert initial == %{
             count: 0,
             map: %{},
             selected: 0,
             focused: false,
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             size: {0, 0},
             items: [],
             origin: {0, 0},
             on_change: &Radio.nop/2
           }

    # panel getters/setters
    assert Radio.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Radio.focusable(%{initial | enabled: false}) == false
    assert Radio.focusable(%{initial | visible: false}) == false
    assert Radio.focusable(%{initial | on_change: nil}) == false
    assert Radio.focusable(%{initial | findex: -1}) == false
    assert Radio.focused(%{focused: false}) == false
    assert Radio.focused(%{focused: true}) == true
    assert Radio.focused(initial, true) == %{initial | focused: true}
    assert Radio.findex(%{findex: 0}) == 0
    assert Radio.children(:state) == []
    assert Radio.children(:state, []) == :state
    assert Radio.refocus(:state, :dir) == :state

    # react update
    on_change = fn index, value -> {index, value} end
    assert Radio.update(initial, focused: true) == initial
    assert Radio.update(initial, count: -1) == initial
    assert Radio.update(initial, map: :map) == initial
    assert Radio.update(initial, selected: -1) == %{initial | selected: -1}
    assert Radio.update(initial, visible: false) == %{initial | visible: false}
    assert Radio.update(initial, enabled: false) == %{initial | enabled: false}
    assert Radio.update(initial, findex: 1) == %{initial | findex: 1}
    assert Radio.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Radio.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Radio.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Radio.update(initial, on_change: on_change) == %{initial | on_change: on_change}

    # reset of calculated props
    assert Radio.update(%{initial | selected: 1}, items: ["item0", "item1"]) == %{
             initial
             | items: ["item0", "item1"],
               count: 2,
               map: %{0 => "item0", 1 => "item1"},
               selected: 0
           }

    # triggers and navigation
    assert Radio.handle(%{}, {:key, :any, "\t"}) == {%{}, {:focus, :next}}
    assert Radio.handle(%{}, {:key, :any, @arrow_down}) == {%{}, {:focus, :next}}
    assert Radio.handle(%{}, {:key, :any, "\r"}) == {%{}, {:focus, :next}}
    assert Radio.handle(%{}, {:key, @alt, @arrow_up}) == {%{}, {:focus, :prev}}

    # ignore keyboard events
    assert Radio.handle(initial, {:key, :any, @arrow_left}) == {initial, nil}
    assert Radio.handle(initial, {:key, :any, @arrow_right}) == {initial, nil}

    # up/down/enter
    dual = Radio.init(items: ["item0", "item1"], size: {0, 2}, on_change: on_change)
    assert Radio.handle(dual, {:key, :any, @arrow_left}) == {dual, nil}

    assert Radio.handle(%{dual | selected: 1}, {:key, :any, @arrow_right}) ==
             {%{dual | selected: 1}, nil}

    assert Radio.handle(dual, {:key, :any, @arrow_right}) ==
             {%{dual | selected: 1}, {:item, 1, "item1"}}

    assert Radio.handle(%{dual | selected: 1}, {:key, :any, @arrow_left}) ==
             {dual, {:item, 0, "item0"}}

    assert Radio.handle(dual, {:key, @alt, "\r"}) == {dual, {:item, 0, "item0"}}
  end
end
