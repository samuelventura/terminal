defmodule SelectTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Select

  test "basic select check" do
    initial = Select.init()

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
             offset: 0,
             on_change: &Select.nop/2
           }

    # getters/setters
    assert Select.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Select.visible(%{visible: :visible}) == :visible
    assert Select.focusable(%{initial | enabled: false}) == false
    assert Select.focusable(%{initial | visible: false}) == false
    assert Select.focusable(%{initial | on_change: nil}) == false
    assert Select.focusable(%{initial | findex: -1}) == false
    assert Select.focused(%{focused: false}) == false
    assert Select.focused(%{focused: true}) == true
    assert Select.focused(initial, true) == %{initial | focused: true}
    assert Select.refocus(:state, :dir) == :state
    assert Select.findex(%{findex: 0}) == 0
    assert Select.children(:state) == []
    assert Select.children(:state, []) == :state

    # update
    on_change = fn index, item -> {index, item} end
    assert Select.update(initial, focused: :any) == initial
    assert Select.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Select.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Select.update(initial, visible: false) == %{initial | visible: false}
    assert Select.update(initial, enabled: false) == %{initial | enabled: false}
    assert Select.update(initial, findex: 1) == %{initial | findex: 1}
    assert Select.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Select.update(initial, selected: 0) == initial
    assert Select.update(initial, count: -1) == initial
    assert Select.update(initial, map: :map) == initial
    assert Select.update(initial, offset: -1) == initial
    assert Select.update(initial, on_change: on_change) == %{initial | on_change: on_change}

    # update items
    assert Select.update(initial, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update items + selected
    assert Select.update(initial, items: [:item0, :item1], selected: 1) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               offset: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # update selected + items
    assert Select.update(initial, selected: 1, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 1,
               offset: 1,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # recalc
    assert Select.update(%{initial | selected: 1, offset: 2}, items: [:item0, :item1]) == %{
             initial
             | items: [:item0, :item1],
               selected: 0,
               offset: 0,
               count: 2,
               map: %{0 => :item0, 1 => :item1}
           }

    # navigation
    assert Select.handle(%{}, {:key, :any, "\t"}) == {%{}, {:focus, :next}}
    assert Select.handle(%{}, {:key, :any, @arrow_right}) == {%{}, {:focus, :next}}
    assert Select.handle(%{}, {:key, @alt, "\t"}) == {%{}, {:focus, :prev}}
    assert Select.handle(%{}, {:key, @alt, @arrow_left}) == {%{}, {:focus, :prev}}
    assert Select.handle(%{}, {:key, 0, "\r"}) == {%{}, {:focus, :next}}

    # triggers
    sample = Select.init(items: [:item0, :item1, :item2], size: {10, 2}, on_change: on_change)

    assert Select.handle(sample, {:key, :any, @arrow_down}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Select.handle(sample, {:key, :any, @page_down}) ==
             {%{sample | selected: 2, offset: 1}, {:item, 2, :item2, {2, :item2}}}

    assert Select.handle(sample, {:key, :any, @hend}) ==
             {%{sample | selected: 2, offset: 1}, {:item, 2, :item2, {2, :item2}}}

    assert Select.handle(sample, {:mouse, @wheel_down, :any, :any, :any}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Select.handle(%{sample | selected: 1}, {:key, :any, @arrow_up}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: 2}, {:key, :any, @page_up}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: 2}, {:key, :any, @home}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: 1}, {:mouse, @wheel_up, :any, :any, :any}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(sample, {:mouse, :any, :any, 1, @mouse_down}) ==
             {%{sample | selected: 1}, {:item, 1, :item1, {1, :item1}}}

    assert Select.handle(sample, {:mouse, :any, :any, 2, @mouse_down}) ==
             {%{sample | selected: 2, offset: 1}, {:item, 2, :item2, {2, :item2}}}

    # retriggers
    assert Select.handle(sample, {:key, @alt, "\r"}) == {sample, {:item, 0, :item0, {0, :item0}}}

    # nops
    assert Select.handle(%{}, nil) == {%{}, nil}
    assert Select.handle(initial, {:mouse, :any, :any, :any, :any}) == {initial, nil}
    assert Select.handle(initial, {:key, :any, :any}) == {initial, nil}
    assert Select.handle(sample, {:key, :any, @arrow_up}) == {sample, nil}
    assert Select.handle(sample, {:key, :any, @page_up}) == {sample, nil}
    assert Select.handle(sample, {:key, :any, @home}) == {sample, nil}
    assert Select.handle(sample, {:mouse, @wheel_up, :any, :any, :any}) == {sample, nil}

    assert Select.handle(%{sample | selected: 2}, {:key, :any, @arrow_down}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(%{sample | selected: 2}, {:key, :any, @page_down}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(%{sample | selected: 2}, {:key, :any, @hend}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(%{sample | selected: 2}, {:mouse, @wheel_down, :any, :any, :any}) ==
             {%{sample | selected: 2, offset: 1}, nil}

    assert Select.handle(sample, {:mouse, :any, :any, 0, @mouse_down}) ==
             {sample, nil}

    assert Select.handle(sample, {:mouse, :any, :any, 3, @mouse_down}) ==
             {sample, nil}

    # offset (any key/mouse should correct it)
    assert Select.handle(%{sample | selected: -1}, {:key, :any, @arrow_up}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.handle(%{sample | selected: -1}, {:mouse, @wheel_up, :any, :any, :any}) ==
             {sample, {:item, 0, :item0, {0, :item0}}}

    assert Select.update(%{sample | selected: -1}, selected: 0) == sample
  end
end
