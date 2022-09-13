defmodule Terminal.Demo.Timer do
  use Terminal.React

  def timer(react, %{origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)
    {timer, set_timer} = use_state(react, :timer, nil)

    # callback required as timer handler
    # to access latest count value otherwise
    # its value at set time will be captured
    on_tick =
      use_callback(react, :timer, fn ->
        log("Timer #{count}")
        set_count.(count + 1)
      end)

    cleanup =
      use_callback(react, :cleanup, fn ->
        if timer != nil do
          log("Cleanup timer...")
          clear_interval(timer)
          # as expected this excepts when called from a cleanup
          # because the timer state key is gone at that point
          # set_timer.(nil)
        end
      end)

    # install cleanup to ensure timer is
    # stopped when this tab is unmounted
    use_effect(react, :once, [], fn ->
      log("Timer effect")

      # callback required as cleanup
      # to access latest timer value
      # otherwise nil will be captured
      fn ->
        log("Timer cleanup")
        cleanup.()
      end
    end)

    on_start = fn ->
      if timer == nil do
        log("Starting timer...")
        timer = set_interval(react, 1000, on_tick)
        set_timer.(timer)
      end
    end

    on_stop = fn ->
      if timer != nil do
        log("Stopping timer...")
        clear_interval(timer)
        set_timer.(nil)
      end
    end

    on_reset = fn -> set_count.(0) end

    markup :main, Panel, origin: origin, size: size do
      markup(:label, Label, origin: {0, 0}, size: {12, 1}, text: "#{count}")

      markup(:start, Button,
        origin: {0, 1},
        size: {12, 1},
        text: "Start",
        on_click: on_start
      )

      markup(:stop, Button,
        origin: {0, 2},
        size: {12, 1},
        text: "Stop",
        on_click: on_stop
      )

      markup(:reset, Button,
        origin: {0, 3},
        size: {12, 1},
        text: "Reset",
        on_click: on_reset
      )
    end
  end
end
