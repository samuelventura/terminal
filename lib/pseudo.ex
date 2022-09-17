defmodule Terminal.Pseudo do
  alias Teletype.Pts

  def open(opts \\ []) do
    Pts.open(opts)
  end

  def handle(port, {port, {:data, data}}), do: {port, true, data}
  def handle(port, _), do: {port, false}

  def write!(port, data) do
    Pts.write!(port, data)
    port
  end

  def read!(port) do
    data = Pts.read!(port)
    {port, data}
  end

  def close(port) do
    Pts.close(port)
  end
end
