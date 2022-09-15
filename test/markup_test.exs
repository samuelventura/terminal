defmodule MarkupTest do
  use ExUnit.Case
  import Terminal.React, only: [markup: 3, markup: 4]

  test "markup ast check" do
    # no body
    ast = markup(:key, Module, [])
    assert ast == {:key, Module, [], []}

    # empty body
    ast =
      markup :key, Module, [] do
      end

    assert ast == {:key, Module, [], []}

    # children list
    ast =
      markup :key, Module, [] do
        for i <- 0..1, do: markup(i, Child, [])
      end

    assert ast == {:key, Module, [], [{0, Child, [], []}, {1, Child, [], []}]}

    # nested children list
    ast =
      markup :key, Module, [] do
        for i <- 0..1 do
          for j <- 0..1 do
            markup(2 * i + j, Child, [])
          end
        end
      end

    assert ast ==
             {:key, Module, [],
              [{0, Child, [], []}, {1, Child, [], []}, {2, Child, [], []}, {3, Child, [], []}]}

    # nil child removal
    ast =
      markup :key, Module, [] do
        for i <- 0..1 do
          case rem(i, 2) do
            0 -> markup(i, Child, [])
            1 -> nil
          end
        end
      end

    assert ast == {:key, Module, [], [{0, Child, [], []}]}
  end
end
