defmodule Terminal.Demo do
  use Terminal.App
  alias Terminal.Panel
  alias Terminal.Label
  alias Terminal.Button
  alias Terminal.Frame
  alias Terminal.Select

  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    app_init(&main/2, size: size)
  end

  def main(react, %{size: size}) do
    {demo, set_demo} = use_state(react, :demo, 0)

    on_change = fn index, _ -> set_demo.(index) end

    tab_origin = {13, 0}
    tab_size = {20, 20}

    markup :main, Panel, size: size do
      markup(:frame, Frame,
        origin: {0, 0},
        size: {12, 5},
        text: "Demos"
      )

      markup(:select, Select,
        origin: {1, 1},
        size: {10, 3},
        selected: demo,
        on_change: on_change,
        items: ["Counter1", "Counter2"]
      )

      markup(:counter1, &counter/2, visible: demo == 0, origin: tab_origin, size: tab_size)
      markup(:counter2, &counter/2, visible: demo == 1, origin: tab_origin, size: tab_size)
    end
  end

  def counter(react, %{visible: visible, origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)

    increment = fn -> set_count.(count + 1) end
    decrement = fn -> set_count.(count - 1) end

    markup :main, Panel, visible: visible, origin: origin, size: size do
      markup(:label, Label, origin: {0, 0}, size: {12, 1}, text: "#{count}")

      markup(:inc, Button,
        origin: {0, 1},
        size: {12, 1},
        enabled: rem(count, 3) != 2,
        text: "Increment",
        on_click: increment
      )

      markup(:dec, Button,
        origin: {0, 2},
        size: {12, 1},
        text: "Decrement",
        enabled: rem(count, 3) != 0,
        on_click: decrement
      )
    end
  end
end
