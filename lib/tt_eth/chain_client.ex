defmodule TTEth.ChainClient do
  @moduledoc """
  A wrapper around `Ethereumex` providing the basics for various chain actions.

  This is agnostic to the transaction version/type.
  """
  alias TTEth.Behaviours.ChainClient
  alias TTEth.Wallet
  alias Ethereumex.HttpClient
  import TTEth, only: [transaction_module: 0, hex_prefix!: 1]

  @behaviour ChainClient

  ## ChainClient specific behaviour.

  @impl ChainClient
  def eth_call(contract_address, encoded_args, opts \\ []),
    do:
      %{data: encoded_args |> hex_prefix!(), to: contract_address}
      |> HttpClient.eth_call(opts |> Keyword.get(:block, "latest"), opts)

  @impl ChainClient
  def eth_send_raw_transaction(tx_data, opts \\ []),
    do: tx_data |> HttpClient.eth_send_raw_transaction(opts)

  # Delegate to the transaction module to serialize and sign the transaction.
  @impl ChainClient
  def build_tx_data("" <> to_address, abi_data, %Wallet{} = wallet, nonce, opts \\ [])
      when is_integer(nonce),
      do:
        to_address
        |> transaction_module().new(abi_data, nonce, opts)
        |> transaction_module().build(wallet)
        |> Base.encode16(case: :lower)
        |> hex_prefix!()

  @impl ChainClient
  def eth_get_balance(address, block \\ "latest", opts \\ []),
    do: address |> HttpClient.eth_get_balance(block, opts)

  @impl ChainClient
  def eth_get_transaction_count(address, block \\ "latest", opts \\ []),
    do: address |> HttpClient.eth_get_transaction_count(block, opts)

  @impl ChainClient
  def eth_get_logs(params, opts \\ []),
    do: params |> HttpClient.eth_get_logs(opts)

  @impl ChainClient
  def eth_new_filter(params, opts \\ []),
    do: params |> HttpClient.eth_new_filter(opts)

  @impl ChainClient
  def eth_get_filter_logs(filter_id, opts \\ []),
    do: filter_id |> HttpClient.eth_get_filter_logs(opts)

  @impl ChainClient
  def eth_get_filter_changes(filter_id, opts \\ []),
    do: filter_id |> HttpClient.eth_get_filter_changes(opts)

  @impl ChainClient
  def eth_get_max_priority_fee_per_gas(opts \\ []),
    do: "eth_maxPriorityFeePerGas" |> HttpClient.request(opts, [])

  @impl ChainClient
  def eth_estimate_gas(%{} = tx_obj, opts \\ []),
    do: tx_obj |> HttpClient.eth_estimate_gas(opts)

  @impl ChainClient
  def eth_fee_history(block_count, newest_block, reward_percentiles, opts \\ []),
    do: HttpClient.eth_fee_history(block_count, newest_block, reward_percentiles, opts)

  @impl ChainClient
  def eth_get_block_by_number("" <> block, tx_detail \\ false),
    do: block |> HttpClient.eth_get_block_by_number(tx_detail)

  @impl ChainClient
  def eth_get_code("" <> address, block \\ "latest", opts \\ []),
    do: address |> HttpClient.eth_get_code(block, opts)

  ## Helpers outside of the ChainClient behaviour.

  def eth_get_transaction_receipt("" <> tx_hash, opts \\ []),
    do: tx_hash |> HttpClient.eth_get_transaction_receipt(opts)
end
