defmodule Terminal.Demo.Controls do
  use Terminal.React

  def controls(react, %{origin: origin, size: {w, _} = size}) do
    {user, set_user} = use_state(react, :user, "user")
    {password, set_password} = use_state(react, :password, "abc123")
    {radio, set_radio} = use_state(react, :radio, 1)
    {select, set_select} = use_state(react, :select, 2)
    {checked, set_checked} = use_state(react, :checked, true)

    on_user = fn value ->
      log("User #{value}")
      set_user.(value)
    end

    on_password = fn value ->
      log("Password #{value}")
      set_password.(value)
    end

    on_radio = fn index, item ->
      log("Radio #{index} #{item}")
      set_radio.(index)
    end

    on_b1 = fn ->
      log("Button1")
      set_radio.(-1)
    end

    on_b2 = fn ->
      log("Button2")
      set_radio.(5)
    end

    on_b3 = fn ->
      log("Button3")
      set_radio.(3)
    end

    on_b4 = fn ->
      log("Button4")
      set_select.(-1)
    end

    on_b5 = fn ->
      log("Button5")
      set_select.(4)
    end

    on_b6 = fn ->
      log("Button6")
      set_select.(2)
    end

    on_select = fn index, item ->
      log("Select #{index} #{item}")
      set_select.(item)
    end

    on_checked = fn checked ->
      log("Checked #{checked}")
      set_checked.(checked)
    end

    markup :main, Panel, origin: origin, size: size do
      # selected index is zero based
      # items can be any datatype implementing String.Chars
      markup(11, Radio,
        origin: {0, 0},
        size: {div(w, 2), 1},
        items: [0, 1, 2, 3, 4],
        selected: radio,
        on_change: on_radio
      )

      markup(12, Checkbox,
        origin: {div(w, 2), 0},
        checked: checked,
        on_change: on_checked,
        text: "Toggle"
      )

      markup(:title, Label, origin: {0, 1}, size: {div(w, 2), 1}, text: "Welcome #{user}!")

      markup(21, Label, origin: {0, 2}, text: "Username:")
      markup(22, Label, origin: {0, 3}, text: "Password:")

      markup(23, Input, origin: {10, 2}, size: {div(w, 2), 2}, text: user, on_change: on_user)

      markup(24, Input,
        password: true,
        on_change: on_password,
        origin: {10, 3},
        size: {div(w, 2), 1},
        text: password
      )

      # selected index is zero based
      # selects with height mismatching data to test scrolling
      # items can be any datatype implementing String.Chars
      markup(31, Select,
        origin: {w - 5, 0},
        size: {1, 2},
        items: [0, 1, 2, 3],
        selected: select,
        on_change: on_select
      )

      markup(32, Select,
        origin: {w - 3, 0},
        size: {1, 6},
        items: [0, 1, 2, 3],
        selected: select,
        on_change: on_select
      )

      # buttons with unordered findex to test navigation
      markup(41, Button,
        origin: {0, 4},
        findex: 1,
        on_click: on_b1,
        text: "B1 set radio to index -1"
      )

      markup(42, Button,
        origin: {0, 5},
        findex: 3,
        on_click: on_b2,
        text: "B2 set radio to index 5"
      )

      markup(43, Button,
        origin: {0, 6},
        findex: 5,
        on_click: on_b3,
        text: "B3 set radio to index 3"
      )

      markup(44, Button,
        origin: {0, 7},
        findex: 2,
        on_click: on_b4,
        text: "B4 set select to index -1"
      )

      markup(45, Button,
        origin: {0, 8},
        findex: 4,
        on_click: on_b5,
        text: "B5 set select to index 4"
      )

      markup(46, Button,
        origin: {0, 9},
        findex: 6,
        on_click: on_b6,
        text: "B6 set select to index 2"
      )
    end
  end
end
