defmodule TTEth.Type.PrivateKey do
  @moduledoc "This module is an Ecto-compatible type that can represent Ethereum private keys."
  use TTEth.Type, size: 32
end
