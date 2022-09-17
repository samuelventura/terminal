defmodule Terminal.Pseudo do
  alias Teletype.Nif
  alias Teletype.Pts

  # this module is only usable on beam VMs
  # running a single app on the controlling tty
  # do not use for ptm/pts relays

  def open(opts \\ []) do
    Nif.ttysignal()
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
    Nif.ttyreset()
  end
end
