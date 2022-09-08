defmodule Terminal.Window do
  @callback init(opts :: any()) :: state :: any()
  @callback handle(state :: any(), event :: any()) :: {state :: any(), cmd :: any()}
  @callback render(state :: any(), canvas :: any()) :: canvas :: any()
  @callback bounds(state :: any()) :: {integer(), integer(), integer(), integer()}
  @callback focused(state :: any(), true | false) :: state :: any()
  @callback focused(state :: any()) :: true | false
  @callback focusable(state :: any()) :: true | false
  @callback findex(state :: any()) :: integer()
  @callback children(state :: any()) :: Keyword.t()
  @callback children(state :: any(), Keyword.t()) :: any()
  @callback update(state :: any(), Keyword.t()) :: any()
end
