defmodule TTEth.Behaviours.Wallet do
  @moduledoc """
  Behaviour for wallet adapters.
  """

  @typedoc """
  This represents the config for a wallet adapter.

  Check the documentation for the adapter for specific configuration options.
  """
  @type config :: map() | binary()

  @doc """
  Returns a new populated wallet struct.
  """
  @callback new(config) :: struct()
end
