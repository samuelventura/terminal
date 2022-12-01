# elixir exs/main.exs
# exit with ctrl+c

Mix.install([
  {:teletype, git: "https://github.com/samuelventura/teletype"},
  {:terminal, git: "https://github.com/samuelventura/terminal"}
])

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
