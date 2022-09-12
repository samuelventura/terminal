defmodule Terminal.Demo do
  use Terminal.App
  use Terminal.Const

  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    app_init(&main/2, size: size, on_event: fn e -> log("Event #{inspect(e)}") end)
  end

  def main(react, %{size: size}) do
    {index, set_index} = use_state(react, :index, 0)
    {name, set_name} = use_state(react, :name, "Color")

    on_change = fn index, name ->
      log("Demo #{index} #{name}")
      set_index.(index)
      # nil on alt+enter for invalid
      set_name.("#{name}")
      # trigger an invalid index
      if name == "Invalid", do: set_index.(-1)
    end

    tab_origin = {13, 2}
    tab_size = {40, 8}

    markup :main, Panel, size: size do
      markup(:label, Label, text: "Terminal UIs with Reactish API - Demo")

      markup(:list_frame, Frame,
        origin: {0, 1},
        size: {12, 6},
        text: "Demos"
      )

      markup(:select, Select,
        origin: {1, 2},
        size: {10, 4},
        selected: index,
        on_change: on_change,
        items: ["Color", "Timer", "Effects", "Counter", "Network", "Password", "Invalid"]
      )

      markup(:tab_frame, Frame,
        origin: {12, 1},
        size: {42, 10},
        text: name
      )

      markup(index, &tabs/2, tab: index, origin: tab_origin, size: tab_size)
    end
  end

  def tabs(_react, %{tab: tab, origin: origin, size: size}) do
    case tab do
      -1 -> markup(:invalid, Panel, [])
      0 -> markup(:color, &color/2, origin: origin, size: size)
      1 -> markup(:timer, &timer/2, origin: origin, size: size)
      2 -> markup(:effects, &effects/2, origin: origin, size: size)
      3 -> markup(:counter, &counter/2, origin: origin, size: size)
      4 -> markup(:network, &network/2, origin: origin, size: size)
      5 -> markup(:password, &password/2, origin: origin, size: size)
    end
  end

  def color(_react, %{origin: origin, size: size}) do
    markup :main, Panel, origin: origin, size: size do
      for b <- 0..7 do
        for f <- 0..15 do
          markup(16 * b + f, Label,
            origin: {2 * f, b},
            text: "H ",
            back: b,
            fore: f
          )
        end
      end
    end
  end

  def timer(react, %{origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)
    {timer, set_timer} = use_state(react, :timer, nil)

    callback =
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
        timer = set_interval(react, 1000, callback)
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

  def effects(react, %{origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)

    on_increment = fn -> set_count.(count + 1) end
    on_decrement = fn -> set_count.(count - 1) end

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

  def counter(react, %{origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)

    on_increment = fn -> set_count.(count + 1) end
    on_decrement = fn -> set_count.(count - 1) end

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

  def network(react, %{origin: origin, size: {w, _h} = size}) do
    {busy, set_busy} = use_state(react, :busy, false)
    {type, set_type} = use_state(react, :type, "DHCP")
    {address, set_address} = use_state(react, :address, "10.77.0.10")
    {netmask, set_netmask} = use_state(react, :netmask, "255.0.0.0")
    {{fgc, bgc, msg}, set_result} = use_state(react, :result, {@black, @black, ""})

    on_type = fn index, name ->
      log("Type #{index} #{name}")
      set_type.(name)
    end

    on_save = fn ->
      log("On save: #{type} ip:#{address} nm:#{netmask}")
      set_result.({@white, @black, "Saving..."})
      set_busy.(true)

      Task.start(fn ->
        log("Save task: #{type} ip:#{address} nm:#{netmask}")
        :timer.sleep(1000)

        case type do
          "Static" ->
            case {valid_ip?(address), valid_ip?(netmask)} do
              {false, _} -> set_result.({@red, @black, "Invalid address: #{address}"})
              {_, false} -> set_result.({@red, @black, "Invalid netmask: #{netmask}"})
              _ -> set_result.({@blue, @black, "Save OK"})
            end

          "DHCP" ->
            set_result.({@blue, @black, "Save OK"})
        end

        set_busy.(false)
      end)
    end

    markup :main, Panel, origin: origin, size: size do
      markup(:title, Label, origin: {0, 0}, size: {w, 1}, text: "Interface eth0")
      markup(:result, Label, origin: {0, 5}, size: {w, 1}, text: msg, back: bgc, fore: fgc)

      markup(:type, Radio,
        origin: {0, 1},
        size: {w, 1},
        items: ["DHCP", "Static"],
        on_change: on_type
      )

      markup :manual, Panel, origin: {0, 2}, size: {w, 2} do
        markup(:address_label, Label, origin: {0, 0}, text: "Address:")
        markup(:netmask_label, Label, origin: {0, 1}, text: "Netmask:")

        markup(:address, Input,
          origin: {9, 0},
          size: {15, 1},
          text: address,
          enabled: type == "Static",
          on_change: set_address
        )

        markup(:netmask, Input,
          origin: {9, 1},
          size: {15, 1},
          text: netmask,
          enabled: type == "Static",
          on_change: set_netmask
        )
      end

      markup(:save, Button,
        origin: {0, 4},
        size: {12, 1},
        text: "Save",
        enabled: !busy,
        on_click: on_save
      )
    end
  end

  def password(react, %{origin: origin, size: size}) do
    {user, set_user} = use_state(react, :user, "samuel")
    {password, set_password} = use_state(react, :password, "abc123")

    on_user = fn text -> set_user.(text) end
    on_password = fn text -> set_password.(text) end

    markup :main, Panel, origin: origin, size: size do
      markup(:label, Label, origin: {0, 0}, size: {22, 1}, text: "Welcome #{user}!")

      markup(:input_label, Label, origin: {0, 1}, text: "Username:")
      markup(:password_label, Label, origin: {0, 2}, text: "Password:")

      markup(:input, Input,
        origin: {10, 1},
        size: {12, 1},
        text: user,
        on_change: on_user
      )

      markup(:password, Input,
        origin: {10, 2},
        size: {12, 1},
        text: password,
        password: true,
        on_change: on_password
      )
    end
  end

  defp valid_ip?(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp log(msg) do
    # 2022-09-10 20:02:49.684244Z
    now = DateTime.utc_now()
    now = String.slice("#{now}", 11..22)
    IO.puts("#{now} #{inspect(self())} #{msg}")
  end
end
