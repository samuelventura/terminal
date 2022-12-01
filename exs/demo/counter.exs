defmodule Terminal.Demo.Counter do
  use Terminal.React

  def counter(react, %{origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)

    on_delta = fn delta -> set_count.(count + delta) end

    # buttons disabled on invalid range to show autorefocus
    markup :main, Panel, origin: origin, size: size do
      markup(:label, Label, origin: {0, 0}, size: {12, 1}, text: "#{count}")

      # unneeded handler wrapper added to demo wrapper support
      markup(:increment, Button,
        origin: {0, 1},
        size: {12, 1},
        enabled: rem(count, 3) != 2,
        text: "Increment",
        on_click: fn -> on_delta.(+1) end
      )

      markup(:decrement, Button,
        origin: {0, 2},
        size: {12, 1},
        text: "Decrement",
        enabled: rem(count, 3) != 0,
        on_click: fn -> on_delta.(-1) end
      )
    end
  end
end
