defmodule Terminal.Demo do
  use Terminal.App
  import Terminal.Demo.Colors
  import Terminal.Demo.Controls
  import Terminal.Demo.Modals
  import Terminal.Demo.Counter
  import Terminal.Demo.Timers
  import Terminal.Demo.Effects
  import Terminal.Demo.Unsafe

  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    on_event = fn e -> log("Event #{inspect(e)}") end
    app_init(&main/2, size: size, on_event: on_event)
  end

  def main(react, %{size: size}) do
    {index, set_index} = use_state(react, :index, 0)
    {name, set_name} = use_state(react, :name, "Colors")

    on_demo = fn index, item ->
      log("Demo #{index} #{item}")
      set_index.(index)
      set_name.(item)
    end

    markup :main, Panel, size: size do
      markup(:label, Label, text: "Terminal UIs with Reactish API - Demo")

      # group into same panel to gain focus on border click
      markup :select, Panel, origin: {0, 1}, size: {12, 10} do
        markup(:frame, Frame,
          size: {12, 10},
          text: "Demos"
        )

        markup(:select, Select,
          origin: {1, 1},
          size: {10, 8},
          selected: index,
          on_change: on_demo,
          items: [
            "Colors",
            "Controls",
            "Modals",
            "Counter",
            "Timers",
            "Effects",
            "Unsafe"
          ]
        )
      end

      # group into same panel to gain focus on border click
      markup :tab, Panel, origin: {12, 1}, size: {42, 12} do
        markup(:frame, Frame,
          origin: {0, 0},
          size: {42, 12},
          text: name
        )

        markup(index, &tabs/2, tab: index, origin: {1, 1}, size: {40, 10})
      end
    end
  end

  def tabs(_react, %{tab: tab, origin: origin, size: size}) do
    case tab do
      0 -> markup(tab, &colors/2, origin: origin, size: size)
      1 -> markup(tab, &controls/2, origin: origin, size: size)
      2 -> markup(tab, &modals/2, origin: origin, size: size)
      3 -> markup(tab, &counter/2, origin: origin, size: size)
      4 -> markup(tab, &timers/2, origin: origin, size: size)
      5 -> markup(tab, &effects/2, origin: origin, size: size)
      6 -> markup(tab, &unsafe/2, origin: origin, size: size)
    end
  end
end
