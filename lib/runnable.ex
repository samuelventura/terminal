defmodule Terminal.Runnable do
  @callback init(opts :: any()) :: {state :: any(), cmd :: any()}
  @callback handle(state :: any(), event :: any()) :: {state :: any(), cmd :: any()}
  @callback render(state :: any(), canvas :: any()) :: canvas :: any()
  @callback execute(cmd :: any()) :: result :: any()

  def init({module, opts}, extras \\ []) do
    {state, cmd} = module.init(opts ++ extras)
    {{module, state}, cmd}
  end

  def handle({module, state}, event) do
    {state, cmd} = module.handle(state, event)
    {{module, state}, cmd}
  end

  def render({module, state}, canvas) do
    module.render(state, canvas)
  end

  def execute({module, _state}, cmd) do
    module.execute(cmd)
  end
end
