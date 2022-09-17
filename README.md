# Terminal

Elixir Terminal UIs with Reactish API

![image](https://user-images.githubusercontent.com/4142710/189275618-cd1acb2e-8023-4892-85e1-0c850ecb4275.png)

Uses [teletype](https://github.com/samuelventura/teletype) for native TTY support

## Demo

```elixir
#from bash (no logs)
#Ctrl+c to exit
mix run scripts/demo.exs
#from iex (no logs)
#Ctrl+c to exit
Demo.run()
```

## Development

```elixir
# socat file:/dev/tty,raw,icanon=0,echo=0,min=0,escape=0x03 tcp-l:8880,reuseaddr
# socat STDIO fails with: Inappropriate ioctl for device
# no resize event is received with this method
# raw required to avoid translating \r to \n
# min=0 required to answer size query immediatelly
# fork useless because term won't answer size query on reconnection
# escape=0x03 required to honor escape sequences
# while true; do socat file:/dev/tty,raw,icanon=0,echo=0,escape=0x03,min=0 tcp-l:8880,reuseaddr; done
# to exit: ctrl-z, then jobs, then kill %1
#
# socat file:/dev/tty,nonblock,raw,icanon=0,echo=0,min=0,escape=0x03 tcp:127.0.0.1:8880
# client socat to test immediate transmission of typed keys on both ends
# escape=0x03 reqired to honor ctrl-c
#
# echo -en "\033[1mThis is bold text.\033[0m" | nc 127.0.0.1 8880
# to test server end honors escapes
System.put_env("ReactLogs", "true")
tty = {Socket, ip: "127.0.0.1", port: 8880}
{:ok, pid} = Demo.start_link(tty: tty)
Demo.stop(pid)
#direct from iex (no logs)
Demo.run()
```

 ## Design

- Only tested so far on VS Code integrated terminal and Linux legacy TTY.
- Very minimal escape sequences to ensure Linux TTY works.
- Control event handlers triggered only from keyboard events
- Use react state and control events instead of getters (on_change instead of get_value)
    - Corollary: Controls are not focusable if on_handler is nil
- Function components external children must be ignored
- No mixing on logic and markup allowed. State and logic to the top, markup to the bottom.
- Null effects may be executed multiple times in a single user event because of state changes propagation.
- The reason for use_effect (instead of direct execution from event handlers) is its cleanup mechanism.
- Effects and cleanups are executed post render in same render process.
- Mouse wheel may focus but not trigger constrol actions.
- Select and Radio items can be any datatype implementing String.Chars.
- Exceptions in timeout/interval handlers should kill the application.
- Cleanups should be idempotent.
- Enter should navigate to next control for all controls except buttons.
- Dialog buttons order should be accept then cancel to take advange of enter navigation.
- Escape should close dialogs from any current focused control (shortcut).

## Issues

- konsole is not consistently responding size queries as vscode term does

## Future

- [ ] Ctrl-c handler
- [ ] Resize handler
- [ ] XTerm support
- [ ] Konsole support
- [ ] MacOS terminal support
- [ ] Explicit screen redraw
- [ ] TextArea
- [ ] Drag and drop
- [ ] Selection
- [ ] Clipboard
- [ ] Input scrolling
- [x] Input validation
- [X] Mouse
- [X] Mouse wheel
- [X] Modals
- [X] Checkbox
- [X] Reversed tab
- [x] Commands
- [x] Subscriptions
- [X] Term behaviour
- [X] Zero index coordinates
- [X] Tab index testing
- [X] Tab navigation testing
- [X] Arror up/down navigation
- [X] List rendering
- [X] Nil rendering
- [X] Keyboard shortcuts
- [x] Modal accept/cancel
- [x] Conditional rendering
- [X] Use effect execution order
- [X] Use effect cleanups
- [X] Timer API
- [x] Test refocus
- [x] Test reverse nav
- [x] Test canvas && diffing
- [x] Test visible propagation
- [X] Kill app with ctrl+c

