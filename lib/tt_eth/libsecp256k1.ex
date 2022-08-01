defmodule TTEth.Libsecp256k1 do
  @moduledoc """
  Wrapper around Libsecp256k1 functions.
  """

  def ecdsa_recover_compact(hash, sig, :uncompressed = _type, v),
    do: ExSecp256k1.recover_compact(hash, sig, v)

  def ecdsa_sign_compact(hash, private_key, _type, _bin) do
    case ExSecp256k1.sign_compact(hash, private_key) do
      {:ok, {a, b}} -> {:ok, a, b}
      otherwise -> otherwise
    end
  end

  def ec_pubkey_create(priv, :uncompressed),
    do: ExSecp256k1.create_public_key(priv)
end
