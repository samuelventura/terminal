defmodule Terminal.Socket do
  # socat file:/dev/tty,raw,icanon=0,echo=0,min=0,escape=0x03 tcp-l:8880,reuseaddr
  # socat STDIO fails with: Inappropriate ioctl for device
  # no resize event is received with this method
  # raw required to avoid translating \r to \n
  # min=0 required to answer size query immediatelly
  # fork useless because term won't answer size query on reconnection
  # escape=0x03 required to honor escape sequences (ctrl-c)
  # while true; do socat file:/dev/tty,raw,icanon=0,echo=0,min=0 tcp-l:8880,reuseaddr; done
  # while true; do socat file:/dev/tty,raw,icanon=0,echo=0,min=0,escape=0x03 tcp-l:8880,reuseaddr; done
  # to exit: ctrl-z, then jobs, then kill %1
  #
  # socat file:/dev/tty,nonblock,raw,icanon=0,echo=0,min=0,escape=0x03 tcp:127.0.0.1:8880
  # client socat to test immediate transmission of typed keys on both ends
  # escape=0x03 reqired to honor ctrl-c
  #
  # echo -en "\033[1mThis is bold text.\033[0m" | nc 127.0.0.1 8880
  # to test server end honors escapes
  def open(host: host, port: port) do
    opts = [
      :binary,
      packet: :raw,
      active: true
    ]

    host = String.to_charlist(host)
    {:ok, socket} = :gen_tcp.connect(host, port, opts)
    socket
  end

  def close(socket) do
    :gen_tcp.close(socket)
  end

  def handle(socket, {:tcp, socket, data}), do: {socket, :data, data}
  def handle(socket, {:tcp_closed, socket}), do: {socket, :exit}
  def handle(socket, _), do: {socket, false}

  def read!(socket) do
    receive do
      {:tcp, ^socket, data} ->
        {socket, data}

      any ->
        raise "#{inspect(any)}"
    end
  end

  def write!(socket, data) do
    :ok = :gen_tcp.send(socket, data)
    socket
  end
end
