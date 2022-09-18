#mix run scripts/demo.exs
#_build/dev/lib/teletype/priv/ptm

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

{:ok, pid} = case System.argv() do
  [] -> Demo.start_link()
  ["--ptm"] ->
    System.put_env("ReactLogs", "true")
    tty = "/tmp/teletype.pts"
    tty = {Terminal.Pseudo, tty: tty}
    Demo.start_link(tty: tty)
  ["--socat"] ->
    System.put_env("ReactLogs", "true")
    tty = {Terminal.Socket, ip: "127.0.0.1", port: 8880}
    Demo.start_link(tty: tty)
end

receive do
  # ctrl+c
  {:EXIT, ^pid, :normal} ->
    :ok

  # killall pts
  {:EXIT, ^pid, reason} ->
    IO.inspect({:EXIT, pid, reason})
end
