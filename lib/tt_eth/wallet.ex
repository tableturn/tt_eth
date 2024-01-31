defmodule TTEth.Wallet do
  @moduledoc """
  Provides a handle struct - `TTEth.Wallet.t()` for encapsulating a wallet.
  """
  alias TTEth.Protocols.Wallet, as: WalletProtocol
  alias TTEth.Type.Signature, as: EthSignature

  @type t :: %__MODULE__{}

  defstruct [
    :adapter,
    :address,
    :public_key,
    :human_address,
    :human_public_key,
    :_adapter
  ]

  @doc """
  Looks up a wallet by name from config and creates it.

  See the adapter for specific configuration options.
  """
  @spec named(atom) :: t()
  def named(wallet_name) when is_atom(wallet_name),
    do:
      :tt_eth
      |> Application.fetch_env!(:wallets)
      |> Keyword.fetch!(wallet_name)
      |> build_with_adapter!(
        :tt_eth
        |> Application.fetch_env!(:wallet_adapter)
      )
      |> new()

  @doc """
  Creates a new `TTEth.Wallet.t` struct from a passed private key.
  """
  @spec from_private_key(binary) :: t()
  def from_private_key("" <> private_key),
    do:
      private_key
      |> build_with_adapter!()
      |> new()

  @doc """
  Creates a new wallet from an underlying wallet or a random one.
  """
  def new(wallet \\ TTEth.LocalWallet.generate()) when is_struct(wallet),
    do:
      __MODULE__
      |> struct!(
        wallet
        |> WalletProtocol.wallet_attrs()
      )

  @doc """
  Signs a digest using the passed wallet.
  """
  def sign(%__MODULE__{_adapter: wallet}, "" <> hash_digest),
    do:
      wallet
      |> WalletProtocol.sign(hash_digest)

  @doc """
  The same as `sign/2` but raises if the signing process is not successful.
  """
  def sign!(%__MODULE__{} = wallet, "" <> hash_digest) do
    {:ok, ret} = wallet |> sign(hash_digest)
    ret
  end

  @doc """
  Signs a plaintext message using the passed wallet.

  This is for personal signed data, not for transaction data.

  SEE: https://eips.ethereum.org/EIPS/eip-191
  SEE: https://ethereum.org/en/developers/docs/apis/json-rpc#eth_sign
  """
  def personal_sign(%__MODULE__{} = wallet, "" <> plaintext),
    do:
      wallet
      |> sign(plaintext |> EthSignature.digest())

  @doc """
  The same as `personal_sign/2` but raises if the signing process is not successful.
  """
  def personal_sign!(%__MODULE__{} = wallet, "" <> plaintext) do
    {:ok, comps} = wallet |> personal_sign(plaintext)
    comps
  end

  ## Private.

  defp build_with_adapter!(config, adapter \\ TTEth.LocalWallet)
       when (is_binary(config) or is_map(config)) and is_atom(adapter),
       do:
         config
         |> adapter.new()
end
