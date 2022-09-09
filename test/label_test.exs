defmodule LabelTest do
  use ExUnit.Case
  alias Terminal.Label
  alias Terminal.Theme

  test "basic label check" do
    theme = Theme.get(:default)

    initial = Label.init()

    # defaults
    assert initial == %{
             text: "",
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             bgcolor: theme.back_readonly,
             fgcolor: theme.fore_readonly
           }

    # panel getter/setters
    assert Label.bounds(%{origin: {1, 2}, size: {3, 4}}) === {1, 2, 3, 4}
    assert Label.focusable(%{}) === false
    assert Label.focused(%{}) === false
    assert Label.focused(%{}, false) === %{}
    assert Label.focused(%{}, true) === %{}
    assert Label.findex(%{findex: 0}) === -1
    assert Label.children(:state) == []
    assert Label.children(:state, []) == :state

    # react update
    assert Label.update(initial, text: "text") == %{initial | text: "text"}
    assert Label.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Label.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Label.update(initial, visible: false) == %{initial | visible: false}
    assert Label.update(initial, bgcolor: :red) == %{initial | bgcolor: :red}
    assert Label.update(initial, fgcolor: :blue) == %{initial | fgcolor: :blue}

    # nops
    assert Label.handle(%{}, nil) === {%{}, nil}

    assert Label.render(%{visible: false}, nil) == nil
  end
end
