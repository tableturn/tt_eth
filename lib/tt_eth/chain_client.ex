defmodule TTEth.ChainClient do
  @moduledoc """
  A wrapper around `Ethereumex` providing the basics for various chain actions.
  """
  alias TTEth.Behaviours.ChainClient
  alias TTEth.Transaction

  @behaviour ChainClient

  @impl ChainClient
  def eth_call(contract_address, encoded_args, opts \\ []),
    do:
      %{data: "0x" <> encoded_args, to: contract_address}
      |> Ethereumex.HttpClient.eth_call("latest", opts)

  @impl ChainClient
  def eth_send_raw_transaction(tx_data, opts \\ []),
    do: tx_data |> Ethereumex.HttpClient.eth_send_raw_transaction(opts)

  @impl ChainClient
  def build_tx_data(to, abi_data, private_key, nonce, opts \\ []),
    do:
      "0x" <>
        (%Transaction{
           data: abi_data,
           gas_limit: opts |> Keyword.get(:gas_limit, 500_000),
           gas_price: opts |> Keyword.get(:gas_price, 1),
           nonce: nonce,
           to: to,
           value: opts |> Keyword.get(:value, 0),
           r: 0,
           s: 0,
           v: 0
         }
         |> Transaction.sign_transaction(private_key, opts[:chain_id])
         |> Transaction.serialize()
         |> ExRLP.encode()
         |> Base.encode16(case: :lower))

  def eth_get_transaction_receipt(tx_hash, opts \\ []),
    do: tx_hash |> Ethereumex.HttpClient.eth_get_transaction_receipt(opts)

  @impl ChainClient
  def eth_get_transaction_count(address, block \\ "latest", opts \\ []),
    do: address |> Ethereumex.HttpClient.eth_get_transaction_count(block, opts)

  @impl ChainClient
  def eth_new_filter(params, opts \\ []),
    do: params |> Ethereumex.HttpClient.eth_new_filter(opts)

  @impl ChainClient
  def eth_get_filter_logs(filter_id, opts \\ []),
    do: filter_id |> Ethereumex.HttpClient.eth_get_filter_logs(opts)

  @impl ChainClient
  def eth_get_filter_changes(filter_id, opts \\ []),
    do: filter_id |> Ethereumex.HttpClient.eth_get_filter_changes(opts)
end
