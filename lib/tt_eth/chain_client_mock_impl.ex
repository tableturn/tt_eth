defmodule TTEth.ChainClientMockImpl do
  @moduledoc """
  Implementation default for tests.
  """
  alias TTEth.Behaviours.ChainClient

  @behaviour ChainClient

  @impl ChainClient
  def eth_call(_contract_address, _encoded_args, _opts \\ []),
    do: :error

  @impl ChainClient
  def eth_send_raw_transaction(_tx_data, _opts \\ []),
    do: :error

  @impl ChainClient
  def build_tx_data(to, abi_data, private_key, nonce, opts \\ []),
    do: to |> TTEth.ChainClient.build_tx_data(abi_data, private_key, nonce, opts)

  @impl ChainClient
  def eth_get_transaction_count(_address, _block \\ "latest", _opts \\ []),
    do: {:ok, "0x42"}

  @impl ChainClient
  def eth_new_filter(_params, _opts \\ []),
    do: :error

  @impl ChainClient
  def eth_get_filter_logs(_filter_id, _opts \\ []),
    do: :error

  @impl ChainClient
  def eth_get_filter_changes(_filter_id, _opts \\ []),
    do: :error
end
