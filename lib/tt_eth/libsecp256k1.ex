defmodule TTEth.Libsecp256k1 do
  @moduledoc """
  Wrapper around `ExSecp256k1` functions.
  """

  @doc """
  Delegates to `ExSecp256k1.recover_compact/3`.
  """
  @spec ecdsa_recover_compact(binary(), binary(), atom(), non_neg_integer()) ::
          {:ok, binary()} | {:error, atom()}
  def ecdsa_recover_compact(hash, sig, :uncompressed = _type, v),
    do: ExSecp256k1.recover_compact(hash, sig, v)

  @doc """
  Delegates to `ExSecp256k1.sign_compact/2`.
  """
  @spec ecdsa_sign_compact(binary(), binary(), atom(), binary()) ::
          {:ok, {binary(), binary()}} | {:error, atom()}
  def ecdsa_sign_compact(hash, private_key, _type, _bin) do
    case ExSecp256k1.sign_compact(hash, private_key) do
      {:ok, {a, b}} -> {:ok, a, b}
      otherwise -> otherwise
    end
  end

  @doc """
  Delegates to `ExSecp256k1.create_public_key/1`.
  """
  @spec ec_pubkey_create(binary(), :uncompressed) :: {:ok, binary()} | atom()
  def ec_pubkey_create(priv, :uncompressed),
    do: ExSecp256k1.create_public_key(priv)
end
