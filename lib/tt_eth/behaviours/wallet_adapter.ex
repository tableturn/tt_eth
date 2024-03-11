defmodule TTEth.Behaviours.WalletAdapter do
  @moduledoc """
  Defines a shared behaviour for wallet adapters.
  """

  @typedoc """
  This represents the config for a wallet adapter.

  Check the documentation for the adapter for specific configuration options.
  """
  @type config :: map() | binary()

  @typedoc """
  Represents a wallet adapter.
  """
  @type wallet_adapter :: struct()

  @doc """
  Returns a new populated wallet adapter struct.
  """
  @callback new(config) :: wallet_adapter

  @doc """
  Provides the attributes needed to build a `Wallet.t` using the passed `wallet_adapter`.
  """
  @callback wallet_attrs(wallet_adapter) :: map()

  @doc """
  Signs `digest` using the given `wallet_adapter`.
  """
  @callback sign(wallet_adapter, digest :: binary()) :: {:ok, binary()} | {:error, any()}
end
