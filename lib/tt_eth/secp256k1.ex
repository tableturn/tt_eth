defmodule TTEth.Secp256k1 do
  @moduledoc """
  Wrapper around `ExSecp256k1` functions.
  """

  @doc """
  Delegates to `ExSecp256k1.recover_compact/3`.
  """
  @spec ecdsa_recover_compact(binary(), binary(), non_neg_integer()) ::
          {:ok, binary()} | {:error, atom()}
  def ecdsa_recover_compact(hash, sig, v),
    do: ExSecp256k1.recover_compact(hash, sig, v)

  @doc """
  Delegates to `ExSecp256k1.sign_compact/2`.
  """
  @spec ecdsa_sign_compact(binary(), binary()) ::
          {:ok, {binary(), binary()}} | {:error, atom()}
  def ecdsa_sign_compact(hash, private_key),
    do: ExSecp256k1.sign_compact(hash, private_key)

  @doc """
  Delegates to `ExSecp256k1.create_public_key/1`.
  """
  @spec ec_pubkey_create(binary()) :: {:ok, binary()} | atom()
  def ec_pubkey_create(priv),
    do: ExSecp256k1.create_public_key(priv)
end
