defmodule PanelTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Control
  alias Terminal.Panel
  alias Terminal.Button
  alias Terminal.Label

  test "basic panel check" do
    initial = Panel.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             enabled: true,
             findex: 0,
             root: false,
             index: [],
             children: %{},
             focus: nil
           }

    # getters/setters
    assert Panel.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Panel.visible(%{visible: :visible}) == :visible
    assert Panel.focusable(%{enabled: false}) == false
    assert Panel.focusable(%{visible: false}) == false
    assert Panel.focusable(%{findex: -1}) == false
    assert Panel.focusable(Panel.init(root: true)) == false
    assert Panel.focused(%{focused: false}) == false
    assert Panel.focused(%{focused: true}) == true
    assert Panel.focused(initial, true) == %{initial | focused: true}
    assert Panel.refocus(initial, :any) == initial
    assert Panel.findex(%{findex: 0}) == 0
    assert Panel.shortcut(:state) == nil
    assert Panel.children(initial) == []
    assert Panel.children(initial, []) == initial
    children = [{0, Panel.init()}, {1, Panel.init()}]
    assert Panel.children(Panel.children(initial, children)) == children
    assert Panel.modal(initial) == false

    # update
    assert Panel.update(initial, focused: :any) == initial
    assert Panel.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Panel.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Panel.update(initial, visible: false) == %{initial | visible: false}
    assert Panel.update(initial, enabled: false) == %{initial | enabled: false}
    assert Panel.update(initial, findex: -1) == %{initial | findex: -1}
    assert Panel.update(initial, root: :any) == initial
    assert Panel.update(initial, index: :any) == initial
    assert Panel.update(initial, children: :any) == initial
    assert Panel.update(initial, focus: :any) == initial

    # nops
    assert Panel.handle(initial, {:key, :any, :any}) == {initial, nil}
    assert Panel.handle(initial, {:mouse, :any, :any, :any, :any}) == {initial, nil}
  end

  test "panel handle check" do
    root = Panel.init(root: true)
    normal = Panel.init(root: false)

    panel = Panel.children(root, c0: Control.init(Label))
    {^panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    {^panel, nil} = Panel.handle(panel, {:key, :any, "\r"})
    {^panel, nil} = Panel.handle(panel, {:mouse, :any, 0, 0, @mouse_down})

    panel = Panel.children(root, c0: Control.init(Button))
    {^panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    {^panel, {:c0, {:click, nil}}} = Panel.handle(panel, {:key, :any, "\r"})

    panel = Panel.children(root, c0: Control.init(Button, size: {1, 1}))
    {^panel, {:c0, {:click, nil}}} = Panel.handle(panel, {:mouse, :any, 0, 0, @mouse_down})

    # mouse changes focus with reversed order match search
    panel =
      Panel.children(root,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Button, size: {1, 1})
      )

    assert panel.focus == :c0
    {panel, {:c1, {:click, nil}}} = Panel.handle(panel, {:mouse, :any, 0, 0, @mouse_down})
    assert panel.focus == :c1
    assert elem(panel.children.c0, 1).focused == false
    assert elem(panel.children.c1, 1).focused == true

    # mouse ignores non focusables
    panel =
      Panel.children(root,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Button, size: {1, 1}, visible: false)
      )

    {^panel, {:c0, {:click, nil}}} = Panel.handle(panel, {:mouse, :any, 0, 0, @mouse_down})

    # keys get to nested focused control
    panel = Panel.children(normal, c0: Control.init(Button))
    panel = Panel.children(root, p0: {Panel, panel})
    {^panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    {^panel, {:p0, {:c0, {:click, nil}}}} = Panel.handle(panel, {:key, :any, "\r"})

    # mouse gets to nested focused control
    panel = Panel.update(normal, size: {1, 1})
    panel = Panel.children(panel, c0: Control.init(Button, size: {1, 1}))
    panel = Panel.children(root, p0: {Panel, panel})
    {^panel, {:p0, {:c0, {:click, nil}}}} = Panel.handle(panel, {:mouse, :any, 0, 0, @mouse_down})

    # mouse focuses nested control
    panel = Panel.update(normal, size: {1, 1})

    panel =
      Panel.children(panel,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Button, size: {1, 1})
      )

    panel = Panel.children(root, p0: {Panel, panel})
    {panel, {:p0, {:c1, {:click, nil}}}} = Panel.handle(panel, {:mouse, :any, 0, 0, @mouse_down})
    panel = elem(panel.children.p0, 1)
    assert elem(panel.children.c0, 1).focused == false
    assert elem(panel.children.c1, 1).focused == true
  end

  test "panel refocus check" do
    root = Panel.init(root: true)
    normal = Panel.init(root: false)
    hidden = Panel.init(root: true, visible: false)
    disabled = Panel.init(root: true, enabled: false)
    findex = Panel.init(root: true, findex: -1)

    panel = Panel.children(root, c0: Control.init(Button))
    assert panel.focus == :c0
    panel = Panel.children(panel, c0: Control.init(Label))
    assert panel.focus == nil

    panel = Panel.children(root, c0: Control.init(Button))
    assert panel.focus == :c0
    panel = Panel.children(panel, c1: Control.init(Label))
    assert panel.focus == nil

    panel = Panel.children(root, c0: Control.init(Button))
    assert panel.focus == :c0
    panel = Panel.children(panel, c1: Control.init(Button))
    assert panel.focus == :c1

    panel = Panel.children(hidden, c0: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.update(panel, visible: true)
    assert panel.focus == :c0

    panel = Panel.children(disabled, c0: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.update(panel, enabled: true)
    assert panel.focus == :c0

    panel = Panel.children(findex, c0: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.update(panel, findex: 0)
    assert panel.focus == :c0

    panel = Panel.children(normal, c0: Control.init(Button), c1: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.focused(panel, true)
    panel = Panel.refocus(panel, :next)
    assert panel.focus == :c0

    panel = Panel.children(normal, c0: Control.init(Button), c1: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.focused(panel, true)
    panel = Panel.refocus(panel, :prev)
    assert panel.focus == :c1
  end
end
