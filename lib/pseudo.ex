defmodule Terminal.Pseudo do
  alias Teletype.Pts

  def open(opts \\ []) do
    Pts.open(opts)
  end

  def handle(pts, msg) do
    Pts.handle(pts, msg)
  end

  def write!(pts, data) do
    Pts.write!(pts, data)
    pts
  end

  def read!(pts) do
    data = Pts.read!(pts)
    {pts, data}
  end

  def close(pts) do
    Pts.close(pts)
  end
end
