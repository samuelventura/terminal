defmodule LabelTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Label
  alias Terminal.Theme

  test "basic label check" do
    theme = Theme.get(:default)

    initial = Label.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             text: "",
             back: theme.back_readonly,
             fore: theme.fore_readonly
           }

    # panel getter/setters
    assert Label.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Label.focusable(%{}) == false
    assert Label.focused(%{}) == false
    assert Label.focused(%{}, false) == %{}
    assert Label.focused(%{}, true) == %{}
    assert Label.refocus(:state, :dir) == :state
    assert Label.findex(%{findex: 0}) == -1
    assert Label.children(:state) == []
    assert Label.children(:state, []) == :state

    # update
    assert Label.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Label.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Label.update(initial, visible: false) == %{initial | visible: false}
    assert Label.update(initial, text: "text") == %{initial | text: "text"}
    assert Label.update(initial, back: @red) == %{initial | back: @red}
    assert Label.update(initial, fore: @red) == %{initial | fore: @red}

    # nops
    assert Label.handle(%{}, nil) == {%{}, nil}

    assert Label.render(%{visible: false}, nil) == nil
  end
end
