#mix run scripts/demo.exs

alias Terminal.Demo

folder = Path.dirname(__ENV__.file)
relative_to = Path.join(folder, "demo")
Code.require_file "colors.exs", relative_to
Code.require_file "controls.exs", relative_to
Code.require_file "counter.exs", relative_to
Code.require_file "effects.exs", relative_to
Code.require_file "modals.exs", relative_to
Code.require_file "timers.exs", relative_to
Code.require_file "unsafe.exs", relative_to
Code.require_file "main.exs", relative_to

Process.flag(:trap_exit, true)
{:ok, pid} = Demo.start_link()

receive do
  # ctrl+c
  {:EXIT, ^pid, :normal} ->
    :ok

  # killall pts
  {:EXIT, ^pid, reason} ->
    Teletype.reset()
    IO.inspect(reason)
end
