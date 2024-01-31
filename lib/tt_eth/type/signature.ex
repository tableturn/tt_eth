defmodule TTEth.Type.Signature do
  @moduledoc """
  This module is an Ecto-compatible type that can represent Ethereum signatures.
  """
  use TTEth.Type, size: 65
  alias TTEth.{BitHelper, Secp256k1}
  import TTEth, only: [keccak: 1]

  @secp256k1n 115_792_089_237_316_195_423_570_985_008_687_907_852_837_564_279_074_904_382_605_163_141_518_161_494_337
  @secp256k1n_2 round(Float.floor(@secp256k1n / 2))
  @base_recovery_id 27
  @base_recovery_id_eip_155 35
  @ethereum_magic <<0x19, "Ethereum Signed Message:", ?\n>>

  @type recovery_id :: non_neg_integer()
  @type v :: byte
  @type r :: non_neg_integer()
  @type s :: non_neg_integer()
  @type components :: {v, r, s}
  @type chain_id :: number
  @type digest :: binary

  @doc """
  Hashes and decorates the passed plaintext message using `decorate_message/1`.
  """
  @spec digest(binary) :: binary
  def digest(msg),
    do:
      msg
      |> decorate_message()
      |> keccak()

  @doc """
  Decorates the passed message with the Ethereum magic as specified in EIP-191.

  SEE: https://eips.ethereum.org/EIPS/eip-191

  This is version `0x45`.
  """
  @spec decorate_message(binary) :: String.t()
  def decorate_message(msg),
    do: <<@ethereum_magic, "#{byte_size(msg)}"::binary, msg::binary>>

  @doc """
  This is for personal signed data, not for transaction data.

  `TTEth.Wallet.personal_sign/2` should be used instead.

  SEE: https://eips.ethereum.org/EIPS/eip-191
  SEE: https://ethereum.org/en/developers/docs/apis/json-rpc#eth_sign
  """
  @deprecated "See Wallet.t() for using a wallet adapter instead."
  @spec sign(message :: binary, private_key :: binary, chain_id | nil) ::
          {:ok, components} | {:error, :cannot_sign}
  def sign(message, private_key, chain_id \\ nil),
    do:
      message
      |> digest()
      |> Secp256k1.ecdsa_sign_compact(private_key)
      |> compact_to_components(chain_id)

  @spec sign!(binary, binary, chain_id | nil) :: components
  def sign!(message, private_key, chain_id \\ nil) do
    {:ok, ret} = message |> sign(private_key, chain_id)
    ret
  end

  @doc """
  Given a hash, signature components and optional chain id, returns the public key.

  Note that this is EIP-155 aware, so if you pass a chain id, it will use it to
  recover the `recovery_id` from `v`.

  The `chain_id` should not be passed if this is for a EIP-191 message.
  """
  @spec recover(binary, components, chain_id | nil) :: {:ok, binary} | {:error, binary}
  def recover(hash, {v, r, s}, chain_id \\ nil) do
    sig =
      BitHelper.pad(:binary.encode_unsigned(r), 32) <>
        BitHelper.pad(:binary.encode_unsigned(s), 32)

    recovery_id = v_to_recovery_id(v, chain_id)

    case Secp256k1.ecdsa_recover_compact(hash, sig, recovery_id) do
      {:ok, public_key} -> {:ok, public_key}
      {:error, reason} -> {:error, to_string(reason)}
    end
  end

  @spec recover!(digest, components, chain_id | nil) :: binary
  def recover!(digest, components, chain_id \\ nil) do
    {:ok, pub} = digest |> recover(components, chain_id)
    pub
  end

  @spec is_signature_valid?(components, chain_id, keyword) :: boolean
  def is_signature_valid?({v, r, s}, _chain_id, max_s: :secp256k1n),
    do:
      (v == 27 || v == 28) and
        r > 0 and r < @secp256k1n and
        s > 0 and s < @secp256k1n

  def is_signature_valid?({r, s, v}, chain_id, max_s: :secp256k1n_2),
    do:
      (v == 27 || v == 28 || v == chain_id * 2 + 35 || v == chain_id * 2 + 36) and
        r > 0 and r < @secp256k1n and
        s > 0 and s <= @secp256k1n_2

  def compact_to_components(compact_signature, chain_id \\ nil) do
    compact_signature
    |> case do
      {:ok, {<<r::size(256), s::size(256)>>, v}} ->
        {:ok, {v_from_recovery_id(v, chain_id), r, s}}

      {:error, _} ->
        {:error, :cannot_sign}
    end
  end

  def compact_to_components!(compact_signature, chain_id \\ nil) do
    {:ok, {_v, _r, _s} = comps} = compact_signature |> compact_to_components(chain_id)
    comps
  end

  @spec components(binary) :: {:error, :invalid_signature} | {:ok, components}
  def components(sig) do
    sig
    |> from_human()
    |> case do
      {:ok, <<r::size(256), s::size(256), v::integer>>} -> {:ok, {v, r, s}}
      _ -> {:error, :invalid_signature}
    end
  end

  @spec components!(binary) :: components
  def components!(sig) do
    {:ok, {_v, _r, _s} = comps} = sig |> components()
    comps
  end

  def from_components!({v, r, s}),
    do: <<r::size(256), s::size(256), v::integer>>

  @spec to_human_from_components!(components) :: <<_::16, _::_*8>>
  def to_human_from_components!({_v, _r, _s} = components),
    do:
      components
      |> from_components!()
      |> to_human!()

  # Private.

  defp uses_chain_id?(v),
    do: v >= @base_recovery_id_eip_155

  @spec v_from_recovery_id(recovery_id, chain_id) :: non_neg_integer()
  defp v_from_recovery_id(recovery_id, chain_id) do
    if is_nil(chain_id) do
      @base_recovery_id + recovery_id
    else
      chain_id * 2 + @base_recovery_id_eip_155 + recovery_id
    end
  end

  @spec v_to_recovery_id(non_neg_integer(), chain_id) :: non_neg_integer()
  defp v_to_recovery_id(v, chain_id) do
    if not is_nil(chain_id) and uses_chain_id?(v) do
      v - chain_id * 2 - @base_recovery_id_eip_155
    else
      v - @base_recovery_id
    end
  end
end
