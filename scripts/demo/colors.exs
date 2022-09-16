defmodule Terminal.Demo.Colors do
  use Terminal.React

  def colors(_react, %{origin: origin, size: size}) do
    markup :main, Panel, origin: origin, size: size do
      # collections of children can be easily generated
      # nested lists of markups are automatically flatten
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
end
