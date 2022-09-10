defmodule Terminal.Demo do
  use Terminal.App
  alias Terminal.Panel
  alias Terminal.Label
  alias Terminal.Button
  alias Terminal.Input
  alias Terminal.Frame
  alias Terminal.Select
  alias Terminal.Radio

  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    app_init(&main/2, size: size)
  end

  def main(react, %{size: size}) do
    {index, set_index} = use_state(react, :index, 0)
    {name, set_name} = use_state(react, :name, "Timer")

    on_change = fn index, name ->
      set_index.(index)
      set_name.(name)
    end

    tab_origin = {13, 2}
    tab_size = {40, 6}

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
        items: ["Timer", "Counter", "Network", "Password"]
      )

      markup(:tab_frame, Frame,
        origin: {12, 1},
        size: {42, 8},
        text: name
      )

      markup(:timer, &timer/2, visible: index == 0, origin: tab_origin, size: tab_size)
      markup(:counter, &counter/2, visible: index == 1, origin: tab_origin, size: tab_size)
      markup(:network, &network/2, visible: index == 2, origin: tab_origin, size: tab_size)
      markup(:login, &password/2, visible: index == 3, origin: tab_origin, size: tab_size)
    end
  end

  def timer(react, %{visible: visible, origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)
    {timer, set_timer} = use_state(react, :timer, nil)

    callback =
      use_callback(react, :timer, fn ->
        log("Timer #{count}")
        set_count.(count + 1)
      end)

    on_start = fn ->
      if timer == nil do
        log("Starting timer...")
        timer = set_interval(react, 500, callback)
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

    markup :main, Panel, visible: visible, origin: origin, size: size do
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

  def counter(react, %{visible: visible, origin: origin, size: size}) do
    {count, set_count} = use_state(react, :count, 0)

    on_increment = fn -> set_count.(count + 1) end
    on_decrement = fn -> set_count.(count - 1) end

    markup :main, Panel, visible: visible, origin: origin, size: size do
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

  def network(react, %{visible: visible, origin: origin, size: {w, _h} = size}) do
    {busy, set_busy} = use_state(react, :busy, false)
    {type, set_type} = use_state(react, :type, "DHCP")
    {address, set_address} = use_state(react, :address, "10.77.0.10")
    {netmask, set_netmask} = use_state(react, :netmask, "255.0.0.0")
    {{fgc, bgc, msg}, set_result} = use_state(react, :result, {:black, :black, ""})

    on_type = fn _index, name -> set_type.(name) end

    on_save = fn ->
      log("On save: #{type} ip:#{address} nm:#{netmask}")
      set_result.({:white, :black, "Saving..."})
      set_busy.(true)

      Task.start(fn ->
        log("Save task: #{type} ip:#{address} nm:#{netmask}")
        :timer.sleep(1000)

        case type do
          "Manual" ->
            case {valid_ip?(address), valid_ip?(netmask)} do
              {false, _} -> set_result.({:red, :black, "Invalid address: #{address}"})
              {_, false} -> set_result.({:red, :black, "Invalid netmask: #{netmask}"})
              _ -> set_result.({:blue, :black, "Save OK"})
            end

          "DHCP" ->
            set_result.({:blue, :black, "Save OK"})
        end

        set_busy.(false)
      end)
    end

    markup :main, Panel, visible: visible, origin: origin, size: size do
      markup(:title, Label, origin: {0, 0}, size: {w, 1}, text: "Interface eth0")
      markup(:result, Label, origin: {0, 5}, size: {w, 1}, text: msg, bgcolor: bgc, fgcolor: fgc)

      markup(:type, Radio,
        origin: {0, 1},
        size: {w, 1},
        items: ["DHCP", "Manual"],
        on_change: on_type
      )

      markup :main, Panel, visible: type == "Manual", origin: {0, 2}, size: {w, 2} do
        markup(:address_label, Label, origin: {0, 0}, text: "Address:")
        markup(:netmask_label, Label, origin: {0, 1}, text: "Netmask:")

        markup(:address, Input,
          origin: {9, 0},
          size: {15, 1},
          text: address,
          on_change: set_address
        )

        markup(:netmask, Input,
          origin: {9, 1},
          size: {15, 1},
          text: netmask,
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

  def password(react, %{visible: visible, origin: origin, size: size}) do
    {user, set_user} = use_state(react, :user, "")

    on_change = fn text -> set_user.(text) end

    markup :main, Panel, visible: visible, origin: origin, size: size do
      markup(:label, Label, origin: {0, 0}, size: {22, 1}, text: "Welcome #{user}!")

      markup(:input_label, Label, origin: {0, 1}, text: "Username:")
      markup(:password_label, Label, origin: {0, 2}, text: "Password:")

      markup(:input, Input,
        origin: {10, 1},
        size: {12, 1},
        on_change: on_change
      )

      markup(:password, Input,
        origin: {10, 2},
        size: {12, 1},
        password: true
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
