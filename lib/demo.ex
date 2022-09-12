defmodule Terminal.Demo do
  use Terminal.App
  use Terminal.Const

  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    app_init(&main/2, size: size, on_event: fn e -> log("Event #{inspect(e)}") end)
  end

  def main(react, %{size: size}) do
    {index, set_index} = use_state(react, :index, 0)
    {name, set_name} = use_state(react, :name, "Colors")

    on_change = fn index, name ->
      log("Demo #{index} #{name}")
      set_index.(index)
      # nil on alt+enter for invalid
      set_name.("#{name}")
      # trigger an invalid index
      if name == "Invalid", do: set_index.(-1)
    end

    markup :main, Panel, size: size do
      markup(:label, Label, text: "Terminal UIs with Reactish API - Demo")

      # both in same panel to gain focus on border click
      markup :select, Panel, origin: {0, 1}, size: {12, 10} do
        markup(:frame, Frame,
          size: {12, 10},
          text: "Demos"
        )

        markup(:select, Select,
          origin: {1, 1},
          size: {10, 8},
          selected: index,
          on_change: on_change,
          items: [
            "Colors",
            "Controls",
            "Timer",
            "Effects",
            "Counter",
            "Network",
            "Password",
            "Invalid"
          ]
        )
      end

      # both in same panel to gain focus on border click
      markup :tab, Panel, origin: {12, 1}, size: {42, 10} do
        markup(:frame, Frame,
          origin: {0, 0},
          size: {42, 10},
          text: name
        )

        markup(index, &tabs/2, tab: index, origin: {1, 1}, size: {40, 8})
      end
    end
  end

  def tabs(_react, %{tab: tab, origin: origin, size: size}) do
    case tab do
      -1 -> markup(:invalid, Panel, [])
      0 -> markup(:colors, &colors/2, origin: origin, size: size)
      1 -> markup(:controls, &controls/2, origin: origin, size: size)
      2 -> markup(:timer, &timer/2, origin: origin, size: size)
      3 -> markup(:effects, &effects/2, origin: origin, size: size)
      4 -> markup(:counter, &counter/2, origin: origin, size: size)
      5 -> markup(:network, &network/2, origin: origin, size: size)
      6 -> markup(:password, &password/2, origin: origin, size: size)
    end
  end

  def colors(_react, %{origin: origin, size: size}) do
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

  def controls(react, %{origin: origin, size: {w, _} = size}) do
    {user, set_user} = use_state(react, :user, "user")
    {password, set_password} = use_state(react, :password, "abc123")
    {radio, set_radio} = use_state(react, :radio, 1)
    {select, set_select} = use_state(react, :select, 2)

    on_user = fn value ->
      log("User #{value}")
      set_user.(value)
    end

    on_password = fn value ->
      log("Password #{value}")
      set_password.(value)
    end

    on_radio = fn index, name ->
      log("Radio #{index} #{name}")
      set_radio.(index)
    end

    on_b1 = fn ->
      log("Button1")
      set_radio.(-1)
    end

    on_b2 = fn ->
      log("Button2")
      set_select.(-1)
    end

    on_b3 = fn ->
      log("Button3")
      set_radio.(10)
    end

    on_b4 = fn ->
      log("Button4")
      set_select.(10)
    end

    on_b5 = fn ->
      log("Button5")
      set_select.(2)
    end

    on_select = fn index, name ->
      log("Select #{index} #{name}")
      set_select.(index)
    end

    markup :main, Panel, origin: origin, size: size do
      markup(11, Radio,
        origin: {0, 0},
        size: {div(w, 2), 1},
        items: [1, 2, 3, 4, 5],
        selected: radio,
        on_change: on_radio
      )

      markup(:label, Label, origin: {0, 1}, size: {div(w, 2), 1}, text: "Welcome #{user}!")

      markup(21, Input, origin: {0, 2}, size: {div(w, 2), 2}, text: user, on_change: on_user)

      markup(22, Input,
        password: true,
        on_change: on_password,
        origin: {0, 3},
        size: {div(w, 2), 1},
        text: password
      )

      # buttons with unordered findex to test navigation
      markup(31, Button, origin: {0, 4}, text: "B1", findex: 1, on_click: on_b1)
      markup(34, Button, origin: {5, 4}, text: "B4", findex: 4, on_click: on_b4)
      markup(32, Button, origin: {10, 4}, text: "B2", findex: 2, on_click: on_b2)
      markup(33, Button, origin: {15, 4}, text: "B3", findex: 3, on_click: on_b3)
      markup(35, Button, origin: {20, 4}, text: "B5", findex: 5, on_click: on_b5)
      # selects with height mismatching data to test scrolling
      markup(41, Select,
        origin: {div(w, 2) + 1, 0},
        size: {1, 2},
        items: [1, 2, 3, 4],
        selected: select,
        on_change: on_select
      )

      markup(42, Select,
        origin: {div(w, 2) + 4, 0},
        size: {1, 6},
        items: [1, 2, 3, 4]
      )
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
