defmodule Log do
  @logs false

  defmacro log(msg) do
    if @logs do
      # remove Elixir from begining of name
      module = __CALLER__.module |> Atom.to_string() |> String.slice(7, 9999)

      quote do
        msg = unquote(msg)
        module = unquote(module)
        # 2022-09-10 20:02:49.684244Z
        now = DateTime.utc_now()
        now = String.slice("#{now}", 11..22)
        IO.puts("#{now} #{inspect(self())} #{module} #{msg}")
      end
    end
  end
end
