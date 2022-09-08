defmodule Terminal.Const do
  defmacro __using__(_) do
    quote do
      @ctl 1
      @alt 2
      @fun 4

      @bold 1
      @dimmed 2
      @inverse 4

      @black 0
      @red 1
      @green 2
      @yellow 3
      @blue 4
      @magenta 5
      @cyan 6
      @white 7
      @bblack 8
      @bred 9
      @bgreen 10
      @byellow 11
      @bblue 12
      @bmagenta 13
      @bcyan 14
      @bwhite 15

      defp color_id(color) do
        case color do
          :black -> @black
          :red -> @red
          :green -> @green
          :yellow -> @yellow
          :blue -> @blue
          :magenta -> @magenta
          :cyan -> @cyan
          :white -> @white
          :bblack -> @bblack
          :bred -> @bred
          :bgreen -> @bgreen
          :byellow -> @byellow
          :bblue -> @bblue
          :bmagenta -> @bmagenta
          :bcyan -> @bcyan
          :bwhite -> @bwhite
          _ -> color
        end
      end
    end
  end
end
