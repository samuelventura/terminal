defmodule Terminal.State do
  def init() do
    pid = self()

    {:ok, agent} =
      Agent.start_link(fn ->
        %{
          pid: pid,
          cycle: 0,
          keys: [],
          state: %{},
          prestate: %{},
          changes: %{},
          effects: %{},
          preffects: %{}
        }
      end)

    agent
  end

  def pid(agent) do
    Agent.get(agent, fn map -> map.pid end)
  end

  def push(agent, key) do
    Agent.get_and_update(agent, fn map ->
      keys = [key | map.keys]
      {keys, %{map | keys: keys}}
    end)
  end

  def pop(agent) do
    Agent.get_and_update(agent, fn map ->
      [key | tail] = map.keys
      {key, %{map | keys: tail}}
    end)
  end

  def key(agent, key) do
    Agent.get(agent, fn map -> [key | map.keys] end)
  end

  def use_state(agent, key, value) do
    Agent.get_and_update(agent, fn map ->
      state = Map.fetch!(map, :state)
      if Map.has_key?(state, key), do: raise("Duplicated state key: #{inspect(key)}")
      prestate = Map.fetch!(map, :prestate)
      value = Map.get(prestate, key, value)
      state = Map.put(state, key, value)
      map = Map.put(map, :state, state)
      {value, map}
    end)
  end

  def put_state(agent, key, value) do
    :ok =
      Agent.update(agent, fn map ->
        state = Map.fetch!(map, :state)
        changes = Map.fetch!(map, :changes)

        {change, state} =
          Map.get_and_update!(state, key, fn curr ->
            {curr != value, value}
          end)

        inc = if change, do: 1, else: 0

        changes =
          Map.update(changes, key, inc, fn curr ->
            curr + inc
          end)

        map = Map.put(map, :state, state)
        map = Map.put(map, :changes, changes)
        map
      end)
  end

  def reset_state(agent) do
    Agent.get_and_update(agent, fn map ->
      cycle = map.cycle + 1

      {cycle,
       %{
         pid: map.pid,
         cycle: cycle,
         keys: [],
         state: %{},
         prestate: map.state,
         changes: map.changes,
         effects: %{},
         preffects: map.effects
       }}
    end)
  end

  def use_effect(agent, key, function, deps) do
    :ok =
      Agent.update(agent, fn map ->
        effects = Map.fetch!(map, :effects)
        if Map.has_key?(effects, key), do: raise("Duplicated effect key: #{inspect(key)}")
        effects = Map.put(effects, key, {function, deps})
        map = Map.put(map, :effects, effects)
        map
      end)
  end

  def get_effects(agent) do
    Agent.get(agent, fn map ->
      effects = Map.fetch!(map, :effects)
      changes = Map.fetch!(map, :changes)
      preffects = Map.fetch!(map, :preffects)

      Enum.filter(effects, fn {key, {_function, deps}} ->
        [_ | parent] = key

        case deps do
          nil -> true
          [] -> !Map.has_key?(preffects, key)
          _ -> Enum.all?(deps, fn dep -> Map.get(changes, [dep | parent], 0) > 0 end)
        end
      end)
    end)
  end

  def reset_changes(agent) do
    :ok = Agent.update(agent, fn map -> Map.put(map, :changes, %{}) end)
  end

  def count_changes(agent) do
    Agent.get(agent, fn map -> map_size(map.changes) end)
  end
end
