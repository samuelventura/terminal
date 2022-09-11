defmodule Terminal.App do
  alias Terminal.State
  alias Terminal.App

  defmacro __using__(_opts) do
    quote do
      @behaviour Terminal.Runnable
      use Terminal.Const
      import Terminal.React
      import Terminal.App, only: [app_init: 2]
      alias Terminal.Panel
      alias Terminal.Label
      alias Terminal.Button
      alias Terminal.Input
      alias Terminal.Frame
      alias Terminal.Select
      alias Terminal.Radio
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
          {mote, _cmd} = mote_handle(mote, event)
          mote
      end

    State.reset_state(react)
    map = mote_to_map(mote, [key], %{})
    exec_realize(react, func, opts, map)
  end

  def render(%{mote: {module, state}}, canvas), do: module.render(state, canvas)
  def execute(_cmd), do: nil

  defp exec_realize(react, func, opts, map) do
    markup = func.(react, opts)
    {key, mote} = realize(react, markup, map, focused: true, root: true)
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

  defp mote_to_map({module, state}, keys, map) do
    map =
      for {key, mote} <- module.children(state), reduce: map do
        map -> mote_to_map(mote, [key | keys], map)
      end

    Map.put(map, keys, {module, state})
  end

  defp mote_handle({module, state}, event) do
    {state, cmd} = module.handle(state, event)
    {{module, state}, cmd}
  end

  defp eval(react, {modfun, opts, inner}) do
    cond do
      is_function(modfun) ->
        opts = Enum.into(opts, %{})
        {_, modfun, opts, inner} = modfun.(react, opts)
        eval(react, {modfun, opts, inner})

      is_atom(modfun) ->
        {modfun, opts, inner}
    end
  end

  defp realize(react, markup, current, extras \\ []) do
    {key, modfun, opts, inner} = markup
    keys = State.push(react, key)
    {module, opts, inner} = eval(react, {modfun, opts, inner})
    inner = for item <- inner, do: realize(react, item, current)
    State.pop(react)

    state =
      case Map.get(current, keys) do
        {^module, state} ->
          module.update(state, opts)

        _ ->
          module.init(opts ++ extras)
      end

    state = module.children(state, inner)
    {key, {module, state}}
  end
end
