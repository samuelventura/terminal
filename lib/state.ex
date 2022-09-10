defmodule Terminal.State do
  def init() do
    pid = self()

    {:ok, agent} =
      Agent.start_link(fn ->
        %{
          pid: pid,
          keys: [],
          state: %{},
          prestate: %{},
          callbacks: %{},
          changes: %{},
          effects: %{},
          ieffects: [],
          preffects: %{},
          timers: %{},
          timerc: 0
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

  def set_state(agent, key, value) do
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
    :ok =
      Agent.update(agent, fn map ->
        %{
          pid: map.pid,
          keys: [],
          state: %{},
          prestate: map.state,
          callbacks: %{},
          changes: map.changes,
          effects: %{},
          ieffects: [],
          preffects: map.effects,
          timers: map.timers,
          timerc: map.timerc
        }
      end)
  end

  def use_callback(agent, key, function) do
    :ok =
      Agent.update(agent, fn map ->
        callbacks = Map.fetch!(map, :callbacks)
        if Map.has_key?(callbacks, key), do: raise("Duplicated callback key: #{inspect(key)}")
        callbacks = Map.put(callbacks, key, function)
        map = Map.put(map, :callbacks, callbacks)
        map
      end)
  end

  def get_callback(agent, key) do
    Agent.get(agent, fn map -> map.callbacks[key] end)
  end

  @spec use_effect(atom | pid | {atom, any} | {:via, atom, any}, any, any, any) :: :ok
  def use_effect(agent, key, function, deps) do
    :ok =
      Agent.update(agent, fn map ->
        effects = Map.fetch!(map, :effects)
        if Map.has_key?(effects, key), do: raise("Duplicated effect key: #{inspect(key)}")
        map = Map.update!(map, :ieffects, fn ieffects -> [key | ieffects] end)
        effects = Map.put(effects, key, {function, deps})
        map = Map.put(map, :effects, effects)
        map
      end)
  end

  def get_effects(agent) do
    Agent.get(agent, fn map ->
      changes = Map.fetch!(map, :changes)
      effects = Map.fetch!(map, :effects)
      ieffects = Map.fetch!(map, :ieffects)
      preffects = Map.fetch!(map, :preffects)

      effects = for key <- Enum.reverse(ieffects), do: {key, effects[key]}

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

  def new_timer(agent) do
    Agent.get_and_update(agent, fn map ->
      id = map.timerc

      map =
        Map.update!(map, :timers, fn timers ->
          Map.put(timers, id, nil)
        end)

      {id, %{map | timerc: id + 1}}
    end)
  end

  def get_timer(agent, id) do
    Agent.get(agent, fn map -> map.timers[id] end)
  end

  def set_timer(agent, id, payload) do
    :ok =
      Agent.update(agent, fn map ->
        Map.update!(map, :timers, fn timers ->
          Map.update!(timers, id, fn _ -> payload end)
        end)
      end)
  end

  def remove_timer(agent, id) do
    :ok =
      Agent.update(agent, fn map ->
        Map.update!(map, :timers, fn timers ->
          Map.delete(timers, id)
        end)
      end)
  end
end
