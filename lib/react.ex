defmodule Terminal.React do
  alias Terminal.State
  alias Terminal.Parser

  defmacro __using__(_opts) do
    quote do
      use Terminal.Const
      import Terminal.React
      alias Terminal.Panel
      alias Terminal.Label
      alias Terminal.Button
      alias Terminal.Input
      alias Terminal.Frame
      alias Terminal.Select
      alias Terminal.Radio
    end
  end

  defmacro markup(key, modfun, props) do
    quote do
      {unquote(key), unquote(modfun), unquote(props), []}
    end
  end

  defmacro markup(key, module, props, do: inner) do
    # standard unquoting of a block returns last value
    # parse to capture each markup instance
    inner = Parser.parse(inner)

    # flatten allows for nested children generators
    quote do
      children = unquote(inner) |> List.flatten()
      {unquote(key), unquote(module), unquote(props), children}
    end
  end

  def use_state(react, key, initial) do
    keys = State.key(react, key)
    current = State.use_state(react, keys, initial)

    {current,
     fn value ->
       pid = State.pid(react)

       case self() == pid do
         true ->
           State.set_state(react, keys, value)

         false ->
           callback = fn -> State.set_state(react, keys, value) end
           send(pid, {:cmd, :callback, callback})
       end
     end}
  end

  def use_callback(react, key, function) do
    keys = State.key(react, key)
    State.use_callback(react, keys, function)
    fn -> State.get_callback(react, keys).() end
  end

  def use_effect(react, key, function) do
    use_effect(react, key, nil, function)
  end

  def use_effect(react, key, deps, callback) do
    keys = State.key(react, key)

    function = fn ->
      cleanup = callback.()

      if is_function(cleanup) do
        State.set_cleanup(react, keys, cleanup)
      end
    end

    State.use_effect(react, keys, function, deps)
  end

  def set_interval(react, millis, callback) do
    id = State.new_timer(react)
    stream = Stream.interval(millis)

    handler = fn _ ->
      case State.get_timer(react, id) do
        nil ->
          true

        _ ->
          callback.()
          false
      end
    end

    task = Task.async(fn -> Enum.any?(stream, handler) end)
    State.set_timer(react, id, task)

    fn ->
      task = State.get_timer(react, id)
      Task.shutdown(task)
      State.remove_timer(react, id)
    end
  end

  def clear_interval(timer) do
    timer.()
  end

  def log(msg) do
    # 2022-09-10 20:02:49.684244Z
    now = DateTime.utc_now()
    now = String.slice("#{now}", 11..22)
    IO.puts("#{now} #{inspect(self())} #{msg}")
  end
end
