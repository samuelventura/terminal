defmodule Terminal.Nil do
  @behaviour Terminal.Control

  def init(_), do: nil
  def bounds(_), do: {0, 0, 0, 0}
  def visible(_), do: false
  def focusable(_), do: false
  def focused(_, _), do: nil
  def focused(_), do: false
  def refocus(_, _), do: nil
  def findex(_), do: -1
  def shortcut(_), do: nil
  def children(_), do: []
  def children(_, _), do: nil
  def modal(_), do: false
  def update(_, _), do: nil
  def handle(_, _), do: {nil, nil}
  def render(_, canvas), do: canvas
end
