defmodule Terminal.Code do
  @behaviour Terminal.Term
  use Terminal.Const

  # works unchanged on macos terminal
  # first output line goes to bottom
  def init(),
    do:
      [
        clear(:all),
        hide(:cursor),
        mouse(:standard),
        mouse(:extended),
        set(:cursor, :blinking_underline)
      ]
      |> IO.iodata_to_binary()

  def query(:size), do: "\e[s\e[999;999H\e[6n\e[u"
  def hide(:cursor), do: "\e[?25l"
  def show(:cursor), do: "\e[?25h"
  def cursor(column, line), do: "\e[#{line + 1};#{column + 1}H"
  # bright colors are shifted by 8 but frame chars wont show in bblack
  def color(:fore, color), do: "\e[38;5;#{rem(color, 16)}m"
  def color(:back, color), do: "\e[48;5;#{rem(color, 8)}m"

  def append(buffer, data) do
    buffer = buffer <> data
    scan(buffer, [])
  end

  # https://xtermjs.org/docs/api/vtfeatures/
  # xtermjs wont suppot blink #944
  defp clear(:all), do: "\ec"
  # defp clear(:screen), do: "\e[2J"
  # defp clear(:styles), do: "\e[0m"

  # standard required to enable extended
  defp mouse(:standard), do: "\e[?1000h"
  defp mouse(:extended), do: "\e[?1006h"

  # defp set(:cursor, @blinking_block), do: "\e[1 q"
  # defp set(:cursor, @steady_block), do: "\e[2 q"
  defp set(:cursor, :blinking_underline), do: "\e[3 q"
  # # defp set(:cursor, @steady_underline), do: "\e[4 q"
  # # defp set(:cursor, @blinking_bar), do: "\e[5 q"
  # # defp set(:cursor, @steady_bar), do: "\e[6 q"
  # # defp set(:bold), do: "\e[1m"
  # defp set(:dimmed), do: "\e[2m"
  # defp set(:italic), do: "\e[3m"
  # defp set(:underline), do: "\e[4m"
  # defp set(:inverse), do: "\e[7m"
  # defp set(:crossed), do: "\e[9m"
  # defp set(_), do: ""

  # normal reset both bold and dimmed
  # defp reset(:normal), do: "\e[22m"
  # defp reset(:italic), do: "\e[23m"
  # defp reset(:underline), do: "\e[24m"
  # defp reset(:inverse), do: "\e[27m"
  # defp reset(:crossed), do: "\e[29m"
  # defp reset(_), do: ""

  @size_re ~r/^\e\[(\d+);(\d+)R/
  @mouse_re ~r/^\e\[M(.)(.)(.)/
  @mouse_down_re ~r/^\e\[<(\d+);(\d+);(\d+)M/
  @mouse_up_re ~r/^\e\[<(\d+);(\d+);(\d+)m/

  # thinkpad/corsair usb us keyboard
  @escapes [
    # working in linux
    {"\eOQ", @f2},
    {"\eOS", @f4},
    {"\e[18~", @f7},
    {"\e[19~", @f8},
    {"\e[20~", @f9},
    {"\e[21~", @f10},
    {"\e[24~", @f12},
    {"\e[H", @home},
    {"\e[2~", @insert},
    {"\e[3~", @delete},
    {"\e[F", @hend},
    {"\e[5~", @page_up},
    {"\e[6~", @page_down},
    {"\e[A", @arrow_up},
    {"\e[B", @arrow_down},
    {"\e[C", @arrow_right},
    {"\e[D", @arrow_left},
    # macos
    # delete = fn + backspace
    # shift + up/down
    {"\e[1;2A", @page_up},
    {"\e[1;2B", @page_down},
    # option + up/down
    {"\e[1;3A", @home},
    {"\e[1;3B", @hend},
    # os/code traps these
    {"\e[[A", @f1},
    {"\e[[C", @f3},
    {"\e[[E", @f5},
    {"\e[17~", @f6},
    {"\e[23~", @f11}
  ]

  @singles [
    {"\d", {@fun, @backspace}},
    {<<0>>, {@ctl, "2"}},
    {<<28>>, {@ctl, "4"}},
    {<<29>>, {@ctl, "5"}},
    {<<30>>, {@ctl, "6"}},
    {<<31>>, {@ctl, "7"}},
    {<<17>>, {@ctl, "q"}},
    {<<23>>, {@ctl, "w"}},
    {<<5>>, {@ctl, "e"}},
    {<<18>>, {@ctl, "r"}},
    {<<20>>, {@ctl, "t"}},
    {<<25>>, {@ctl, "y"}},
    {<<21>>, {@ctl, "u"}},
    {<<15>>, {@ctl, "o"}},
    {<<16>>, {@ctl, "p"}},
    {<<1>>, {@ctl, "a"}},
    {<<19>>, {@ctl, "s"}},
    {<<4>>, {@ctl, "d"}},
    {<<6>>, {@ctl, "f"}},
    {"\a", {@ctl, "g"}},
    {"\b", {@ctl, "h"}},
    {"\v", {@ctl, "k"}},
    {"\f", {@ctl, "l"}},
    {<<26>>, {@ctl, "z"}},
    {<<24>>, {@ctl, "x"}},
    {<<3>>, {@ctl, "c"}},
    {<<22>>, {@ctl, "v"}},
    {<<2>>, {@ctl, "b"}},
    {<<14>>, {@ctl, "n"}}
    # tab -> "\t"
    # prtsc -> <<28>>
    # ctrl_` -> ctrl_2
    # ctrl_1 -> silent
    # ctrl_3 -> \e
    # ctrl_8 -> \d
    # ctrl_9 -> silent
    # ctrl_0 -> silent
    # ctrl_- -> <<31>>
    # ctrl_= -> silent
    # ctrl_back -> \b ctrl_h
    # ctrl_\t -> silent
    # ctrl_m -> \r
    # ctrl_[ -> \e
    # ctrl_] -> ctrl_5
    # ctrl_\ -> :prtsc
    # ctrl_; -> silent
    # ctrl_' -> ctrl_g
    # ctrl_, -> silent
    # ctrl_. -> silent
    # ctrl_/ -> silent
    # ctrl_space -> ctrl_2
    # ctrl_i -> \t
    # ctrl_j -> \n (blocked input at some point)
  ]

  @singles_map @singles |> Enum.into(%{})

  defp scan("", events) do
    {"", Enum.reverse(events)}
  end

  defp scan(buffer, events) do
    {prefix, event} = scan(buffer)
    buffer = tail(buffer, prefix)
    scan(buffer, [event | events])
  end

  defp scan("\e" <> _ = buffer) do
    nil
    |> mouse(buffer, @mouse_re)
    |> mouse_ex(buffer, @mouse_up_re, @mouse_up)
    |> mouse_ex(buffer, @mouse_down_re, @mouse_down)
    |> escapes(buffer)
    |> resize(buffer)
    |> altkey(buffer)
    |> default({"\e", {:key, 0, "\e"}})
  end

  defp scan(<<k>> <> _) do
    singles(<<k>>) |> default({<<k>>, {:key, 0, <<k>>}})
  end

  defp singles(single) do
    case Map.get(@singles_map, single) do
      nil ->
        nil

      code ->
        {flag, key} = code
        {single, {:key, flag, key}}
    end
  end

  defp mouse(nil, buffer, regex) do
    case Regex.run(regex, buffer) do
      [prefix, s, x, y] ->
        [s] = String.to_charlist(s)
        [x] = String.to_charlist(x)
        [y] = String.to_charlist(y)
        {prefix, {:mouse, s - 32, x - 32 - 1, y - 32 - 1}}

      nil ->
        nil
    end
  end

  defp mouse_ex(nil, buffer, regex, code) do
    case Regex.run(regex, buffer) do
      [prefix, s, x, y] ->
        s = String.to_integer(s)
        x = String.to_integer(x) - 1
        y = String.to_integer(y) - 1
        {prefix, {:mouse, s, x, y, code}}

      nil ->
        nil
    end
  end

  defp mouse_ex(prev, _, _, _), do: prev

  defp escapes(nil, buffer) do
    Enum.find_value(@escapes, fn {prefix, code} ->
      case String.starts_with?(buffer, prefix) do
        true ->
          {prefix, {:key, @fun, code}}

        false ->
          nil
      end
    end)
  end

  defp escapes(prev, _), do: prev

  defp resize(nil, buffer) do
    case Regex.run(@size_re, buffer) do
      [prefix, h, w] ->
        w = String.to_integer(w)
        h = String.to_integer(h)
        {prefix, {:resize, w, h}}

      nil ->
        nil
    end
  end

  defp resize(prev, _), do: prev

  defp altkey(nil, "\e" <> <<k>> <> _) do
    case Map.get(@singles_map, <<k>>) do
      nil ->
        {"\e" <> <<k>>, {:key, @alt, <<k>>}}

      code ->
        {flag, key} = code
        flag = Bitwise.bor(flag, @alt)
        {"\e" <> <<k>>, {:key, flag, key}}
    end
  end

  defp altkey(prev, _), do: prev

  defp default(nil, def), do: def
  defp default(prev, _), do: prev

  defp tail(buffer, prefix) do
    bl = String.length(buffer)
    pl = String.length(prefix)
    String.slice(buffer, pl, bl)
  end
end
