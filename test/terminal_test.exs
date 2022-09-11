defmodule TerminalTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Canvas

  test "canvas basic check" do
    c1 = Canvas.new(10, 10)
    {w, h} = Canvas.get(c1, :size)
    c2 = Canvas.new(w, h)
    d = Canvas.diff(c1, c2)
    assert d == []
  end
end
