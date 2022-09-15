defmodule AppTest do
  use ExUnit.Case
  alias Terminal.App
  alias Terminal.Panel
  import Terminal.React, only: [markup: 3, markup: 4]

  defp even(_react, %{i: 0}), do: markup(:root, Panel, [])
  defp even(_react, %{i: 1}), do: nil

  defp even(_react, %{i: i}) do
    case rem(i, 2) do
      0 -> markup(:root, Panel, [])
      1 -> nil
    end
  end

  test "app realize check" do
    # do not use this technique for long lists of children
    # nils get currently replaced by a {Nil, nil} mote
    # use a generator with explicit filter instead
    app = fn _react, _ ->
      markup :root, Panel, [] do
        markup(0, &even/2, i: 0)
        markup(1, &even/2, i: 1)
        markup(2, &even/2, i: 2)
        markup(3, &even/2, i: 3)
      end
    end

    {state, nil} = App.app_init(app, [])
    App.handle(state, :event)
  end
end
