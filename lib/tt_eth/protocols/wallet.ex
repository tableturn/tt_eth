defprotocol TTEth.Protocols.Wallet do
  @moduledoc """
  Protocol for wallet adapters.
  """

  @typedoc """
  All the types that implement this protocol.
  """
  @type t :: any()

  @doc """
  Returns a map of attributes used to construct a `TTEth.Wallet.t()`.
  """
  def wallet_attrs(t)

  @doc """
  Returns a signature.
  """
  @spec sign(t, binary()) :: binary()
  def sign(t, digest)
end
