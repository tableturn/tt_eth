defmodule TTEth.ChainClientMockImpl do
  @moduledoc """
  Implementation default for tests.
  """
  alias TTEth.Behaviours.ChainClient
  alias TTEth.Wallet

  @behaviour ChainClient

  @impl ChainClient
  def eth_call(_contract_address, _encoded_args, _opts \\ []),
    do: :error

  @impl ChainClient
  def eth_send_raw_transaction(_tx_data, _opts \\ []),
    do: :error

  @impl ChainClient
  def build_tx_data(to, abi_data, %Wallet{} = wallet, nonce, opts \\ []),
    do: to |> TTEth.ChainClient.build_tx_data(abi_data, wallet, nonce, opts)

  @impl ChainClient
  def eth_get_balance(_address, _block \\ "latest", _opts \\ []),
    do: {:ok, "0x7"}

  @impl ChainClient
  def eth_get_transaction_count(_address, _block \\ "latest", _opts \\ []),
    do: {:ok, "0x42"}

  @impl ChainClient
  def eth_get_logs(_params, _opts \\ []),
    do: {:error, :not_found}

  @impl ChainClient
  def eth_new_filter(_params, _opts \\ []),
    do: :error

  @impl ChainClient
  def eth_get_filter_logs(_filter_id, _opts \\ []),
    do: :error

  @impl ChainClient
  def eth_get_filter_changes(_filter_id, _opts \\ []),
    do: :error

  @impl ChainClient
  def eth_get_max_priority_fee_per_gas(_opts \\ []),
    do: {:ok, "0x10"}

  @impl ChainClient
  def eth_estimate_gas(%{} = _tx_obj, _opts \\ []),
    do: {:ok, "0x5208"}

  @impl ChainClient
  def eth_fee_history(_block_count, _newest_block, _reward_percentiles, _opts \\ []),
    do:
      {:ok,
       [
         %{
           "oldestBlock" => "0x54",
           "reward" => [
             [
               "0x174876e800",
               "0x174876e800"
             ],
             [
               "0x174876e800",
               "0x174876e800"
             ],
             [
               "0x174876e800",
               "0x174876e800"
             ]
           ],
           "baseFeePerGas" => [
             "0x0",
             "0x0",
             "0x0",
             "0x0"
           ],
           "gasUsedRatio" => [
             0.0010253063265735019,
             0.006479788956353575,
             0.00006763590977418037
           ]
         }
       ]}

  @impl ChainClient
  def eth_get_block_by_number(_block, _tx_detail \\ false),
    do: {:ok, %{"number" => "0x1", "baseFeePerGas" => "0x10"}}
end
