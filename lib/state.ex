defmodule Terminal.State do
  def init() do
    {:ok, agent} = Agent.start_link(fn -> {[], %{}, %{}} end)
    agent
  end

  def push(agent, key) do
    Agent.get_and_update(agent, fn {keys, map1, map2} ->
      keys = [key | keys]
      {keys, {keys, map1, map2}}
    end)
  end

  def pop(agent) do
    Agent.get_and_update(agent, fn {[key | tail], map1, map2} -> {key, {tail, map1, map2}} end)
  end

  def reset(agent) do
    :ok =
      Agent.update(agent, fn {_keys, map1, _map2} ->
        {[], %{}, map1}
      end)
  end

  def key(agent, key) do
    Agent.get(agent, fn {keys, _map1, _map2} -> [key | keys] end)
  end

  def use(agent, key, value) do
    Agent.get_and_update(agent, fn {keys, map1, map2} ->
      if Map.has_key?(map1, key), do: raise("Duplicated key: #{inspect(key)}")
      value = Map.get(map2, key, value)
      map1 = Map.put(map1, key, value)
      {value, {keys, map1, map2}}
    end)
  end

  def put(agent, key, value) do
    :ok =
      Agent.update(agent, fn {keys, map1, map2} ->
        map1 = Map.put(map1, key, value)
        {keys, map1, map2}
      end)
  end
end
