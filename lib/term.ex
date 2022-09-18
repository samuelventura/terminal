defmodule Terminal.Term do
  # minimal terminal API required for implemented controls
  # init:
  #   clear all
  #   extended mouse
  #   blinking underline cursor (linux tty unique option)
  @callback init() :: iodata()
  @callback reset() :: iodata()
  @callback query(:size) :: iodata()
  @callback hide(:cursor) :: iodata()
  @callback show(:cursor) :: iodata()
  @callback color(:fore | :back, color :: integer()) :: iodata()
  @callback cursor(column :: integer(), line :: integer()) :: iodata()
  @callback append(buffer :: binary(), data :: binary()) :: {buffer :: binary(), events :: list()}
end
