defmodule TTEth.Type.SignatureTest do
  use ExUnit.Case
  alias TTEth.Type.Signature
  alias TTEth.Fixtures.Signature1, as: S1
  doctest Signature, import: true

  @message S1.message()
  @digest S1.digest()
  @binary_sig S1.signature(:binary)
  @human_sig S1.signature(:human)
  @binary_pubkey S1.pubkey(:binary)

  describe "sign/2" do
    test "can sign and verify a message and private key" do
      {pub, priv} = TTEth.new_keypair()
      {:ok, sig_components} = @message |> Signature.sign(priv)
      {:ok, recovered} = @message |> Signature.digest() |> Signature.recover(sig_components)
      assert pub == recovered
    end
  end

  describe "recover/3" do
    test "it recovers" do
      assert @binary_pubkey ==
               @message
               |> Signature.digest()
               |> Signature.recover!(@binary_sig |> Signature.components!())
    end
  end

  describe "digest/1" do
    test "computes the digest of the given message" do
      assert @digest == @message |> Signature.digest()
    end
  end

  describe "decorate_message/1" do
    exp = <<0x19, "Ethereum Signed Message:", ?\n, "#{byte_size(@message)}">> <> @message
    assert exp == @message |> Signature.decorate_message()
  end

  describe "type/0" do
    test "uses :binary as storage type" do
      assert Signature.type() == :binary
    end
  end

  describe "cast/1 and load/1" do
    test "suceeds with a readable address" do
      assert {:ok, @human_sig} == @human_sig |> Signature.cast()
      assert {:ok, @human_sig} == @human_sig |> Signature.load()
    end

    test "succeeds with a binary address" do
      assert {:ok, @human_sig} == @binary_sig |> Signature.cast()
      assert {:ok, @human_sig} == @binary_sig |> Signature.load()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @human_sig} == <<0x04, @binary_sig>> |> Signature.cast()
      assert {:ok, @human_sig} == <<0x04, @binary_sig>> |> Signature.load()
    end

    test "fails properly with the :error return code" do
      assert :error == <<0x00, @binary_sig>> |> Signature.cast()
      assert :error == <<0x00, @binary_sig>> |> Signature.load()
    end
  end

  describe "dump/1" do
    test "suceeds with a readable address" do
      assert {:ok, @binary_sig} == @human_sig |> Signature.dump()
    end

    test "succeeds with a binary address" do
      assert {:ok, @binary_sig} == @binary_sig |> Signature.dump()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @binary_sig} == <<0x04, @binary_sig>> |> Signature.dump()
    end

    test "fails properly with the :error return code" do
      assert :error == <<0x00, @binary_sig>> |> Signature.dump()
    end
  end

  describe "to_human/1" do
    test "suceeds with a readable address" do
      assert {:ok, @human_sig} == @human_sig |> Signature.to_human()
    end

    test "succeeds with a binary address" do
      assert {:ok, @human_sig} == @binary_sig |> Signature.to_human()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @human_sig} == <<0x04, @binary_sig>> |> Signature.to_human()
    end

    test "fails properly with the :error return code" do
      assert {:error, :invalid_input} == <<0x00, @binary_sig>> |> Signature.to_human()
    end
  end

  describe "from_human/1" do
    test "suceeds with a readable address" do
      assert {:ok, @binary_sig} == @human_sig |> Signature.from_human()
    end

    test "succeeds with a binary address" do
      assert {:ok, @binary_sig} == @binary_sig |> Signature.from_human()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @binary_sig} == <<0x04, @binary_sig>> |> Signature.from_human()
    end

    test "fails properly with the :error return code" do
      assert {:error, :invalid_input} == <<0x00, @binary_sig>> |> Signature.from_human()
    end
  end
end
