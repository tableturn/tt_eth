defmodule TTEth.Wallet do
  @moduledoc false
  alias TTEth.Type.{Address, PublicKey, PrivateKey}

  @type t :: %__MODULE__{}
  defstruct [
    :address,
    :public_key,
    :private_key,
    :human_address,
    :human_public_key,
    :human_private_key
  ]

  @me __MODULE__

  @spec named(atom) :: t()
  def named(name),
    do:
      :tt_eth
      |> Application.fetch_env!(:wallets)
      |> Keyword.fetch!(name)
      |> from_private_key()

  @doc "Constructs a wallet from a private key."
  @spec from_private_key(binary) :: t()
  def from_private_key(priv) when is_binary(priv) do
    raw_priv = priv |> PrivateKey.from_human!() |> PublicKey.from_private_key!()
    {raw_priv, priv} |> new()
  end

  @doc "Constructs a new wallet from a keypair or a random one."
  @spec new({binary, binary}) :: t()
  def new({pub, priv} \\ TTEth.new_keypair()) when is_binary(pub) and is_binary(priv) do
    address = pub |> Address.from_public_key!()

    struct!(%@me{}, %{
      address: address |> Address.from_human!(),
      public_key: pub |> PublicKey.from_human!(),
      private_key: priv |> PrivateKey.from_human!(),
      human_address: address |> Address.to_human!(),
      human_public_key: pub |> PublicKey.to_human!(),
      human_private_key: priv |> PrivateKey.to_human!()
    })
  end
end
