defmodule TTEth.TestToken do
  @moduledoc false
  use TTEth.Contract,
    abi_file: Application.app_dir(:tt_eth, "priv/fixtures/contract_abis/TestToken.abi")
end
