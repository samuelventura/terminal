defmodule Terminal.Theme do
  def get(:default) do
    %{
      back_readonly: :black,
      fore_readonly: :bblack,
      back_editable: :black,
      fore_editable: :white,
      back_disabled: :black,
      fore_disabled: :bblack,
      back_selected: :white,
      fore_selected: :black,
      back_focused: :blue,
      fore_focused: :white,
      back_notice: :blue,
      fore_notice: :white,
      back_error: :red,
      fore_error: :white
    }
  end

  def get(module), do: module.theme()
end
