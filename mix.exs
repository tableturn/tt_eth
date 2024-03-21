defmodule TTEth.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project(),
    do: [
      app: :tt_eth,
      version: @version,
      description: "Ethereum primitives for Elixir.",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      # Docs
      name: "TTEth",
      source_url: "https://github.com/tableturn/tt_eth",
      docs: [
        extras: ["README.md"],
        groups_for_modules: groups_for_modules()
      ]
    ]

  defp elixirc_paths(:test),
    do: ["lib", "test/support"]

  defp elixirc_paths(_),
    do: ["lib"]

  defp deps(),
    do: [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
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

  defp groups_for_modules(),
    do: [
      "Transactions Types": [
        TTEth.Transactions.LegacyTransaction,
        TTEth.Transactions.EIP1559Transaction
      ],
      Behaviours: [
        TTEth.Behaviours.ChainClient,
        TTEth.Behaviours.Transaction,
        TTEth.Behaviours.WalletAdapter
      ],
      Types: [
        TTEth.Type.Address,
        TTEth.Type.Hash,
        TTEth.Type.PrivateKey,
        TTEth.Type.PublicKey,
        TTEth.Type.Signature
      ]
    ]
end
