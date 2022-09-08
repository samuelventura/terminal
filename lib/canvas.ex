defmodule Terminal.Canvas do
  use Terminal.Const

  @cell {' ', @white, @black}

  def new(width, height) do
    %{
      x: 0,
      y: 0,
      data: %{},
      width: width,
      height: height,
      cursor: {false, 0, 0},
      fgcolor: @white,
      bgcolor: @black,
      clip: {0, 0, width, height},
      clips: []
    }
  end

  def push(%{clips: clips} = canvas, bounds) do
    canvas = %{canvas | clips: [bounds | clips]}
    update_clip(canvas)
  end

  def pop(%{clips: [_ | tail]} = canvas) do
    canvas = %{canvas | clips: tail}
    update_clip(canvas)
  end

  defp update_clip(%{width: width, height: height, clips: clips} = canvas) do
    clip = {0, 0, width, height}

    clip =
      for {ix, iy, iw, ih} <- Enum.reverse(clips), reduce: clip do
        {ax, ay, aw, ah} ->
          w = min(iw, aw - ix)
          h = min(ih, ah - iy)
          {ax + ix, ay + iy, w, h}
      end

    %{canvas | clip: clip}
  end

  def get(%{width: width, height: height}, :size) do
    {width, height}
  end

  def get(%{cursor: cursor}, :cursor) do
    cursor
  end

  def clear(canvas, :colors) do
    %{canvas | fgcolor: @white, bgcolor: @black}
  end

  def move(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | x: cx + x, y: cy + y}
  end

  def cursor(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | cursor: {true, cx + x, cy + y}}
  end

  def color(canvas, :fgcolor, name) do
    %{canvas | fgcolor: color_id(name)}
  end

  def color(canvas, :bgcolor, name) do
    %{canvas | bgcolor: color_id(name)}
  end

  # writes a single line clipping excess to avoid terminal wrapping
  def write(canvas, chardata) do
    %{
      x: x,
      y: y,
      data: data,
      fgcolor: fg,
      bgcolor: bg,
      clip: {cx, cy, cw, ch}
    } = canvas

    mx = cx + cw
    my = cy + ch

    {data, x, y} =
      chardata
      |> IO.chardata_to_string()
      |> String.to_charlist()
      |> Enum.reduce_while({data, x, y}, fn c, {data, x, y} ->
        case x < cx || y < cy || x >= mx || y >= my do
          true ->
            {:halt, {data, x, y}}

          false ->
            data = Map.put(data, {x, y}, {c, fg, bg})
            {:cont, {data, x + 1, y}}
        end
      end)

    %{canvas | data: data, x: x, y: y}
  end

  def diff(canvas1, canvas2) do
    %{
      data: data1,
      height: height,
      width: width,
      cursor: {cursor1, x1, y1},
      bgcolor: b1,
      fgcolor: f1
    } = canvas1

    %{
      data: data2,
      height: ^height,
      width: ^width
    } = canvas2

    {list, f, b, x, y} =
      for row <- 0..(height - 1), col <- 0..(width - 1), reduce: {[], f1, b1, x1, y1} do
        {list, f0, b0, x, y} ->
          cel1 = Map.get(data1, {col, row}, @cell)
          cel2 = Map.get(data2, {col, row}, @cell)

          case cel2 == cel1 do
            true ->
              {list, f0, b0, x, y}

            false ->
              {c2, f2, b2} = cel2

              list =
                case {x, y} == {col, row} do
                  true ->
                    list

                  false ->
                    [{:m, col, row} | list]
                end

              list =
                case b0 == b2 do
                  true -> list
                  false -> [{:b, b2} | list]
                end

              list =
                case f0 == f2 do
                  true -> list
                  false -> [{:f, f2} | list]
                end

              # to update styles write c2 even if same to c1
              list =
                case list do
                  [{:d, d} | tail] -> [{:d, [c2 | d]} | tail]
                  _ -> [{:d, [c2]} | list]
                end

              row = row + div(col + 1, width)
              col = rem(col + 1, width)
              {list, f2, b2, col, row}
          end
      end

    # restore canvas2 styles and cursor
    %{
      cursor: {cursor2, x2, y2},
      bgcolor: b2,
      fgcolor: f2
    } = canvas2

    list =
      case b == b2 do
        true -> list
        false -> [{:b, b2} | list]
      end

    list =
      case f == f2 do
        true -> list
        false -> [{:f, f2} | list]
      end

    list =
      case {x, y} == {x2, y2} do
        true -> list
        false -> [{:m, x2, y2} | list]
      end

    list =
      case cursor1 == cursor2 do
        true -> list
        false -> [{:c, cursor2} | list]
      end

    list
  end

  def encode(term, list) when is_list(list) do
    list = encode(term, [], list)
    :lists.reverse(list)
  end

  defp encode(_, list, []), do: list

  defp encode(term, list, [{:m, x, y} | tail]) do
    d = term.cursor(x, y)
    encode(term, [d | list], tail)
  end

  defp encode(term, list, [{:d, d} | tail]) do
    d = :lists.reverse(d)
    d = IO.chardata_to_string(d)
    encode(term, [d | list], tail)
  end

  defp encode(term, list, [{:s, s1, s2} | tail]) do
    b1 = Bitwise.band(s1, @bold)
    b2 = Bitwise.band(s2, @bold)
    d1 = Bitwise.band(s1, @dimmed)
    d2 = Bitwise.band(s2, @dimmed)
    i1 = Bitwise.band(s1, @inverse)
    i2 = Bitwise.band(s2, @inverse)

    list =
      case {b1, b2, d1, d2} do
        {@bold, 0, _, @dimmed} -> [term.reset(:normal), term.set(:dimmed) | list]
        {_, @bold, @dimmed, 0} -> [term.reset(:normal), term.set(:bold) | list]
        {@bold, 0, _, _} -> [term.reset(:normal) | list]
        {_, _, @dimmed, 0} -> [term.reset(:normal) | list]
        {0, @bold, _, _} -> [term.set(:bold) | list]
        {_, _, 0, @dimmed} -> [term.set(:dimmed) | list]
        _ -> list
      end

    list =
      case {i1, i2} do
        {0, @inverse} -> [term.set(:inverse) | list]
        {@inverse, 0} -> [term.reset(:inverse) | list]
        _ -> list
      end

    encode(term, list, tail)
  end

  defp encode(term, list, [{:b, b} | tail]) do
    d = term.color(:bgcolor, b)
    encode(term, [d | list], tail)
  end

  defp encode(term, list, [{:f, f} | tail]) do
    d = term.color(:fgcolor, f)
    encode(term, [d | list], tail)
  end

  defp encode(term, list, [{:c, c} | tail]) do
    d =
      case c do
        true -> term.show(:cursor)
        false -> term.hide(:cursor)
      end

    encode(term, [d | list], tail)
  end
end
