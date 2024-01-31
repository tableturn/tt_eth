defmodule TTEth do
  @moduledoc """
  Top level functions and helpers.

  ## Configuration

  Configure TTEth using:

  ```elixir
  config tt_eth,
    chain_client: YourChainClientModule,
    wallets: [
      primary: "[private key]",
      secondary: "[private key]"
    ]
  ```

  """

  alias TTEth.{Wallet, Behaviours}
  import Application, only: [get_env: 3]
  import Integer, only: [is_even: 1]
  require Logger

  @doc """
  This function generates a new keypair until it appears to be valid. This workaround
  was implemented because the native library in charge of the keypair generation randomly
  fails and returns invalid keypairs.
  """
  @spec new_keypair(any) :: {binary, binary}
  def new_keypair(kp \\ nil)

  def new_keypair({pub, priv} = kp)
      when byte_size(pub) == 65 and byte_size(priv) == 32,
      do: kp

  def new_keypair(_),
    do: :crypto.generate_key(:ecdh, :secp256k1) |> new_keypair()

  @doc """
  Computes the SHA3-256 of the given data.

  Delegates to `ExKeccak.hash_256/1`.
  """
  @spec keccak(binary) :: binary
  def keccak(data) when is_binary(data),
    do: data |> ExKeccak.hash_256()

  @doc """
  Reflects the current chain id. Configured in `config/...`:

  ```
  config :tt_eth,
    chain_id: "1234567"
  ```
  """
  @spec chain_id() :: binary()
  def chain_id(),
    do: :tt_eth |> Application.fetch_env!(:chain_id) |> to_string()

  ## Wrappers for the underlying chain client.

  @doc "Signs and sends a transaction to the chain using the configured `TTEth.ChainClient`."
  def send_raw_transaction(%Wallet{} = wallet, to, method, args, opts \\ []),
    do:
      wallet
      |> build_tx_data(to, method, args, opts)
      |> chain_client().eth_send_raw_transaction(opts)

  @doc "Builds the tx data using the configured `TTEth.ChainClient`."
  def build_tx_data(%Wallet{} = wallet, to, method, args, opts \\ []) do
    with {_, {:ok, "0x" <> raw_nonce}} <-
           {:raw_nonce,
            wallet.human_address |> chain_client().eth_get_transaction_count("pending")},
         {_, {nonce, ""}} <-
           {:parse_nonce, raw_nonce |> Integer.parse(16)},
         {_, abi_data} <-
           {:abi_encode, method |> ABI.encode(args)} do
      to
      |> chain_client().build_tx_data(abi_data, wallet, nonce, opts)
    end
  end

  @doc """
  Delegate to `TTEth.ChainClient.eth_get_max_priority_fee_per_gas/0`.
  """
  def get_max_priority_fee_per_gas(),
    do: chain_client().eth_get_max_priority_fee_per_gas()

  @doc """
  Delegate to `TTEth.ChainClient.eth_estimate_gas/1+2`.
  """
  def estimate_gas(%{} = tx_obj, opts \\ []),
    do: tx_obj |> chain_client().eth_estimate_gas(opts)

  @doc """
  Delegate to `TTEth.ChainClient.eth_get_block/1+2`

  `tx_detail` flag set to false to mirror RPC call:
  SEE: https://www.quicknode.com/docs/ethereum/eth_getBlockByNumber.
  """
  def get_block_by_number("" <> block, tx_detail \\ false),
    do: block |> chain_client().eth_get_block_by_number(tx_detail)

  ## Dependencies / Injection.

  @doc """
  Reflects the current chain client module. Can be used when testing.

  Configured in `config/...`:

  ```
  config :tt_eth,
    chain_client: YourModule.ChainClient
  ```
  """
  @spec chain_client() :: module
  def chain_client(),
    do: :tt_eth |> get_env(:chain_client, TTEth.ChainClient)

  @spec transaction_module() :: module
  def transaction_module(),
    do: :tt_eth |> get_env(:transaction_module, TTEth.Transactions.EIP1559Transaction)

  ## Mocks related stuff.

  @doc false
  def all_mocks(),
    do: [
      %{
        name: :chain_client,
        mock: ChainClientMock,
        impl: TTEth.ChainClientMockImpl,
        behaviour: Behaviours.ChainClient
      }
    ]

  @doc """
  Decodes a `0x` prefixed hex encoded value to an unsigned int.

  ## Examples

      iex> hex_to_int!("0xa")
      10
      iex> hex_to_int!("0x0a")
      10

  """
  @spec hex_to_int!(<<_::16, _::_*8>>) :: non_neg_integer()
  def hex_to_int!(value),
    do:
      value
      |> hex_to_binary!()
      |> :binary.decode_unsigned()

  @doc """
  Decodes a `0x` prefixed hex encoded value to a binary.

  Handles padding as required.

  ## Examples

      iex> hex_to_binary!("0x10a")
      <<1, 10>>
      iex> hex_to_binary!("0x010a")
      <<1, 10>>

  """
  @spec hex_to_binary!(<<_::16, _::_*8>>) :: binary
  def hex_to_binary!("0x" <> rest),
    do:
      rest
      |> maybe_pad_leading(String.length(rest))
      |> Base.decode16!(case: :mixed)

  @doc """
  Encodes a binary to a `0x` prefixed hex encoded value.

  This is `0` leading aware.

  ## Examples

      iex> binary_to_hex!(<<1, 10>>)
      "0x10a"
      iex> binary_to_hex!(<<33, 10>>)
      "0x210a"

  """
  def binary_to_hex!(bin) when is_binary(bin),
    do:
      bin
      |> Base.encode16(case: :lower)
      |> maybe_strip_leading_zero()
      |> hex_prefix!()

  @doc """
  Prepends a `0x` to a binary if needed.

  ## Examples

      iex> hex_prefix!("0x123")
      "0x123"
      iex> hex_prefix!("123")
      "0x123"

  """
  @spec hex_prefix!(binary) :: binary
  def hex_prefix!("0x" <> val), do: "0x" <> val
  def hex_prefix!(val), do: "0x" <> val

  ## Private.

  # Handle padding of hex values.
  defp maybe_pad_leading(rest, len) when is_even(len),
    do: rest

  defp maybe_pad_leading(rest, _len),
    do: "0" <> rest

  # Handle stripping of leading `0`s.
  defp maybe_strip_leading_zero("0" <> rest),
    do: rest

  defp maybe_strip_leading_zero(bin),
    do: bin
end
