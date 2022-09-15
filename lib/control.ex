defmodule Terminal.Control do
  @callback init(opts :: any()) :: state :: any()
  @callback handle(state :: any(), event :: any()) :: {state :: any(), cmd :: any()}
  @callback render(state :: any(), canvas :: any()) :: canvas :: any()
  @callback bounds(state :: any()) :: {integer(), integer(), integer(), integer()}
  @callback visible(state :: any()) :: true | false
  @callback focusable(state :: any()) :: true | false
  @callback focused(state :: any(), true | false) :: state :: any()
  @callback focused(state :: any()) :: true | false
  @callback refocus(state :: any(), dir :: any()) :: state :: any()
  @callback findex(state :: any()) :: integer()
  @callback children(state :: any()) :: Keyword.t()
  @callback children(state :: any(), Keyword.t()) :: any()
  @callback shortcut(state :: any()) :: any()
  @callback modal(state :: any()) :: true | false
  @callback update(state :: any(), Keyword.t()) :: any()

  def init(module, opts \\ []), do: {module, module.init(opts)}

  def merge(map, props) do
    for {key, value} <- props, reduce: map do
      map ->
        if !Map.has_key?(map, key), do: raise("Invalid prop #{key}: #{inspect(value)}")
        Map.put(map, key, value)
    end
  end

  def coalesce(map, key, value) do
    case {Map.has_key?(map, key), Map.get(map, key)} do
      {true, nil} -> Map.put(map, key, value)
      _ -> map
    end
  end

  def tree({module, state}, keys \\ [], map \\ %{}) do
    map =
      for {key, mote} <- module.children(state), reduce: map do
        map -> tree(mote, [key | keys], map)
      end

    Map.put(map, keys, {module, state})
  end
end
