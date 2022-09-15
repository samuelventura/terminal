defmodule FocusTest do
  use ExUnit.Case
  use Terminal.Const
  alias Terminal.Panel
  alias Terminal.Button
  alias Terminal.Label

  test "basic single level focus check" do
    root = Panel.init(root: true)

    children = [
      l0: {Label, Label.init()},
      c0: {Button, Button.init()},
      c1: {Button, Button.init()},
      l1: {Label, Label.init()}
    ]

    # focus next, single level, multiple children
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    assert panel.focus == :c1
    {panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    assert panel.focus == :c0

    # focus prev, single level, multiple children
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, {:key, @alt, "\t"})
    assert panel.focus == :c1
    {panel, nil} = Panel.handle(panel, {:key, @alt, "\t"})
    assert panel.focus == :c0

    children = [
      l0: {Label, Label.init()},
      c0: {Button, Button.init()},
      l1: {Label, Label.init()}
    ]

    # focus next, single level, single child
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    assert panel.focus == :c0

    # focus prev, single level, single child
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, {:key, @alt, "\t"})
    assert panel.focus == :c0
  end

  test "basic multi level focus check" do
    root = Panel.init(root: true)
    normal = Panel.init(root: false)

    children = [
      l0: {Label, Label.init()},
      c0: {Button, Button.init()},
      c1: {Button, Button.init()},
      l1: {Label, Label.init()}
    ]

    # focus next, multi level, multiple children
    panel = Panel.children(normal, children)
    panel = Panel.children(root, p0: {Panel, panel})
    assert elem(panel.children.p0, 1).focus == :c0
    {panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    assert elem(panel.children.p0, 1).focus == :c1
    {panel, nil} = Panel.handle(panel, {:key, :any, "\t"})
    assert elem(panel.children.p0, 1).focus == :c0

    # focus prev, multi level, multiple children
    panel = Panel.children(normal, children)
    panel = Panel.children(root, p0: {Panel, panel})
    assert elem(panel.children.p0, 1).focus == :c0
    {panel, nil} = Panel.handle(panel, {:key, @alt, "\t"})
    assert elem(panel.children.p0, 1).focus == :c1
    {panel, nil} = Panel.handle(panel, {:key, @alt, "\t"})
    assert elem(panel.children.p0, 1).focus == :c0
  end
end
