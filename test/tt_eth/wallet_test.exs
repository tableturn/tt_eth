defmodule TTEth.WalletTest do
  use TTEth.Case, async: true
  alias TTEth.LocalWallet

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
  end

  describe "new/0+1" do
    test "generates a random wallet every time" do
      assert Wallet.new() != Wallet.new()
    end

    test "generates a wallet deterministically given a keypair" do
      kp = LocalWallet.generate()
      assert Wallet.new(kp) == Wallet.new(kp)
    end
  end

  describe "sign/2" do
    setup :build_wallet

    test "given a wallet and digest, signs the digest", %{wallet: wallet} do
      wallet
      |> Wallet.sign("some plaintext" |> TTEth.keccak())
      |> assert_match({:ok, {<<_signature::512>>, recovery_id}} when recovery_id in [0, 1])
    end

    test "returns an error tuple if a failure happens", %{wallet: wallet} do
      wallet
      |> Wallet.sign("some plaintext")
      |> assert_equal({:error, :wrong_message_size})
    end
  end

  describe "sign!/2" do
    setup :build_wallet

    test "same as sign/2", %{wallet: wallet} do
      digest = "some plaintext" |> TTEth.keccak()

      {:ok, compact_signature} =
        wallet
        |> Wallet.sign(digest)

      wallet
      |> Wallet.sign!(digest)
      |> assert_match(^compact_signature)
    end
  end

  describe "personal_sign/2" do
    setup :build_wallet

    test "signs a plaintext using the EIP-191 standard", %{wallet: wallet} do
      wallet
      |> Wallet.personal_sign("some plaintext")
      |> assert_match({:ok, {v, _r, _s}} when v in [27, 28])
    end
  end

  describe "personal_sign!/2" do
    setup :build_wallet

    test "same as personal_sign/2", %{wallet: wallet} do
      {:ok, components} =
        wallet
        |> Wallet.personal_sign("some plaintext")

      wallet
      |> Wallet.personal_sign!("some plaintext")
      |> assert_match(^components)
    end
  end

  ## Private.

  defp assert_match_ternary_wallet(wallet) do
    human_address = "0x0aF6b8a8E5D56F0ab74D47Ac446EEa46817F32bC"
    address = human_address |> TTEth.Type.Address.from_human!()

    private_key = @human_private_key |> TTEth.Type.PrivateKey.from_human!()

    human_public_key =
      "0x58be6efb58e39ce4b5d1ca552d80f8c9009dfecec0e5a31fc8d22ee866320c506be5" <>
        "8730c77623df9862d8041c1bdef8a031e5d38a1ac1b83d053277391f974c"

    public_key = human_public_key |> TTEth.Type.PublicKey.from_human!()

    wallet
    |> assert_match(%Wallet{
      address: ^address,
      public_key: ^public_key,
      human_address: ^human_address,
      human_public_key: ^human_public_key,
      _adapter: %LocalWallet{
        private_key: ^private_key,
        human_private_key: @human_private_key
      }
    })
  end

  defp build_wallet(_),
    do: %{wallet: Wallet.new()}
end
