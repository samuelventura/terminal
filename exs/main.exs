# mix run exs/main.exs

defmodule Terminal.Demo do
  use Terminal.App

  def init(opts) do
    size = Keyword.fetch!(opts, :size)
    on_event = fn e -> log("Event #{inspect(e)}") end
    app_init(&main/2, size: size, on_event: on_event)
  end

  def main(_react, %{size: size}) do
    markup :main, Panel, size: size do
      markup(:label, Label, text: "Minimal Main")
    end
  end
end

Process.flag(:trap_exit, true)

tty = {Teletype.Tty, []}
{:ok, pid} = Terminal.Demo.start_link(tty: tty)

receive do
  {:EXIT, ^pid, :normal} -> :ok
  other -> IO.inspect(other)
end
