defmodule Terminal.App do
  use Terminal.Const
  alias Terminal.Canvas
  alias Terminal.Control
  alias Terminal.State
  alias Terminal.App
  alias Terminal.Nil

  defmacro __using__(_opts) do
    quote do
      @behaviour Terminal.Runnable
      use Terminal.Const
      import Terminal.React
      import Terminal.App, only: [app_init: 2]
      alias Terminal.Panel
      alias Terminal.Label
      alias Terminal.Input
      alias Terminal.Frame
      alias Terminal.Radio
      alias Terminal.Button
      alias Terminal.Select
      alias Terminal.Checkbox
      defdelegate handle(state, event), to: App
      defdelegate render(state, canvas), to: App
      defdelegate execute(cmd), to: App
    end
  end

  defdelegate app_init(function, props), to: App, as: :init

  def init(func, opts) do
    opts = Enum.into(opts, %{})
    react = State.init()
    exec_realize(react, func, opts, %{})
  end

  def handle(%{func: func, opts: opts, key: key, mote: mote, react: react}, event) do
    mote =
      case event do
        {:cmd, :changes, nil} ->
          mote

        {:cmd, :callback, callback} ->
          callback.()
          mote

        _ ->
          on_event = Map.get(opts, :on_event, fn _ -> nil end)
          on_event.(event)
          {mote, _cmd} = mote_handle(react, mote, event)
          mote
      end

    State.reset_state(react)
    map = Control.tree(mote, [key], %{})
    exec_realize(react, func, opts, map)
  end

  def render(%{react: react, mote: mote}, canvas) do
    key = State.get_modal(react)
    exec_render(mote, key, canvas)
  end

  def execute(_cmd), do: nil

  defp exec_render({module, state}, nil, canvas), do: module.render(state, canvas)

  defp exec_render({module, state}, key, canvas) do
    canvas = module.render(state, canvas)
    canvas = Canvas.modal(canvas)

    {module, state} =
      Enum.reduce(key, {module, state}, fn id, {module, state} ->
        children = Enum.into(module.children(state), %{})
        Map.get(children, id)
      end)

    bounds = module.bounds(state)
    canvas = Canvas.push(canvas, bounds)
    canvas = module.render(state, canvas)
    Canvas.pop(canvas)
  end

  defp exec_realize(react, func, opts, map) do
    markup = func.(react, opts)
    {key, mote} = realize(react, markup, map, root: true)
    state = %{func: func, opts: opts, key: key, mote: mote, react: react}
    exec_effects(state)
  end

  defp exec_effects(%{react: react} = state) do
    {effects, cleanups} = State.reset_effects(react)
    State.reset_changes(react)
    exec_cleanups(cleanups)
    exec_effects(effects)

    case State.count_changes(react) do
      0 ->
        {state, nil}

      _ ->
        handle(state, {:cmd, :changes, nil})
    end
  end

  defp exec_effects([]), do: nil

  defp exec_effects([effect | tail]) do
    {_key, {function, _deps}} = effect
    function.()
    exec_effects(tail)
  end

  defp exec_cleanups([]), do: nil

  defp exec_cleanups([cleanup | tail]) do
    {_key, cleanup} = cleanup
    cleanup.()
    exec_cleanups(tail)
  end

  defp is_shortcut({:key, _, key}), do: {Enum.member?(@shortcuts, key), key}
  defp is_shortcut(_), do: false

  defp mote_handle(react, mote, event) do
    case is_shortcut(event) do
      {true, shortcut} ->
        mote_handle(react, mote, {:shortcut, shortcut})

      _ ->
        event_handle(react, mote, event)
    end
  end

  defp event_handle(react, {module, state}, event) do
    key = State.get_modal(react)

    event =
      case key do
        nil -> event
        _ -> {:modal, key, event}
      end

    {state, cmd} = module.handle(state, event)
    {{module, state}, cmd}
  end

  defp eval(react, {modfun, opts, inner}) do
    cond do
      is_function(modfun) ->
        opts = Enum.into(opts, %{})
        res = eval(react, modfun, opts)
        {_, modfun, opts, inner} = res
        eval(react, {modfun, opts, inner})

      is_atom(modfun) ->
        {modfun, opts, inner}
    end
  end

  defp eval(react, modfun, opts) do
    case modfun.(react, opts) do
      nil -> {nil, Nil, [], []}
      res -> res
    end
  end

  defp realize(react, markup, current, extras \\ []) do
    {key, modfun, opts, inner} = markup
    keys = State.push_key(react, key)
    {module, opts, inner} = eval(react, {modfun, opts, inner})
    inner = for item <- inner, do: realize(react, item, current)
    State.pop_key(react)

    state =
      case Map.get(current, keys) do
        {^module, state} ->
          module.update(state, opts)

        _ ->
          module.init(opts ++ extras)
      end

    state = module.children(state, inner)
    set_modal(react, keys, module, state)
    {key, {module, state}}
  end

  defp set_modal(react, key, module, state) do
    visible = module.visible(state)
    modal = module.modal(state)

    if visible and modal do
      [_ | key] = Enum.reverse(key)
      # discard top root
      if key != [] do
        State.set_modal(react, key)
      end
    end
  end
end
