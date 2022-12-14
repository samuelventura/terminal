defmodule Terminal.Panel do
  @behaviour Terminal.Control
  alias Terminal.Control
  alias Terminal.Check
  alias Terminal.Canvas

  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    origin = Map.get(opts, :origin, {0, 0})
    size = Map.get(opts, :size, {0, 0})
    visible = Map.get(opts, :visible, true)
    enabled = Map.get(opts, :enabled, true)
    findex = Map.get(opts, :findex, 0)
    root = Map.get(opts, :root, false)

    state = %{
      focused: root,
      origin: origin,
      size: size,
      visible: visible,
      enabled: enabled,
      findex: findex,
      root: root,
      index: [],
      children: %{},
      focus: nil
    }

    check(state)
  end

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(%{visible: visible}), do: visible
  def focused(%{focused: focused}), do: focused
  def focused(state, focused), do: Map.put(state, :focused, focused)
  def refocus(state, dir), do: recalculate(state, dir)
  def findex(%{findex: findex}), do: findex
  def shortcut(_), do: nil
  def modal(%{root: root}), do: root

  # ignore modals
  def focusable(%{root: true}), do: false
  def focusable(%{enabled: false}), do: false
  def focusable(%{visible: false}), do: false
  def focusable(%{findex: findex}) when findex < 0, do: false

  def focusable(%{children: children, index: index}) do
    Enum.find_value(index, false, fn id ->
      mote = Map.get(children, id)
      mote_focusable(mote)
    end)
  end

  def children(%{index: index, children: children}) do
    for id <- index, reduce: [] do
      list -> [{id, children[id]} | list]
    end
  end

  def children(state, children) do
    {index, children} =
      for {id, child} <- children, reduce: {[], %{}} do
        {index, map} ->
          if id == nil, do: raise("Invalid child id: #{id}")
          if Map.has_key?(map, id), do: raise("Duplicated child id: #{id}")
          {[id | index], Map.put(map, id, child)}
      end

    state = Map.put(state, :children, children)
    state = Map.put(state, :index, index)
    recalculate(state, :next)
  end

  def update(state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:root, :children, :focus, :index, :focused])
    state = Control.merge(state, props)
    state = recalculate(state, :next)
    check(state)
  end

  def handle(%{origin: {x, y}} = state, {:modal, [], {:mouse, s, mx, my, a}}) do
    handle(state, {:mouse, s, mx - x, my - y, a})
  end

  def handle(state, {:modal, [], event}), do: handle(state, event)

  def handle(state, {:modal, [key | tail], event}) do
    mote = state.children[key]
    {mote, event} = mote_handle(mote, {:modal, tail, event})
    state = put_child(state, key, mote)
    {state, event}
  end

  def handle(%{focus: nil} = state, {:key, _, _}), do: {state, nil}

  def handle(%{focus: focus} = state, {:key, _, _} = event) do
    mote = get_child(state, focus)
    {mote, event} = mote_handle(mote, event)
    child_event(state, mote, event)
  end

  # controls get focused before receiving a mouse event
  # unless the root panel has no focusable children at all
  def handle(%{focus: nil} = state, {:mouse, _, _, _, _}), do: {state, nil}

  def handle(%{focus: focus, index: index, children: children} = state, {:mouse, s, mx, my, a}) do
    Enum.find_value(index, {state, nil}, fn id ->
      mote = Map.get(children, id)
      focusable = mote_focusable(mote)
      bounds = mote_bounds(mote)
      client = toclient(bounds, mx, my)

      case {focusable, client, focus} do
        {false, _, _} ->
          false

        {_, false, _} ->
          false

        {_, {dx, dy}, ^id} ->
          event = {:mouse, s, dx, dy, a}
          {mote, event} = mote_handle(mote, event)
          child_event(state, mote, event)

        {_, {dx, dy}, _} ->
          state = unfocus(state)
          state = %{state | focus: id}
          mote = mote_focused(mote, true, :next)
          event = {:mouse, s, dx, dy, a}
          {mote, event} = mote_handle(mote, event)
          child_event(state, mote, event)
      end
    end)
  end

  # shortcuts are broadcasted without focus pre-assigment
  def handle(%{index: index, children: children} = state, {:shortcut, _} = event) do
    Enum.each(index, fn id ->
      mote = Map.get(children, id)

      if mote_focusable(mote) do
        mote_handle(mote, event)
      end
    end)

    {state, nil}
  end

  def handle(state, _event), do: {state, nil}

  def render(%{index: index, children: children}, canvas) do
    for id <- Enum.reverse(index), reduce: canvas do
      canvas ->
        mote = Map.get(children, id)
        mote_render(mote, canvas)
    end
  end

  # assumes no child other than the pointed
  # by the focus key will be ever focused
  # no attempt is made to unfocus every children
  defp recalculate(state, dir) do
    %{
      visible: visible,
      enabled: enabled,
      focused: focused,
      findex: findex,
      focus: focus
    } = state

    expected = visible && enabled && focused && findex >= 0

    # try to recover the current focus key
    # returning nil if not recoverable
    {state, focus} =
      case focus do
        nil ->
          {state, nil}

        _ ->
          case get_child(state, focus) do
            nil ->
              state = Map.put(state, :focus, nil)
              {state, nil}

            mote ->
              focused = mote_focused(mote)
              focusable = mote_focusable(mote)

              case {focusable && expected, focused} do
                {false, false} ->
                  state = Map.put(state, :focus, nil)
                  {state, nil}

                {false, true} ->
                  mote = mote_focused(mote, false, dir)
                  state = put_child(state, focus, mote)
                  state = Map.put(state, :focus, nil)
                  {state, nil}

                {true, false} ->
                  mote = mote_focused(mote, true, dir)
                  state = put_child(state, focus, mote)
                  {state, focus}

                {true, true} ->
                  {state, focus}
              end
          end
      end

    # try to initialize the focus key if nil
    case {expected, focus} do
      {true, nil} ->
        case focus_list(state, dir) do
          [] ->
            state

          [focus | _] ->
            mote = get_child(state, focus)
            mote = mote_focused(mote, true, dir)
            state = put_child(state, focus, mote)
            Map.put(state, :focus, focus)
        end

      _ ->
        state
    end
  end

  defp child_event(%{focus: focus, root: root} = state, mote, event) do
    case event do
      {:focus, dir} ->
        {first, next} = focus_next(state, focus, dir)

        # critical to remove and reapply focused even
        # and specially when next equals current focus
        next =
          case {root, first, next} do
            {true, ^focus, nil} -> focus
            {true, _, nil} -> first
            _ -> next
          end

        case next do
          nil ->
            {put_child(state, focus, mote), {:focus, dir}}

          _ ->
            mote = mote_focused(mote, false, dir)
            state = put_child(state, focus, mote)
            mote = get_child(state, next)
            mote = mote_focused(mote, true, dir)
            state = put_child(state, next, mote)
            {Map.put(state, :focus, next), nil}
        end

      nil ->
        {put_child(state, focus, mote), nil}

      _ ->
        {put_child(state, focus, mote), {focus, event}}
    end
  end

  defp focus_next(state, focus, dir) do
    index = focus_list(state, dir)

    case index do
      [] ->
        {nil, nil}

      [first | _] ->
        {next, _} =
          Enum.reduce_while(index, {nil, nil}, fn id, {_, prev} ->
            case {focus == id, focus == prev} do
              {true, _} -> {:cont, {nil, id}}
              {_, true} -> {:halt, {id, nil}}
              _ -> {:cont, {nil, nil}}
            end
          end)

        {first, next}
    end
  end

  defp focus_list(state, :next) do
    index = focus_list(state, :prev)
    Enum.reverse(index)
  end

  defp focus_list(state, :prev) do
    %{index: index} = state
    index = Enum.filter(index, &child_focusable(state, &1))
    Enum.sort(index, &focus_compare(state, &1, &2))
  end

  defp focus_compare(state, id1, id2) do
    fi1 = child_findex(state, id1)
    fi2 = child_findex(state, id2)
    fi1 >= fi2
  end

  defp unfocus(%{focus: focus} = state) do
    mote = get_child(state, focus)
    mote = mote_focused(mote, false, :next)
    put_child(state, focus, mote)
  end

  defp toclient({x, y, w, h}, mx, my) do
    case mx >= x && mx < x + w && my >= y && my < y + h do
      false -> false
      true -> {mx - x, my - y}
    end
  end

  defp get_child(state, id), do: get_in(state, [:children, id])
  defp put_child(state, id, child), do: put_in(state, [:children, id], child)
  defp child_focusable(state, id), do: mote_focusable(get_child(state, id))
  defp child_findex(state, id), do: mote_findex(get_child(state, id))
  defp mote_bounds({module, state}), do: module.bounds(state)
  defp mote_findex({module, state}), do: module.findex(state)
  defp mote_focusable({module, state}), do: module.focusable(state)
  defp mote_focused({module, state}), do: module.focused(state)

  defp mote_render({module, state}, canvas) do
    visible = module.visible(state)
    modal = module.modal(state)

    case {visible, modal} do
      {false, _} ->
        canvas

      {_, true} ->
        canvas

      _ ->
        bounds = module.bounds(state)
        canvas = Canvas.push(canvas, bounds)
        canvas = module.render(state, canvas)
        Canvas.pop(canvas)
    end
  end

  defp mote_focused({module, state}, focused, dir) do
    state = module.focused(state, focused)
    state = module.refocus(state, dir)
    {module, state}
  end

  defp mote_handle({module, state}, event) do
    {state, event} = module.handle(state, event)
    {{module, state}, event}
  end

  defp check(state) do
    Check.assert_boolean(:focused, state.focused)
    Check.assert_point_2d(:origin, state.origin)
    Check.assert_point_2d(:size, state.size)
    Check.assert_boolean(:visible, state.visible)
    Check.assert_boolean(:enabled, state.enabled)
    Check.assert_gte(:findex, state.findex, -1)
    Check.assert_boolean(:root, state.root)
    Check.assert_map(:children, state.children)
    Check.assert_list(:index, state.index)
    state
  end
end
