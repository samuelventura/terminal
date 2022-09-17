defmodule Terminal.Term do
  # minimal terminal API required for implemented controls
  # init:
  #   clear all
  #   extended mouse
  #   blinking underline cursor (linux tty unique option)
  @callback init() :: binary()
  @callback reset() :: binary()
  @callback query(:size) :: binary()
  @callback hide(:cursor) :: binary()
  @callback show(:cursor) :: binary()
  @callback color(:fore | :back, color :: integer()) :: binary()
  @callback cursor(column :: integer(), line :: integer()) :: binary()
  @callback append(buffer :: binary(), data :: binary()) :: {buffer :: binary(), events :: list()}
end
