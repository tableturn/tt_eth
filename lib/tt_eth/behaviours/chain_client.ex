defmodule TTEth.Behaviours.ChainClient do
  @moduledoc """
  The behaviours for a `TTEth.ChainClient` client.

  This allows for testing etc.
  """

  @type address :: TTEth.Type.Address.t()
  @type private_key :: TTEth.Type.PrivateKey.t()
  @type encoded_args :: binary
  @type opts :: keyword
  @type nonce :: non_neg_integer()
  @type tx_data :: <<_::16, _::_*8>>
  @type abi_data :: binary
  @type block_id :: String.t()
  @type filter_params :: map
  @type filter_id :: String.t()
  @type tx_obj :: map()

  @callback eth_call(contract :: address, encoded_args) :: any
  @callback eth_call(contract :: address, encoded_args, opts) :: any

  @callback eth_send_raw_transaction(tx_data) :: any
  @callback eth_send_raw_transaction(tx_data, opts) :: any

  @callback build_tx_data(address, abi_data, private_key, nonce) :: tx_data
  @callback build_tx_data(address, abi_data, private_key, nonce, keyword) :: tx_data

  @callback eth_get_transaction_count(account :: address, block_id) :: any
  @callback eth_get_transaction_count(account :: address, block_id, opts) :: any

  @callback eth_new_filter(filter_params) :: any
  @callback eth_new_filter(filter_params, opts) :: any

  @callback eth_get_filter_logs(filter_id) :: any
  @callback eth_get_filter_logs(filter_id, opts) :: any

  @callback eth_get_filter_changes(filter_id) :: any
  @callback eth_get_filter_changes(filter_id, opts) :: any

  @callback eth_get_max_priority_fee_per_gas() :: any
  @callback eth_get_max_priority_fee_per_gas(opts) :: any

  @callback eth_estimate_gas(tx_obj) :: any
  @callback eth_estimate_gas(tx_obj, opts) :: any

  @callback eth_get_block_by_number(block_id) :: any
  @callback eth_get_block_by_number(block_id, boolean) :: any
end
