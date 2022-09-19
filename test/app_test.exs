defmodule AppTest do
  use ExUnit.Case
  alias Terminal.App
  alias Terminal.Panel
  import Terminal.React, only: [markup: 3, markup: 4]

  defp even(_react, %{i: 0}), do: markup(:root, Panel, [])
  defp even(_react, %{i: 1}), do: nil

  defp even(_react, %{i: i}) do
    case rem(i, 2) do
      0 -> markup(:root, Panel, [])
      1 -> nil
    end
  end

  test "conditional markup realize check" do
    # do not use this technique for long lists of children
    # nils get currently replaced by a {Nil, nil} mote
    # use a generator with explicit filter instead
    app = fn _react, _ ->
      markup :root, Panel, [] do
        markup(0, &even/2, i: 0)
        markup(1, &even/2, i: 1)
        markup(2, &even/2, i: 2)
        markup(3, &even/2, i: 3)
      end
    end

    {state, nil} = App.app_init(app, [])
    App.handle(state, :event)
  end

  defmodule TestApp do
    use Terminal.App

    def init(opts) do
      size = Keyword.fetch!(opts, :size)
      pid = Keyword.fetch!(opts, :pid)
      send(pid, {:app, :init, size})
      app_init(&main/2, size: size)
    end

    def main(_react, %{size: size}) do
      markup :main, Panel, size: size do
      end
    end
  end

  test "start, init, and stop check" do
    self_pid = self()

    {:ok, _listen} =
      spawn_link(fn _ ->
        tcp_opts = [
          :binary,
          ip: {0, 0, 0, 0},
          packet: :raw,
          active: true,
          reuseaddr: true
        ]

        {:ok, listener} = :gen_tcp.listen(0, tcp_opts)
        {:ok, {_ip, port}} = :inet.sockname(listener)
        send(self_pid, {:port, port})
        {:ok, socket} = :gen_tcp.accept(listener)
        {:ok, _res} = :gen_tcp.recv(socket, 0)
        :gen_tcp.send(socket, "\e\[0;0R")
      end)

    port =
      receive do
        {:port, port} -> port
      end

    tty = {Terminal.Socket, ip: "127.0.0.1", port: port}
    {:ok, pid} = TestApp.start_link(tty: tty, pid: self_pid)
    assert_receive {:app, :init, {0, 0}}
    assert :stop == TestApp.stop(pid)
  end
end
