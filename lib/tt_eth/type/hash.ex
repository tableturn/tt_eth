defmodule TTEth.Type.Hash do
  @moduledoc """
  This module is an Ecto-compatible type that can represent Ethereum
  hashes.
  """
  use TTEth.Type, size: 32
  import TTEth, only: [keccak: 1]

  @spec from_string!(binary) :: <<_::16, _::_*8>>
  def from_string!(input) when is_binary(input),
    do:
      input
      |> keccak()
      |> to_human!()
end
