defmodule SelectTest do
  use ExUnit.Case
  alias Terminal.Select

  test "basic select check" do
    initial = Select.init()

    # defaults
    assert initial == %{
             count: 0,
             map: %{},
             offset: 0,
             selected: 0,
             focused: false,
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             size: {0, 0},
             items: [],
             origin: {0, 0},
             on_change: &Select.nop/2
           }

    # panel getters/setters
    assert Select.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Select.focusable(%{initial | enabled: false}) == false
    assert Select.focusable(%{initial | visible: false}) == false
    assert Select.focusable(%{initial | on_change: nil}) == false
    assert Select.focusable(%{initial | findex: -1}) == false
    assert Select.focused(%{focused: false}) == false
    assert Select.focused(%{focused: true}) == true
    assert Select.focused(initial, true) == %{initial | focused: true}
    assert Select.findex(%{findex: 0}) == 0
    assert Select.children(:state) == []
    assert Select.children(:state, []) == :state

    # react update
    on_change = fn index, value -> {index, value} end
    assert Select.update(initial, focused: true) == initial
    assert Select.update(initial, count: -1) == initial
    assert Select.update(initial, map: :map) == initial
    assert Select.update(initial, offset: -1) == initial
    assert Select.update(initial, selected: -1) == %{initial | selected: -1}
    assert Select.update(initial, visible: false) == %{initial | visible: false}
    assert Select.update(initial, enabled: false) == %{initial | enabled: false}
    assert Select.update(initial, findex: 1) == %{initial | findex: 1}
    assert Select.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Select.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Select.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Select.update(initial, on_change: on_change) == %{initial | on_change: on_change}

    # reset of calculated props
    assert Select.update(%{initial | selected: 1, offset: 2}, items: ["item0", "item1"]) == %{
             initial
             | items: ["item0", "item1"],
               count: 2,
               map: %{0 => "item0", 1 => "item1"},
               selected: 0,
               offset: 0
           }

    assert Select.handle(%{}, {:key, nil, "\t"}) == {%{}, {:focus, :next}}

    assert Select.handle(%{initial | on_change: on_change}, {:key, nil, "\r"}) ==
             {%{initial | on_change: on_change}, {:item, 0, nil}}

    assert Select.handle(initial, {:key, nil, :arrow_up}) == {initial, nil}
    assert Select.handle(initial, {:key, nil, :arrow_down}) == {%{initial | offset: 1}, nil}

    # up/down/enter
    dual = Select.init(items: ["item0", "item1"], size: {0, 2}, on_change: on_change)
    assert Select.handle(dual, {:key, nil, "\r"}) == {dual, {:item, 0, "item0"}}
    assert Select.handle(dual, {:key, nil, :arrow_up}) == {dual, nil}

    assert Select.handle(%{dual | selected: 1}, {:key, nil, :arrow_down}) ==
             {%{dual | selected: 1}, nil}

    assert Select.handle(dual, {:key, nil, :arrow_down}) ==
             {%{dual | selected: 1}, {:item, 1, "item1"}}

    assert Select.handle(%{dual | selected: 1}, {:key, nil, :arrow_up}) ==
             {dual, {:item, 0, "item0"}}

    # offset
    dual = Select.init(items: ["item0", "item1"], size: {0, 1})

    assert Select.handle(dual, {:key, nil, :arrow_down}) ==
             {%{dual | offset: 1, selected: 1}, {:item, 1, "item1"}}

    assert Select.handle(%{dual | offset: 1, selected: 1}, {:key, nil, :arrow_up}) ==
             {dual, {:item, 0, "item0"}}
  end
end
