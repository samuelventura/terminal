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
      fore: @white,
      back: @black,
      clip: {0, 0, width, height},
      clips: []
    }
  end

  def modal(canvas) do
    %{width: width, height: height} = canvas
    %{data: data} = canvas
    canvas = new(width, height)
    data = for {key, {d, _, _}} <- data, do: {key, {d, @bblack, @black}}
    data = Enum.into(data, %{})
    %{canvas | data: data}
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
    %{canvas | fore: @white, back: @black}
  end

  def move(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | x: cx + x, y: cy + y}
  end

  def cursor(%{clip: {cx, cy, _, _}} = canvas, x, y) do
    %{canvas | cursor: {true, cx + x, cy + y}}
  end

  def color(canvas, :fore, color) do
    %{canvas | fore: color}
  end

  def color(canvas, :back, color) do
    %{canvas | back: color}
  end

  # writes a single line clipping excess to avoid terminal wrapping
  def write(canvas, chardata) do
    %{
      x: x,
      y: y,
      data: data,
      fore: fg,
      back: bg,
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
      back: b1,
      fore: f1
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
      back: b2,
      fore: f2
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

  defp encode(term, list, [{:b, b} | tail]) do
    d = term.color(:back, b)
    encode(term, [d | list], tail)
  end

  defp encode(term, list, [{:f, f} | tail]) do
    d = term.color(:fore, f)
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
