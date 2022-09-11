defmodule ParserTest do
  use ExUnit.Case
  alias Terminal.Parser

  # should detect key duplication at any nesting level
  test "parser duplicate key detection check" do
    {:__block__, [], inner} =
      quote do
        markup(:same, Panel, [])
        markup(:same, Panel, [])
      end

    assert_parsing(inner)

    {:markup, [], [:root, {:__aliases__, [alias: false], [:Panel]}, [], [do: inner]]} =
      quote do
        markup :root, Panel, [] do
          markup(:same, Panel, [])
          markup(:same, Panel, [])
        end
      end

    assert_parsing(inner)

    {:markup, [], [:root, {:__aliases__, [alias: false], [:Panel]}, [], [do: inner]]} =
      quote do
        markup :root, Panel, [] do
          markup(:same, Panel, [])

          markup :same, Panel, [] do
          end
        end
      end

    assert_parsing(inner)

    {:markup, [], [:root, {:__aliases__, [alias: false], [:Panel]}, [], [do: inner]]} =
      quote do
        markup :root, Panel, [] do
          markup :same, Panel, [] do
          end

          markup(:same, Panel, [])
        end
      end

    assert_parsing(inner)

    {:markup, [], [:root, {:__aliases__, [alias: false], [:Panel]}, [], [do: inner]]} =
      quote do
        markup :root, Panel, [] do
          markup :same, Panel, [] do
          end

          markup :same, Panel, [] do
          end
        end
      end

    assert_parsing(inner)

    {:markup, [],
     [
       :root,
       {:__aliases__, [alias: false], [:Panel]},
       [],
       [
         do:
           {:markup, [],
            [
              :root,
              {:__aliases__, [alias: false], [:Panel]},
              [],
              [
                do: inner
              ]
            ]}
       ]
     ]} =
      quote do
        markup :root, Panel, [] do
          markup :root, Panel, [] do
            markup :same, Panel, [] do
            end

            markup :same, Panel, [] do
            end
          end
        end
      end

    assert_parsing(inner)
  end

  defp assert_parsing(inner) do
    assert_raise RuntimeError, "Duplicated key: same", fn ->
      Parser.parse(inner)
    end
  end
end
