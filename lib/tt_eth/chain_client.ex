defmodule TTEth.ChainClient do
  @moduledoc """
  A wrapper around `Ethereumex` providing the basics for various chain actions.

  This is agnostic to the transaction version/type.
  """
  alias TTEth.Behaviours.ChainClient
  alias Ethereumex.HttpClient
  import TTEth, only: [transaction_module: 0]

  @behaviour ChainClient

  ## ChainClient specific behaviour.

  @impl ChainClient
  def eth_call(contract_address, encoded_args, opts \\ []),
    do:
      %{data: encoded_args |> prepend_hex(), to: contract_address}
      |> HttpClient.eth_call(opts |> Keyword.get(:block, "latest"), opts)

  @impl ChainClient
  def eth_send_raw_transaction(tx_data, opts \\ []),
    do: tx_data |> HttpClient.eth_send_raw_transaction(opts)

  # Delegate to the transaction module to serialize and sign the transaction.
  @impl ChainClient
  def build_tx_data("" <> to_address, abi_data, private_key, nonce, opts \\ [])
      when is_integer(nonce),
      do:
        to_address
        |> transaction_module().new(abi_data, nonce, opts)
        |> transaction_module().build(private_key)
        |> Base.encode16(case: :lower)
        |> prepend_hex()

  @impl ChainClient
  def eth_get_transaction_count(address, block \\ "latest", opts \\ []),
    do: address |> HttpClient.eth_get_transaction_count(block, opts)

  @impl ChainClient
  def eth_new_filter(params, opts \\ []),
    do: params |> HttpClient.eth_new_filter(opts)

  @impl ChainClient
  def eth_get_filter_logs(filter_id, opts \\ []),
    do: filter_id |> HttpClient.eth_get_filter_logs(opts)

  @impl ChainClient
  def eth_get_filter_changes(filter_id, opts \\ []),
    do: filter_id |> HttpClient.eth_get_filter_changes(opts)

  ## Helpers outside of the ChainClient behaviour.

  def eth_estimate_gas(tx_hash, opts \\ []),
    do: tx_hash |> HttpClient.eth_estimate_gas(opts)

  def eth_get_transaction_receipt(tx_hash, opts \\ []),
    do: tx_hash |> HttpClient.eth_get_transaction_receipt(opts)

  ## Private.

  defp prepend_hex(data),
    do: "0x" <> data
end
