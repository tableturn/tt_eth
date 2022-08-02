defmodule TTEth.WalletTest do
  use TTEth.Case, async: true

  @human_private_key "0xfa015243f2e6d8694ab037a7987dc73b1630fc8cb1ce82860344684c15d24026"

  describe "named/1" do
    test "reads from config" do
      for name <- [:primary, :secondary, :ternary] do
        name
        |> Wallet.named()
        |> assert_match(%Wallet{})
      end
    end

    test "builds all the needed information from the private key" do
      :ternary
      |> Wallet.named()
      |> assert_match_ternary_wallet()
    end
  end

  describe "from_private_key/1" do
    test "reconstructs everything from a human private key" do
      @human_private_key
      |> Wallet.from_private_key()
      |> assert_match_ternary_wallet()
    end

    test "reconstructs everything from a binary private key" do
      @human_private_key
      |> TTEth.Type.PrivateKey.from_human!()
      |> Wallet.from_private_key()
      |> assert_match_ternary_wallet()
    end
  end

  describe "new/0+1" do
    test "generates a random wallet every time" do
      assert Wallet.new() != Wallet.new()
    end

    test "generates a wallet deterministically given a keypair" do
      kp = TTEth.new_keypair()
      assert Wallet.new(kp) == Wallet.new(kp)
    end
  end

  ## Private.

  defp assert_match_ternary_wallet(wallet) do
    private_key = @human_private_key |> TTEth.Type.PrivateKey.from_human!()
    human_address = "0x0aF6b8a8E5D56F0ab74D47Ac446EEa46817F32bC"
    address = human_address |> TTEth.Type.Address.from_human!()

    human_public_key =
      "0x58be6efb58e39ce4b5d1ca552d80f8c9009dfecec0e5a31fc8d22ee866320c506be5" <>
        "8730c77623df9862d8041c1bdef8a031e5d38a1ac1b83d053277391f974c"

    public_key = human_public_key |> TTEth.Type.PublicKey.from_human!()

    wallet
    |> assert_match(%Wallet{
      human_address: ^human_address,
      human_private_key: @human_private_key,
      human_public_key: ^human_public_key,
      address: ^address,
      private_key: ^private_key,
      public_key: ^public_key
    })
  end
end
