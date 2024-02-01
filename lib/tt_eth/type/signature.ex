defmodule TTEth.Type.Signature do
  @moduledoc """
  This module is an Ecto-compatible type that can represent Ethereum signatures.
  """
  use TTEth.Type, size: 65
  alias TTEth.{BitHelper, Secp256k1}
  import TTEth, only: [keccak: 1]

  @base_v 27
  @valid_vs [@base_v, @base_v + 1]
  @ethereum_magic <<0x19, "Ethereum Signed Message:", ?\n>>

  @type recovery_id :: non_neg_integer()
  @type v :: 27 | 28
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
  @deprecated "Use Wallet.personal_sign/2 instead."
  @spec sign(message :: binary, private_key :: binary) ::
          {:ok, components} | {:error, :cannot_sign}
  def sign(message, private_key),
    do:
      message
      |> digest()
      |> Secp256k1.ecdsa_sign_compact(private_key)
      |> compact_to_components()

  @spec sign!(binary, binary) :: components
  def sign!(message, private_key) do
    {:ok, ret} = message |> sign(private_key)
    ret
  end

  @doc """
  Given a hash, signature components and optional chain id, returns the public key.
  """
  @spec recover(binary, components) :: {:ok, binary} | {:error, binary}
  def recover(digest, {v, r, s}) do
    sig =
      BitHelper.pad(:binary.encode_unsigned(r), 32) <>
        BitHelper.pad(:binary.encode_unsigned(s), 32)

    recovery_id = v - @base_v

    case Secp256k1.ecdsa_recover_compact(digest, sig, recovery_id) do
      {:ok, public_key} -> {:ok, public_key}
      {:error, reason} -> {:error, to_string(reason)}
    end
  end

  @spec recover!(digest, components) :: binary
  def recover!(digest, components) do
    {:ok, pub} = digest |> recover(components)
    pub
  end

  @doc """
  Takes the compact signature and returns the components with `v` added.
  """
  def compact_to_components({:ok, {<<r::size(256), s::size(256)>>, recovery_id}}),
    do: {:ok, {@base_v + recovery_id, r, s}}

  def compact_to_components({:error, _}),
    do: {:error, :cannot_sign}

  @spec components(binary) :: {:error, :invalid_signature} | {:ok, components}
  def components(signature) do
    signature
    |> from_human()
    |> case do
      {:ok, <<r::size(256), s::size(256), v::integer>>} -> {:ok, {v, r, s}}
      _ -> {:error, :invalid_signature}
    end
  end

  @spec components!(binary) :: components
  def components!(signature) do
    {:ok, {_v, _r, _s} = comps} = signature |> components()
    comps
  end

  @spec from_components!(components) :: binary()
  def from_components!({v, r, s} = _components) when v in @valid_vs,
    do: <<r::size(256), s::size(256), v::integer>>

  @spec to_human_from_components!(components) :: <<_::16, _::_*8>>
  def to_human_from_components!({_v, _r, _s} = components),
    do:
      components
      |> from_components!()
      |> to_human!()
end
