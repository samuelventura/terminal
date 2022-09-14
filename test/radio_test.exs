defmodule RadioTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Radio

  test "basic radio check" do
    initial = Radio.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             items: [],
             selected: -1,
             count: 0,
             map: %{},
             on_change: &Radio.nop/2
           }

    # getters/setters
    assert Radio.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Radio.visible(%{visible: :visible}) == :visible
    assert Radio.focusable(%{initial | enabled: false}) == false
    assert Radio.focusable(%{initial | visible: false}) == false
    assert Radio.focusable(%{initial | on_change: nil}) == false
    assert Radio.focusable(%{initial | findex: -1}) == false
    assert Radio.focused(%{focused: false}) == false
    assert Radio.focused(%{focused: true}) == true
    assert Radio.focused(initial, true) == %{initial | focused: true}
    assert Radio.refocus(:state, :dir) == :state
    assert Radio.findex(%{findex: 0}) == 0
    assert Radio.children(:state) == []
    assert Radio.children(:state, []) == :state

    # update
    on_change = fn index, item -> {index, item} end
    assert Radio.update(initial, focused: :any) == initial
    assert Radio.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Radio.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Radio.update(initial, visible: false) == %{initial | visible: false}
    assert Radio.update(initial, enabled: false) == %{initial | enabled: false}
    assert Radio.update(initial, findex: 1) == %{initial | findex: 1}
    assert Radio.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Radio.update(initial, selected: 0) == initial
    assert Radio.update(initial, count: -1) == initial
    assert Radio.update(initial, map: :map) == initial
    assert Radio.update(initial, on_change: on_change) == %{initial | on_change: on_change}

    # update items
    assert Radio.update(initial, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update items + selected
    assert Radio.update(initial, items: [:item0, :item1], selected: 1) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update selected + items
    assert Radio.update(initial, selected: 1, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # recalc
    assert Radio.update(%{initial | selected: 1}, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # navigation
    assert Radio.handle(%{}, {:key, :any, "\t"}) == {%{}, {:focus, :next}}
    assert Radio.handle(%{}, {:key, :any, @arrow_down}) == {%{}, {:focus, :next}}
    assert Radio.handle(%{}, {:key, @alt, "\t"}) == {%{}, {:focus, :prev}}
    assert Radio.handle(%{}, {:key, @alt, @arrow_up}) == {%{}, {:focus, :prev}}
    assert Radio.handle(%{}, {:key, :any, "\r"}) == {%{}, {:focus, :next}}

    # triggers
    sample = Radio.init(items: [:item0, :item1, :item2], size: {10, 1}, on_change: on_change)

    assert Radio.handle(sample, {:key, :any, @arrow_right}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Radio.handle(sample, {:key, :any, @hend}) ==
             {%{sample | selected: 2}, {:item, 2, :item2, {2, :item2}}}

    assert Radio.handle(sample, {:mouse, @wheel_down, :any, :any, :any}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Radio.handle(%{sample | selected: 1}, {:key, :any, @arrow_left}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(%{sample | selected: 2}, {:key, :any, @home}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(%{sample | selected: 1}, {:mouse, @wheel_up, :any, :any, :any}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(sample, {:mouse, :any, 7, :any, @mouse_down}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Radio.handle(%{sample | selected: 2}, {:mouse, :any, 3, :any, @mouse_down}) ==
             {%{sample | selected: 0}, {:item, 0, :item0, {0, :item0}}}

    # retriggers
    assert Radio.handle(sample, {:key, @alt, "\r"}) == {sample, {:item, 0, :item0, {0, :item0}}}

    # nops
    assert Radio.handle(%{}, nil) == {%{}, nil}
    assert Radio.handle(initial, {:mouse, :any, :any, :any, :any}) == {initial, nil}
    assert Radio.handle(initial, {:key, :any, :any}) == {initial, nil}
    assert Radio.handle(sample, {:key, :any, @arrow_left}) == {sample, nil}
    assert Radio.handle(sample, {:key, :any, @home}) == {sample, nil}
    assert Radio.handle(sample, {:mouse, @wheel_up, :any, :any, :any}) == {sample, nil}

    assert Radio.handle(%{sample | selected: 2}, {:key, :any, @arrow_right}) ==
             {%{sample | selected: 2}, nil}

    assert Radio.handle(%{sample | selected: 2}, {:key, :any, @hend}) ==
             {%{sample | selected: 2}, nil}

    assert Radio.handle(%{sample | selected: 2}, {:mouse, @wheel_down, :any, :any, :any}) ==
             {%{sample | selected: 2}, nil}

    assert Radio.handle(%{sample | selected: 2}, {:mouse, :any, 5, :any, @mouse_down}) ==
             {%{sample | selected: 2}, nil}

    # offset (any key/mouse should correct it)
    assert Radio.handle(%{sample | selected: -1}, {:key, :any, @arrow_left}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.handle(%{sample | selected: -1}, {:mouse, @wheel_up, :any, :any, :any}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Radio.update(%{sample | selected: -1}, selected: 0) == sample
  end
end
