defmodule Terminal.Demo.Unsafe do
  use Terminal.React

  def unsafe(react, %{origin: origin, size: {w, _h} = size}) do
    {busy, set_busy} = use_state(react, :busy, false)
    {type, set_type} = use_state(react, :type, "DHCP")
    {address, set_address} = use_state(react, :address, "192.168.0.1")
    {netmask, set_netmask} = use_state(react, :netmask, "255.255.255.X")
    {{fgc, bgc, msg}, set_alert} = use_state(react, :alert, {@black, @black, ""})

    on_type = fn index, item ->
      log("Type #{index} #{item}")
      set_type.(item)
    end

    on_save = fn ->
      log("On save: #{type} ip:#{address} nm:#{netmask}")
      set_alert.({@white, @black, "Saving..."})
      set_busy.(true)

      # quick unsafe remote/async/long call
      # side effects that require ensured cleanup
      # should go within use_effect callback
      # see the timer tab for an example
      Task.start(fn ->
        log("Save task: #{type} ip:#{address} nm:#{netmask}")
        :timer.sleep(1000)

        case type do
          "Static" ->
            case {valid_ip?(address), valid_ip?(netmask)} do
              {false, _} -> set_alert.({@red, @black, "Invalid address: #{address}"})
              {_, false} -> set_alert.({@red, @black, "Invalid netmask: #{netmask}"})
              _ -> set_alert.({@blue, @black, "Save OK"})
            end

          "DHCP" ->
            set_alert.({@blue, @black, "Save OK"})
        end

        set_busy.(false)
      end)
    end

    markup :main, Panel, origin: origin, size: size do
      markup(:title, Label, origin: {0, 0}, size: {w, 1}, text: "Interface eth0")
      markup(:alert, Label, origin: {0, 5}, size: {w, 1}, text: msg, back: bgc, fore: fgc)
      markup(:notice1, Label, origin: {0, 6}, text: "Spawns task from event handler")
      markup(:notice2, Label, origin: {0, 7}, text: "DHCP save should work")
      markup(:notice3, Label, origin: {0, 8}, text: "Static save should fail")
      markup(:notice4, Label, origin: {0, 9}, text: "Crash if demo changed while saving")

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

  defp valid_ip?(ip) do
    ip = String.to_charlist(ip)

    case :inet.parse_address(ip) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end
