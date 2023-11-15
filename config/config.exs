import Config

config :tt_eth,
  # A list of your private keys. These are used for tests only here.
  # Be extremely careful when storing these.
  # These should be "0x" prefixed.
  # Generation: `"0x" <> (:crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower))`
  wallets: [
    primary: "0xf90f7e5e801d8820666a1c941e518eae78601e1a4c4305bbe18217dd7bc6d030",
    secondary: "0xe2187dc017e880dded10c403f7c0d397afb11736ac027c1202e318b0dd345086",
    ternary: "0xfa015243f2e6d8694ab037a7987dc73b1630fc8cb1ce82860344684c15d24026"
  ],
  transaction_module: TTEth.Transactions.LegacyTransaction,
  signer_module: TTEth.Secp256k1
