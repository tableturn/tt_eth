defmodule TTEth.LocalWallet do
  @moduledoc """
  A local wallet, derived from a private key.

  ## Config

  Expects the config to look like so:

      config TTEth,
        wallet_adapter: TTEth.LocalWallet,
        wallets: [
          primary: "0x0aF6...0000",
        ]
  """
  alias TTEth.Type.{Address, PublicKey, PrivateKey}
  alias TTEth.Secp256k1
  alias TTEth.Behaviours.Wallet, as: WalletBehaviour

  @type t :: %__MODULE__{}

  @behaviour WalletBehaviour

  defstruct [
    :private_key,
    :human_private_key
  ]

  defimpl TTEth.Protocols.Wallet, for: __MODULE__ do
    def wallet_attrs(%@for{} = wallet) do
      pub =
        wallet.private_key
        |> PublicKey.from_private_key!()
        |> PublicKey.from_human!()

      address = pub |> Address.from_public_key!()

      [
        address: address,
        public_key: pub,
        human_address: address |> Address.to_human!(),
        human_public_key: pub |> PublicKey.to_human!(),
        _adapter: wallet
      ]
    end

    def sign(%@for{} = wallet, "" <> digest),
      do:
        digest
        |> Secp256k1.ecdsa_sign_compact(wallet.private_key)
  end

  @impl WalletBehaviour

  def new(%{private_key: private_key} = _config),
    do:
      __MODULE__
      |> struct!(%{
        private_key: private_key |> PrivateKey.from_human!(),
        human_private_key: private_key
      })

  def new("" <> private_key = _config),
    do:
      %{private_key: private_key}
      |> new()

  ## Helpers.

  @doc """
  Generates a new `TTEth.LocalWallet.t` with a random private key.
  """
  def generate() do
    {_pub, priv} = TTEth.new_keypair()

    %{private_key: priv}
    |> new()
  end
end
