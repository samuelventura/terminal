defmodule Terminal.Demo.Modals do
  use Terminal.React

  def modals(react, %{origin: origin, size: size}) do
    {show, set_show} = use_state(react, :show, false)

    on_show = fn -> set_show.(true) end
    on_hide = fn -> set_show.(false) end

    markup :main, Panel, origin: origin, size: size do
      markup(:show, Button,
        origin: {0, 0},
        size: {12, 1},
        text: "Show",
        on_click: on_show
      )

      markup(:hide, Button,
        origin: {0, 1},
        size: {12, 1},
        text: "Hide",
        on_click: on_hide
      )

      markup(:text, Label,
        origin: {0, 6},
        text: "This should get covered by the modal"
      )

      markup :modal, Panel, root: true, visible: show, origin: {15, 4}, size: {30, 6} do
        markup(:frame, Frame,
          origin: {0, 0},
          size: {30, 6},
          text: "Modal"
        )

        markup :main, Panel, origin: {1, 1}, size: {28, 4} do
          markup(21, Label, origin: {0, 0}, text: "Username:")
          markup(22, Label, origin: {0, 1}, text: "Password:")

          markup(23, Input, origin: {10, 0}, size: {12, 1})
          markup(24, Input, origin: {10, 1}, size: {12, 1}, password: true)

          markup(:cancel, Button,
            origin: {8, 3},
            size: {8, 1},
            text: "Cancel",
            on_click: on_hide
          )

          markup(:save, Button,
            origin: {18, 3},
            size: {8, 1},
            text: "Save",
            on_click: on_hide
          )
        end
      end
    end
  end
end
