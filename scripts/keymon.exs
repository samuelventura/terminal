#mix run scripts/keymon.exs
#exit with Ctrl+c

alias Terminal.Tty

term = Terminal.Xterm
tty = Terminal.Pseudo
tty = {tty, []}
tty = Tty.open(tty)
tty = Tty.write!(tty, term.init())
:timer.sleep(1000)
query = term.query(:size)
tty = Tty.write!(tty, query)
IO.puts "Key monitor\r"
IO.puts "#{inspect(query)}\r"
IO.puts "#{inspect(term.init())}\r"

Enum.reduce_while(Stream.cycle(0..1), {tty, ""}, fn _, {tty, buffer} ->
  {tty, data} = Tty.read!(tty)
  IO.puts "#{inspect(data)}\r"
  {buffer, events} = term.append(buffer, data)
  IO.puts "#{inspect(events)}\r"
  case events do
    [{:key, 1, "c"}] -> {:halt, nil}
    _ -> {:cont, {tty, buffer}}
  end
end)

Teletype.reset()
