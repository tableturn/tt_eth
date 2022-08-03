defmodule TTEth.TestToken do
  use TTEth.Contract,
    abi_file: Application.app_dir(:tt_eth, "priv/fixtures/contract_abis/TestToken.abi")
end
