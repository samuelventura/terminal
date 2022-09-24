defmodule Terminal.Runner do
  alias Terminal.Tty
  alias Terminal.Runnable
  alias Terminal.Canvas
  require Log

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
    break = Keyword.get(opts, :break)
    tty = Tty.open(tty)
    tty = Tty.write!(tty, term.init())
    query = term.query(:size)
    tty = Tty.write!(tty, query)
    size(tty, term, "", app, break)
  end

  # wait for size instead of tty.read! which raises on :stop event
  defp size(tty, term, buffer, app, break) do
    receive do
      {:stop, pid} ->
        if pid != nil, do: send(pid, {:ok, :stop, self()})

      msg ->
        case Tty.handle(tty, msg) do
          {_tty, :exit} ->
            raise "#{inspect(msg)}"

          {tty, :data, data} ->
            {buffer, events} = term.append(buffer, data)

            case find_resize(events) do
              {:resize, width, height} ->
                canvas = Canvas.new(width, height)
                {app, cmd} = Runnable.init(app, size: {width, height})
                execute_cmd(app, cmd)
                {tty, canvas} = render(tty, term, app, canvas)
                loop(tty, term, "", app, canvas, break)

              _ ->
                size(tty, term, buffer, app, break)
            end

          _ ->
            size(tty, term, buffer, app, break)
        end
    end
  end

  defp stop(tty, term, app, canvas) do
    app = apply_event(app, :stop)
    {tty, _} = render(tty, term, app, canvas)
    tty = Tty.write!(tty, term.reset())
    Runnable.cleanup(app)
    Tty.close(tty)
  end

  defp loop(tty, term, buffer, app, canvas, break) do
    receive do
      {:stop, pid} ->
        stop(tty, term, app, canvas)
        if pid != nil, do: send(pid, {:ok, :stop, self()})

      :SIGWINCH ->
        query = term.query(:size)
        tty = Tty.write!(tty, query)
        loop(tty, term, buffer, app, canvas, break)

      {:cmd, cmd, res} ->
        app = apply_event(app, {:cmd, cmd, res})
        {tty, canvas} = render(tty, term, app, canvas)
        loop(tty, term, buffer, app, canvas, break)

      msg ->
        case Tty.handle(tty, msg) do
          {tty, :data, data} ->
            Log.log("#{inspect(data)}")
            {buffer, events} = term.append(buffer, data)
            Log.log("#{inspect(events)}")
            app = apply_events(app, events)

            # glitch on horizontal resize because of auto line wrapping
            # this should correct any glitch from size query
            {tty, canvas} =
              case find_resize(events) do
                {:resize, width, height} ->
                  tty = Tty.write!(tty, term.init())
                  canvas = Canvas.new(width, height)
                  {tty, canvas}

                _ ->
                  {tty, canvas}
              end

            {tty, canvas} = render(tty, term, app, canvas)

            case find_break(events, break) do
              true -> stop(tty, term, app, canvas)
              _ -> loop(tty, term, buffer, app, canvas, break)
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

  defp find_break(events, break) do
    Enum.find_value(events, fn event ->
      case event do
        ^break -> true
        _ -> false
      end
    end)
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
        Log.log("#{inspect(data)}")
        tty = Tty.write!(tty, data)
        {tty, canvas2}
    end
  end
end
