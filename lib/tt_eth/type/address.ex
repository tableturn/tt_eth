defmodule TTEth.Type.Address do
  @moduledoc """
  This module is an Ecto-compatible type that can represent Ethereum
  addresses.
  """
  use TTEth.Type, size: 20
  alias TTEth.BitHelper
  alias TTEth.Type.PublicKey

  @human_size @hex_size + 2

  @spec from_public_key(binary) :: {:ok, binary} | {:error, :invalid_input}
  def from_public_key(pubkey) do
    pubkey
    |> PublicKey.from_human()
    |> case do
      # The address is calculated by hashing the public key and keeping only
      # the first twenty bytes.
      {:ok, val} -> {:ok, val |> TTEth.keccak() |> BitHelper.mask_bitstring(20 * 8)}
      {:error, _} = ret -> ret
    end
  end

  @spec from_public_key!(binary) :: binary
  def from_public_key!(pub) do
    {:ok, addr} = pub |> from_public_key()
    addr
  end

  @spec encode_eth_address(binary) ::
          {:ok, <<_::16, _::_*8>>} | {:error, :unrecognized_address_format}
  def encode_eth_address(val),
    do: val |> EIP55.encode()

  @doc """
  Encodes address to EIP55 standard.

  ## Examples

    iex> encode_eth_address!("0xba2cc6707d46358ced394924ba587e4afedea576")
    "0xba2CC6707D46358ced394924BA587e4AfedeA576"
  """
  @spec encode_eth_address!(binary) :: <<_::16, _::_*8>>
  def encode_eth_address!(val) do
    {:ok, ret} = val |> encode_eth_address()
    ret
  end

  @doc """
  Checks validity of Ethereum address.

  ## Examples

    iex> eth_address_valid?("0xba2CC6707D46358ced394924BA587e4AfedeA576")
    true
    iex> eth_address_valid?("0xba2cc6707D46358ced394924BA587e4AfedeA576")
    false
  """
  @spec eth_address_valid?(binary) :: boolean
  def eth_address_valid?(val),
    do: val |> EIP55.valid?()

  @spec postprocess_human(<<_::336>>) :: <<_::16, _::_*8>>
  def postprocess_human(<<val::binary-size(@human_size)>>),
    do: val |> encode_eth_address!()
end
