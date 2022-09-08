defmodule Terminal.Tty do
  def open({module, opts}) do
    state = module.open(opts)
    {module, state}
  end

  def handle({module, state}, msg) do
    case module.handle(state, msg) do
      {state, true, data} -> {{module, state}, true, data}
      {state, false} -> {{module, state}, false}
    end
  end

  def write!({module, state}, data) do
    state = module.write!(state, data)
    {module, state}
  end

  def read!({module, state}) do
    {state, data} = module.read!(state)
    {{module, state}, data}
  end
end
