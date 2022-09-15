defmodule Terminal.React do
  alias Terminal.State
  alias Terminal.Parser

  defmacro __using__(_opts) do
    quote do
      use Terminal.Const
      import Terminal.React
      alias Terminal.Panel
      alias Terminal.Label
      alias Terminal.Input
      alias Terminal.Frame
      alias Terminal.Radio
      alias Terminal.Button
      alias Terminal.Select
      alias Terminal.Checkbox
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
    # filter allow for removal of nil children
    quote do
      children = unquote(inner) |> List.flatten()
      children = Enum.filter(children, fn child -> child != nil end)
      {unquote(key), unquote(module), unquote(props), children}
    end
  end

  def use_state(react, key, initial) do
    keys = State.key(react, key)
    current = State.use_state(react, keys, initial)
    pid = assert_pid(react)

    {current,
     fn value ->
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
    assert_pid(react)
    keys = State.key(react, key)
    State.use_callback(react, keys, function)
    fn -> State.get_callback(react, keys).() end
  end

  def use_effect(react, key, function) do
    use_effect(react, key, nil, function)
  end

  def use_effect(react, key, deps, callback) do
    assert_pid(react)
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
    pid = assert_pid(react)
    id = State.new_timer(react)

    callfunc = fn ->
      task = State.get_timer(react, id)
      if task != nil, do: callback.()
    end

    {:ok, task} =
      Task.start_link(fn ->
        stream = Stream.interval(millis)

        Enum.any?(stream, fn _ ->
          send(pid, {:cmd, :callback, callfunc})
          State.get_timer(react, id) == nil
        end)

        Process.unlink(pid)
      end)

    State.set_timer(react, id, task)

    fn ->
      # unlink requires react process
      assert_pid(react)
      task = State.clear_timer(react, id)

      if task != nil do
        Process.unlink(task)
        Process.exit(task, :kill)
      end
    end
  end

  def set_timeout(react, millis, callback) do
    pid = assert_pid(react)
    id = State.new_timer(react)

    callfunc = fn ->
      task = State.clear_timer(react, id)
      if task != nil, do: callback.()
    end

    # Process.send_after is a cancelable an alternative
    {:ok, task} =
      Task.start_link(fn ->
        :timer.sleep(millis)
        send(pid, {:cmd, :callback, callfunc})
        Process.unlink(pid)
      end)

    State.set_timer(react, id, task)

    fn ->
      # unlink requires react process
      assert_pid(react)
      task = State.clear_timer(react, id)

      if task != nil do
        Process.unlink(task)
        Process.exit(task, :kill)
      end
    end
  end

  def clear_timer(timer) do
    timer.()
  end

  def log(msg) do
    # 2022-09-10 20:02:49.684244Z
    now = DateTime.utc_now()
    now = String.slice("#{now}", 11..22)
    IO.puts("#{now} #{inspect(self())} #{msg}")
  end

  defp assert_pid(react) do
    # API restricted to react process
    pid = self()

    case State.pid(react) do
      ^pid -> pid
      pid -> raise "Invalid caller: #{inspect(pid)}"
    end
  end
end
