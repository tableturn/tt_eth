defmodule TTEth.Type.PublicKey do
  @moduledoc "This module is an Ecto-compatible type that can represent Ethereum public keys."
  use TTEth.Type, size: 64
  alias TTEth.Libsecp256k1

  @spec from_private_key(binary) :: {:ok, binary} | {:error, String.t()}
  def from_private_key(priv) when is_binary(priv),
    do: Libsecp256k1.ec_pubkey_create(priv, :uncompressed)

  @spec from_private_key!(binary) :: binary
  def from_private_key!(priv) do
    {:ok, pub} = from_private_key(priv)
    pub
  end
end
