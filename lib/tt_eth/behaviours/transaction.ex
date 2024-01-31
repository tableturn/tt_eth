defmodule TTEth.Behaviours.Transaction do
  @moduledoc """
  Defines a standard transaction behaviour.
  """

  @type to_address :: String.t()
  @type abi_data :: binary()
  @type nonce :: non_neg_integer()
  @type opts :: Keyword.t()

  @type transaction :: struct()
  @type wallet :: TTEth.Wallet.t()

  @callback new(to_address, abi_data, nonce, opts) :: transaction

  @callback build(transaction, wallet) :: binary()
end
