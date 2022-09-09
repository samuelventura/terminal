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
    {name, set_name} = use_state(react, :name, "Counter")

    on_change = fn index, name ->
      set_index.(index)
      set_name.(name)
    end

    tab_origin = {14, 2}
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
        items: ["Counter", "Login", "Network"]
      )

      markup(:tab_frame, Frame,
        origin: {12, 1},
        size: {42, 8},
        text: name
      )

      markup(:counter, &counter/2, visible: index == 0, origin: tab_origin, size: tab_size)
      markup(:login, &login/2, visible: index == 1, origin: tab_origin, size: tab_size)
      markup(:network, &network/2, visible: index == 2, origin: tab_origin, size: tab_size)
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

  def login(react, %{visible: visible, origin: origin, size: size}) do
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

  def network(react, %{visible: visible, origin: origin, size: {w, _h} = size}) do
    {type, set_type} = use_state(react, :type, "DHCP")
    {address, set_address} = use_state(react, :address, "")
    {netmask, set_netmask} = use_state(react, :netmask, "")

    on_type = fn _index, name -> set_type.(name) end

    on_save = fn ->
      case type do
        "DHCP" -> IO.inspect("Saved: #{type}")
        _ -> IO.inspect("Saved: #{type} ip:#{address} nm:#{netmask}")
      end
    end

    markup :main, Panel, visible: visible, origin: origin, size: size do
      markup(:label, Label, origin: {0, 0}, size: {22, 1}, text: "Interface eth0")

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
          size: {12, 1},
          on_change: set_address
        )

        markup(:netmask, Input,
          origin: {9, 1},
          size: {12, 1},
          on_change: set_netmask
        )
      end

      markup(:save, Button,
        origin: {0, 4},
        size: {12, 1},
        text: "Save",
        on_click: on_save
      )
    end
  end
end
