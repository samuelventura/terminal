defmodule Terminal.Tty do
  def open({module, opts}) do
    state = module.open(opts)
    {module, state}
  end

  def handle({module, state}, msg) do
    case module.handle(state, msg) do
      {state, :data, data} -> {{module, state}, :data, data}
      {state, :exit} -> {{module, state}, :exit}
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

  def close({module, state}) do
    module.close(state)
  end
end
