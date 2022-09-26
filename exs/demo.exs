# mix run exs/demo.exs --ptm|--socat
# --ptm : ../teletype/priv/ptm
# --socat : socat file:/dev/tty,raw,icanon=0,echo=0,min=0,escape=0x03 tcp-l:8880,reuseaddr

alias Terminal.Demo

folder = Path.dirname(__ENV__.file)
relative_to = Path.join(folder, "demo")
Code.require_file("colors.exs", relative_to)
Code.require_file("controls.exs", relative_to)
Code.require_file("counter.exs", relative_to)
Code.require_file("effects.exs", relative_to)
Code.require_file("modals.exs", relative_to)
Code.require_file("timers.exs", relative_to)
Code.require_file("unsafe.exs", relative_to)
Code.require_file("main.exs", relative_to)

Process.flag(:trap_exit, true)

{:ok, pid} =
  case System.argv() do
    [] ->
      tty = {Teletype.Tty, []}
      Demo.start_link(tty: tty)

    ["--ptm"] ->
      System.put_env("ReactLogs", "true")
      tty = "/tmp/teletype.pts"
      tty = {Teletype.Tty, tty: tty}
      Demo.start_link(tty: tty)

    ["--socat"] ->
      System.put_env("ReactLogs", "true")
      tty = {Terminal.Socket, host: "127.0.0.1", port: 8880}
      Demo.start_link(tty: tty)

    ["--rpi4"] ->
      System.put_env("ReactLogs", "true")
      tty = {Terminal.Socket, host: "athasha-4ad8", port: 8012}
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
