defmodule Terminal.App do
  alias Terminal.State
  alias Terminal.App

  defmacro __using__(_opts) do
    quote do
      @behaviour Terminal.Runnable
      import Terminal.React
      import Terminal.App, only: [app_init: 2]
      defdelegate handle(state, event), to: App
      defdelegate render(state, canvas), to: App
      defdelegate execute(cmd), to: App
    end
  end

  defdelegate app_init(function, props), to: App, as: :init

  def init(func, opts) do
    opts = Enum.into(opts, %{})
    react = State.init()
    markup = func.(react, opts)
    {key, mote} = realize(react, markup, %{}, focused: true, root: true)
    state = %{func: func, opts: opts, key: key, mote: mote, react: react}
    {state, nil}
  end

  def handle(%{func: func, opts: opts, key: key, mote: mote, react: react}, event) do
    {mote, _cmd} = mote_handle(mote, event)
    # IO.inspect({event, cmd})
    current = mote_to_map(mote, [key], %{})
    State.reset(react)
    markup = func.(react, opts)
    {key, mote} = realize(react, markup, current, focused: true, root: true)
    state = %{func: func, opts: opts, key: key, mote: mote, react: react}
    {state, nil}
  end

  def render(%{mote: {module, state}}, canvas), do: module.render(state, canvas)
  def execute(_cmd), do: nil

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
