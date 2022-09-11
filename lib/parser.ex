defmodule Terminal.Parser do
  def parse(list) when is_list(list) do
    list =
      for item <- list do
        quote do
          unquote(item)
        end
      end

    for item <- list, reduce: %{} do
      map ->
        key =
          case item do
            {:markup, _, [key, _, _]} -> key
            {:markup, _, [key, _, _, _]} -> key
          end

        if Map.has_key?(map, key), do: raise("Duplicated key: #{key}")
        Map.put(map, key, key)
    end

    list
  end

  def parse({:__block__, _, list}) when is_list(list) do
    parse(list)
  end

  def parse({:markup, _, _} = single) do
    parse([single])
  end

  def parse(other) do
    quote do
      unquote(other)
    end
  end
end
