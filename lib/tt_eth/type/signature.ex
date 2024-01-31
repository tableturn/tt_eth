defmodule TTEth.Type.Signature do
  @moduledoc """
  This module is an Ecto-compatible type that can represent Ethereum signatures.
  """
  use TTEth.Type, size: 65
  alias TTEth.{BitHelper, Secp256k1}
  import TTEth, only: [keccak: 1]

  @secp256k1n 115_792_089_237_316_195_423_570_985_008_687_907_852_837_564_279_074_904_382_605_163_141_518_161_494_337
  @secp256k1n_2 round(Float.floor(@secp256k1n / 2))
  @base_v 27
  @ethereum_magic <<0x19, "Ethereum Signed Message:", ?\n>>

  @type recovery_id :: non_neg_integer()
  @type v :: non_neg_integer()
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
  This is for a signed message, not for transaction data.

  `TTEth.Wallet.personal_sign/2` should be used instead.

  SEE: https://eips.ethereum.org/EIPS/eip-191
  SEE: https://ethereum.org/en/developers/docs/apis/json-rpc#eth_sign
  """
  @deprecated "Use Wallet.personal_sign/2 to sign using a wallet adapter instead."
  @spec sign(message :: binary, private_key :: binary) ::
          {:ok, components} | {:error, :cannot_sign}
  def sign(message, private_key) do
    message
    |> digest()
    |> Secp256k1.ecdsa_sign_compact(private_key)
    |> case do
      {:ok, {<<r::size(256), s::size(256)>>, recovery_id}} ->
        {:ok, {@base_v + recovery_id, r, s}}

      {:error, _} ->
        {:error, :cannot_sign}
    end
  end

  @spec sign!(binary, binary) :: components
  def sign!(message, private_key) do
    {:ok, ret} = message |> sign(private_key)
    ret
  end

  @doc """
  Given a hash, signature components and optional chain id, returns the public key.

  Note: The `chain_id` has been dropped and should not be passed if this is for a EIP-191 message.
  not for EIP-155 transactions.
  """
  @spec recover(binary, components) :: {:ok, binary} | {:error, binary}
  def recover(hash, {v, r, s}) do
    sig =
      BitHelper.pad(:binary.encode_unsigned(r), 32) <>
        BitHelper.pad(:binary.encode_unsigned(s), 32)

    recovery_id = v - @base_v

    case Secp256k1.ecdsa_recover_compact(hash, sig, recovery_id) do
      {:ok, public_key} -> {:ok, public_key}
      {:error, reason} -> {:error, to_string(reason)}
    end
  end

  @spec recover!(digest, components) :: binary
  def recover!(digest, components) do
    {:ok, pub} = digest |> recover(components)
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

  def to_human_from_components!({<<r::size(256), s::size(256)>>, v} = _components)
      when is_integer(v),
      do:
        {v, r, s}
        |> to_human_from_components!()
end
