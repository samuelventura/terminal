defmodule Terminal.React do
  alias Terminal.State

  defmacro markup(key, modfun, props) do
    quote do
      {unquote(key), unquote(modfun), unquote(props), []}
    end
  end

  defmacro markup(key, module, props, do: inner) do
    inner = inner_to_list(inner)

    quote do
      {unquote(key), unquote(module), unquote(props), unquote(inner)}
    end
  end

  def use_state(react, key, initial) do
    keys = State.key(react, key)
    current = State.use_state(react, keys, initial)

    {current,
     fn value ->
       pid = State.pid(react)

       case self() == pid do
         true ->
           State.put_state(react, keys, value)

         false ->
           callback = fn -> State.put_state(react, keys, value) end
           send(pid, {:cmd, :callback, callback})
       end
     end}
  end

  def use_effect(react, key, deps, function) do
    keys = State.key(react, key)
    State.use_effect(react, keys, function, deps)
  end

  defp inner_to_list(list) when is_list(list) do
    list =
      for item <- list do
        quote do
          unquote(item)
        end
      end

    for {_, _, [key, _, _]} <- list, reduce: %{} do
      map ->
        if Map.has_key?(map, key), do: raise("Duplicated key: #{key}")
        Map.put(map, key, key)
    end

    list
  end

  defp inner_to_list({:__block__, _, list}) when is_list(list) do
    inner_to_list(list)
  end

  defp inner_to_list({:markup, _, _} = single) do
    inner_to_list([single])
  end
end
