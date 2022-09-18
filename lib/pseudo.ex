defmodule Terminal.Pseudo do
  alias Teletype.Pts

  def open(opts \\ []) do
    Pts.open(opts)
  end

  def handle({port, _} = pts, {port, {:data, data}}), do: {pts, true, data}
  def handle(pts, _), do: {pts, false}

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
