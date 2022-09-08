defmodule Terminal.Linux do
  use Terminal.Const

  # https://man7.org/linux/man-pages/man4/console_codes.4.html
  # cursor styles not supported
  # limited text styles support
  # 8 colors only
  #
  # forecolors 8-15 render as dimmed but get reset if more then 16 colors
  # are used at once by abusing bgcolor/dimmed/bold combinations
  def clear(:all), do: "\ec"
  def clear(:screen), do: "\e[2J"
  def clear(:styles), do: "\e[0m"

  def query(:size), do: "\e[s\e[999;999H\e[6n\e[u"

  # standard required to enable extended
  def mouse(:standard), do: "\e[?1000h"
  def mouse(:extended), do: "\e[?1006h"

  def cursor(:style, _), do: ""
  def cursor(column, line), do: "\e[#{line + 1};#{column + 1}H"

  def show(:cursor), do: "\e[?25h"
  def hide(:cursor), do: "\e[?25l"

  def color(:fgcolor, name), do: "\e[38;5;#{rem(color_id(name), 16)}m"
  def color(:bgcolor, name), do: "\e[48;5;#{rem(color_id(name), 8)}m"

  def set(:bold), do: "\e[1m"
  def set(:dimmed), do: "\e[2m"
  def set(:inverse), do: "\e[7m"
  def set(_), do: ""

  # normal reset both bold and dimmed
  def reset(:normal), do: "\e[22m"
  def reset(:inverse), do: "\e[27m"
  def reset(_), do: ""

  def append(buffer, data) do
    buffer = buffer <> data
    scan(buffer, [])
  end

  @resize ~r/^\e\[(\d+);(\d+)R/

  # thinkpad/corsair usb us keyboard
  @escapes [
    {"\e[[A", :f1},
    {"\e[[B", :f2},
    {"\e[[C", :f3},
    {"\e[[D", :f4},
    {"\e[[E", :f5},
    {"\e[17~", :f6},
    {"\e[18~", :f7},
    {"\e[19~", :f8},
    {"\e[20~", :f9},
    {"\e[21~", :f10},
    {"\e[23~", :f11},
    {"\e[24~", :f12},
    {"\e[1~", :home},
    {"\e[2~", :insert},
    {"\e[3~", :delete},
    {"\e[4~", :end},
    {"\e[5~", :page_up},
    {"\e[6~", :page_down},
    {"\e[A", :arrow_up},
    {"\e[B", :arrow_down},
    {"\e[C", :arrow_right},
    {"\e[D", :arrow_left}
  ]

  @singles [
    {"\d", {@fun, :backspace}},
    {"\a", {@ctl, "g"}},
    {"\b", {@ctl, "h"}},
    {"\v", {@ctl, "k"}},
    {"\f", {@ctl, "l"}},
    # {"\t", {@ctl, "i"}},
    # {"\n", {@ctl, "j"}},
    # {"\r", {@ctl, "m"}},
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

  defp resize(nil, buffer) do
    case Regex.run(@resize, buffer) do
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
