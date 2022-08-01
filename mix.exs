defmodule TTEth.MixProject do
  use Mix.Project

  def project(),
    do: [
      app: :tt_eth,
      version: "0.1.0",
      description: "Ethereum primitives for Elixir.",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]

  defp elixirc_paths(:test),
    do: ["lib", "test/support"]

  defp elixirc_paths(_),
    do: ["lib"]

  defp deps(),
    do: [
      {:faker, "~> 0.13", only: [:dev, :test]},
      {:hammox, "~> 0.7.0", only: [:test]},
      {:ecto, "~> 3.5"},
      {:ex_secp256k1, "~> 0.5"},
      {:eip_55, "~> 0.1"},
      {:ethereumex, "~> 0.10.0"},
      {:ex_keccak, "~> 0.2"},
      {:ex_abi, "~> 0.5"},
      {:ex_rlp, "~> 0.5.3"}
    ]
end
