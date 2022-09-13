defmodule Terminal.Demo.Effects do
  use Terminal.React

  def effects(react, %{origin: origin, size: size}) do
    use_effect(react, :always, fn ->
      log("Always effect")
      fn -> log("Always cleanup") end
    end)

    use_effect(react, :once, [], fn ->
      log("Once effect")
      fn -> log("Once cleanup") end
    end)

    use_effect(react, :count, [:count], fn ->
      log("Count effect")
      fn -> log("Count cleanup") end
    end)

    markup :main, Panel, origin: origin, size: size do
      markup(1, Label, origin: {0, 0}, text: "Click and change tabs")
      markup(2, Label, origin: {0, 1}, text: "to see logged effects.")
      markup(3, Label, origin: {0, 2}, text: "See source code as well.")
    end
  end
end
