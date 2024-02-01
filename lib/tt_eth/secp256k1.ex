defmodule TTEth.Secp256k1 do
  @moduledoc """
  Wrapper around `ExSecp256k1` functions.
  """

  @valid_recovery_ids [0, 1]

  @type recovery_id :: 0 | 1
  @type compact_signature_return :: {:ok, {binary, recovery_id}} | {:error, atom}

  @doc """
  Delegates to `ExSecp256k1.recover_compact/3` with guards around the `recovery_id` value.
  """
  @spec ecdsa_recover_compact(binary(), binary(), non_neg_integer()) ::
          {:ok, binary()} | {:error, atom()}
  def ecdsa_recover_compact(hash, signature, recovery_id) when recovery_id in @valid_recovery_ids,
    do: ExSecp256k1.recover_compact(hash, signature, recovery_id)

  def ecdsa_recover_compact(_hash, _sig, _recovery_id),
    do: {:error, :invalid_recovery_id}

  @doc """
  Delegates to `ExSecp256k1.sign_compact/2`.
  """
  @spec ecdsa_sign_compact(binary(), binary()) :: compact_signature_return
  def ecdsa_sign_compact(hash, private_key),
    do: ExSecp256k1.sign_compact(hash, private_key)

  @doc """
  Delegates to `ExSecp256k1.create_public_key/1`.
  """
  @spec ec_pubkey_create(binary()) :: {:ok, binary()} | atom()
  def ec_pubkey_create(private_key),
    do: ExSecp256k1.create_public_key(private_key)
end
