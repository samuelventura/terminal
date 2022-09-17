defmodule Terminal.Runner do
  use Terminal.Const
  alias Terminal.Tty
  alias Terminal.Runnable
  alias Terminal.Canvas

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts}
    }
  end

  def start_link(opts) do
    Task.start_link(fn -> run(opts) end)
  end

  def run(opts) do
    tty = Keyword.fetch!(opts, :tty)
    term = Keyword.fetch!(opts, :term)
    app = Keyword.fetch!(opts, :app)
    tty = Tty.open(tty)
    tty = init_tty(tty, term)
    {tty, size} = query_size(tty, term)
    {width, height} = size
    canvas = Canvas.new(width, height)
    {app, cmd} = Runnable.init(app, size: size)
    execute_cmd(app, cmd)
    {tty, canvas} = render(tty, term, app, canvas)
    loop(tty, term, "", app, canvas)
  end

  # code cursor not shown under inverse
  # setup code cursor to linux default
  defp init_tty(tty, term) do
    Tty.write!(tty, term.init())
  end

  defp close_tty(tty, term) do
    tty = Tty.write!(tty, term.reset())
    Tty.close(tty)
  end

  defp loop(tty, term, buffer, app, canvas) do
    receive do
      {:exit, pid} ->
        # normal exit
        close_tty(tty, term)
        send(pid, {:ok, self()})

      {:cmd, cmd, res} ->
        app = apply_event(app, {:cmd, cmd, res})
        {tty, canvas} = render(tty, term, app, canvas)
        loop(tty, term, buffer, app, canvas)

      :SIGWINCH ->
        query = term.query(:size)
        tty = Tty.write!(tty, query)
        loop(tty, term, buffer, app, canvas)

      msg ->
        case Tty.handle(tty, msg) do
          {tty, true, data} ->
            # IO.inspect(data)
            {buffer, events} = term.append(buffer, data)
            # IO.inspect(events)
            app = apply_events(app, events)

            # glitch on horizontal resize because of auto line wrapping
            {tty, canvas} =
              case find_resize(events) do
                {:resize, width, height} ->
                  tty = init_tty(tty, term)
                  canvas = Canvas.new(width, height)
                  {tty, canvas}

                _ ->
                  {tty, canvas}
              end

            {tty, canvas} = render(tty, term, app, canvas)

            case find_break(events) do
              {:key, @ctl, "c"} -> close_tty(tty, term)
              _ -> loop(tty, term, buffer, app, canvas)
            end

          _ ->
            raise "#{inspect(msg)}"
        end
    end
  end

  defp apply_events(app, []), do: app

  defp apply_events(app, [event | tail]) do
    app = apply_event(app, event)
    apply_events(app, tail)
  end

  defp apply_event(app, event) do
    {app, cmd} = Runnable.handle(app, event)
    execute_cmd(app, cmd)
    app
  end

  defp find_resize(events) do
    Enum.find(events, fn event ->
      case event do
        {:resize, _, _} -> true
        _ -> false
      end
    end)
  end

  defp find_break(events) do
    Enum.find(events, fn event ->
      case event do
        {:key, @ctl, "c"} -> true
        _ -> false
      end
    end)
  end

  defp query_size(tty, term) do
    query = term.query(:size)
    tty = Tty.write!(tty, query)
    wait_size(tty, term)
  end

  defp wait_size(tty, term) do
    {tty, data} = Tty.read!(tty)
    {"", events} = term.append("", data)
    # ignores buffered events
    case find_resize(events) do
      {:resize, w, h} -> {tty, {w, h}}
      _ -> wait_size(tty, term)
    end
  end

  defp execute_cmd(_, nil), do: nil

  defp execute_cmd(app, cmd) do
    self = self()

    spawn(fn ->
      try do
        res = Runnable.execute(app, cmd)
        send(self, {:cmd, cmd, res})
      rescue
        e ->
          send(self, {:cmd, cmd, e})
      end
    end)
  end

  defp render(tty, term, app, canvas1) do
    {width, size} = Canvas.get(canvas1, :size)
    canvas2 = Canvas.new(width, size)
    canvas2 = Runnable.render(app, canvas2)
    {cursor1, _, _} = Canvas.get(canvas1, :cursor)
    {cursor2, _, _} = Canvas.get(canvas2, :cursor)
    diff = Canvas.diff(canvas1, canvas2)
    # do not hide cursor for empty or cursor only diffs
    # hide cursor before write or move and then restore
    diff =
      case diff do
        [] ->
          diff

        [{:c, _}] ->
          diff

        _ ->
          case {cursor1, cursor2} do
            {true, true} ->
              diff = [{:c, true} | diff]
              diff = :lists.reverse(diff)
              [{:c, false} | diff]

            {true, false} ->
              diff = :lists.reverse(diff)
              [{:c, false} | diff]

            _ ->
              :lists.reverse(diff)
          end
      end

    case diff do
      [] ->
        {tty, canvas2}

      _ ->
        data = Canvas.encode(term, diff)
        data = IO.iodata_to_binary(data)
        # IO.inspect(data)
        tty = Tty.write!(tty, data)
        {tty, canvas2}
    end
  end
end
