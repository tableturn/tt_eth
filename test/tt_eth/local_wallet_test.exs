defmodule TTEth.LocalWalletTest do
  use TTEth.Case
  alias TTEth.LocalWallet
  alias TTEth.Type.PrivateKey
  alias TTEth.Protocols.Wallet, as: WalletProtocol

  @human_private_key "0xfa015243f2e6d8694ab037a7987dc73b1630fc8cb1ce82860344684c15d24026"

  describe "implements TTEth.Protocols.Wallet protocol" do
    setup :build_local_wallet

    test "wallet_attrs/1 - returns attributes needed when building a wallet", %{
      local_wallet: local_wallet
    } do
      local_wallet
      |> WalletProtocol.wallet_attrs()
      |> assert_match(
        address: _,
        public_key: _,
        human_address: "0x" <> _,
        human_public_key: "0x" <> _,
        _adapter: ^local_wallet
      )
    end

    test "sign/2 - signs the given digest with the wallet", %{
      local_wallet: local_wallet
    } do
      local_wallet
      |> WalletProtocol.sign("some plaintext" |> TTEth.keccak())
      |> assert_match({:ok, {<<_signature::512>>, recovery_id}} when recovery_id in [0, 1])
    end
  end

  describe "implements TTEth.Behaviours.Wallet behaviour" do
    test "new/1 - initializes a new CloudKMS struct" do
      decoded_private_key = @human_private_key |> PrivateKey.from_human!()

      %{private_key: @human_private_key}
      |> LocalWallet.new()
      |> assert_match(%LocalWallet{
        private_key: ^decoded_private_key,
        human_private_key: @human_private_key
      })
    end
  end

  ## Private.

  defp build_local_wallet(_),
    do: %{local_wallet: @human_private_key |> LocalWallet.new()}
end
