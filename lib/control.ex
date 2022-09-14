defmodule Terminal.Control do
  @callback init(opts :: any()) :: state :: any()
  @callback handle(state :: any(), event :: any()) :: {state :: any(), cmd :: any()}
  @callback render(state :: any(), canvas :: any()) :: canvas :: any()
  @callback bounds(state :: any()) :: {integer(), integer(), integer(), integer()}
  @callback refocus(state :: any(), dir :: any()) :: state :: any()
  @callback focused(state :: any(), true | false) :: state :: any()
  @callback focused(state :: any()) :: true | false
  @callback focusable(state :: any()) :: true | false
  @callback findex(state :: any()) :: integer()
  @callback children(state :: any()) :: Keyword.t()
  @callback children(state :: any(), Keyword.t()) :: any()
  @callback update(state :: any(), Keyword.t()) :: any()

  def merge(map, props) do
    for {key, value} <- props, reduce: map do
      map ->
        if !Map.has_key?(map, key), do: raise("Invalid prop #{key}: #{inspect(value)}")
        Map.put(map, key, value)
    end
  end
end
