defmodule Terminal.Demo.Timers do
  use Terminal.React

  def timers(react, %{origin: origin, size: {w, h} = size}) do
    {count, set_count} = use_state(react, :count, 0)
    {flag, set_flag} = use_state(react, :flag, "Off")
    {interval, set_interval} = use_state(react, :interval, nil)
    {timeout, set_timeout} = use_state(react, :timeout, nil)

    # callback required as interval handler
    # to access latest count value otherwise
    # its value at set time will be captured
    on_tick =
      use_callback(react, :interval, fn ->
        log("Timer #{count}")
        set_count.(count + 1)
      end)

    cleanup =
      use_callback(react, :cleanup, fn ->
        if interval != nil do
          log("Cleanup interval...")
          clear_timer(interval)
          # as expected this excepts when called from a cleanup
          # because the interval state key is gone at that point
          # set_interval.(nil)
        end

        if timeout != nil do
          log("Cleanup timeout...")
          clear_timer(timeout)
        end
      end)

    # install cleanup to ensure interval is
    # stopped when this tab is unmounted
    use_effect(react, :once, [], fn ->
      log("Timer effect")

      # callback required as cleanup
      # to access latest interval value
      # otherwise nil will be captured
      fn ->
        log("Timer cleanup")
        cleanup.()
      end
    end)

    on_start = fn ->
      log("Starting interval...")
      interval = set_interval(react, 1000, on_tick)
      set_interval.(interval)
    end

    on_stop = fn ->
      log("Stopping interval...")
      clear_timer(interval)
      set_interval.(nil)
    end

    on_single = fn ->
      log("Starting timeout...")
      set_flag.("Running")

      timeout =
        set_timeout(react, 2000, fn ->
          set_timeout.(nil)
          set_flag.("Done")
        end)

      set_timeout.(timeout)
    end

    on_cancel = fn ->
      log("Canceling timeout...")
      clear_timer(timeout)
      set_timeout.(nil)
      set_flag.("Canceled")
    end

    on_reset = fn ->
      set_count.(0)
      set_flag.("Off")
    end

    markup :main, Panel, origin: origin, size: size do
      markup :interval, Panel, size: {div(w, 2), h} do
        markup(:label, Label, size: {12, 1}, text: "#{count}")

        markup(:start, Button,
          origin: {0, 1},
          size: {12, 1},
          text: "Start",
          enabled: interval == nil,
          on_click: on_start
        )

        markup(:stop, Button,
          origin: {0, 2},
          size: {12, 1},
          text: "Stop",
          enabled: interval != nil,
          on_click: on_stop
        )
      end

      markup :timeout, Panel, origin: {div(w, 2), 0}, size: {div(w, 2), h} do
        markup(:label, Label, size: {12, 1}, text: flag)

        markup(:single, Button,
          origin: {0, 1},
          size: {12, 1},
          text: "Single",
          enabled: timeout == nil,
          on_click: on_single
        )

        markup(:cancel, Button,
          origin: {0, 2},
          size: {12, 1},
          text: "Cancel",
          enabled: timeout != nil,
          on_click: on_cancel
        )
      end

      markup(:reset, Button,
        origin: {0, 3},
        size: {w, 1},
        text: "Reset",
        on_click: on_reset
      )
    end
  end
end
