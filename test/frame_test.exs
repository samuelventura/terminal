defmodule FrameTest do
  use ExUnit.Case
  alias Terminal.Frame
  alias Terminal.Theme

  test "basic frame check" do
    theme = Theme.get(:default)

    initial = Frame.init()

    # defaults
    assert initial == %{
             text: "",
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             bgcolor: theme.back_readonly,
             fgcolor: theme.fore_readonly,
             bracket: false,
             style: :single
           }

    # panel getter/setters
    assert Frame.bounds(%{origin: {1, 2}, size: {3, 4}}) === {1, 2, 3, 4}
    assert Frame.focusable(%{}) === false
    assert Frame.focused(%{}) === false
    assert Frame.focused(%{}, false) === %{}
    assert Frame.focused(%{}, true) === %{}
    assert Frame.findex(%{findex: 0}) === -1
    assert Frame.children(:state) == []
    assert Frame.children(:state, []) == :state

    # react update
    assert Frame.update(initial, text: "text") == %{initial | text: "text"}
    assert Frame.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Frame.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Frame.update(initial, visible: false) == %{initial | visible: false}
    assert Frame.update(initial, bgcolor: :bgcolor) == %{initial | bgcolor: :bgcolor}
    assert Frame.update(initial, fgcolor: :fgcolor) == %{initial | fgcolor: :fgcolor}

    # nops
    assert Frame.handle(%{}, nil) === {%{}, nil}

    assert Frame.render(%{visible: false}, nil) == nil
  end
end
