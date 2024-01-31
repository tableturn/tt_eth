defprotocol TTEth.Protocols.Wallet do
  @moduledoc """
  Protocol for wallet adapters.
  """

  @type t :: any()

  @doc """
  Returns a map of attributes used to construct a `TTEth.Wallet.t()`.
  """
  def wallet_attrs(t)

  @doc """
  Returns a signature.
  """
  def sign(t, hash_digest)
end
