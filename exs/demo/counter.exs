defmodule Terminal.Demo.Counter do
  use Terminal.React

  def counter(react, %{origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)

    on_increment = fn -> set_count.(count + 1) end
    on_decrement = fn -> set_count.(count - 1) end

    # buttons disabled on invalid range to show autorefocus
    markup :main, Panel, origin: origin, size: size do
      markup(:label, Label, origin: {0, 0}, size: {12, 1}, text: "#{count}")

      markup(:increment, Button,
        origin: {0, 1},
        size: {12, 1},
        enabled: rem(count, 3) != 2,
        text: "Increment",
        on_click: on_increment
      )

      markup(:decrement, Button,
        origin: {0, 2},
        size: {12, 1},
        text: "Decrement",
        enabled: rem(count, 3) != 0,
        on_click: on_decrement
      )
    end
  end
end
