defmodule TTEth.EndToEndTest do
  use TTEth.Case
  alias TTEth.Type.{Address, Signature, PublicKey}
  alias TTEth.Fixtures.Signature1, as: S1
  doctest Signature, import: true

  @message S1.message()
  @digest S1.digest()
  @binary_sig S1.signature(:binary)
  @comp_sig S1.signature(:components)
  @human_sig S1.signature(:human)
  @binary_pubkey S1.pubkey(:binary)
  @human_pubkey S1.pubkey(:human)
  @binary_addr S1.address(:binary)
  @human_addr S1.address(:human)

  describe "recovering using fixture data" do
    test "with controled returns" do
      # Digest message.
      digest = @message |> Signature.digest()
      # Convert human signature to binary.
      {:ok, binary_sig} = @human_sig |> Signature.from_human()
      # Convert binary signature to components.
      {:ok, comp_sig} = binary_sig |> Signature.components()
      # Convert binary signature to human signature.
      {:ok, human_sig} = binary_sig |> Signature.to_human()
      # Sign digest.
      {:ok, binary_pubkey} = digest |> Signature.recover(comp_sig)
      # Convert binary public key into human.
      {:ok, human_pubkey} = binary_pubkey |> PublicKey.to_human()
      # Extract public binary address.
      {:ok, binary_addr} = binary_pubkey |> Address.from_public_key()
      # Extract human address.
      {:ok, human_addr} = binary_addr |> Address.to_human()

      assert @digest == digest
      assert @binary_sig == binary_sig
      assert @comp_sig == comp_sig
      assert @human_sig == human_sig
      assert @binary_pubkey == binary_pubkey
      assert @human_pubkey == human_pubkey
      assert @binary_addr = binary_addr
      assert @human_addr == human_addr
    end

    test "with pipeline style" do
      @message
      |> Signature.digest()
      |> assert_equal(@digest)
      |> Signature.recover!(Signature.components!(@binary_sig))
      |> assert_equal(@binary_pubkey)
      |> Address.from_public_key!()
      |> assert_equal(@binary_addr)
      |> Address.to_human!()
      |> assert_equal(@human_addr)
    end
  end

  test "recovering using random keys" do
    # Generate keypair.
    {pub, priv} = TTEth.new_keypair()
    # Extract address.
    addr = pub |> Address.from_public_key!()
    human_addr = addr |> Address.to_human!()
    # Store signature original components.
    sig_as_comps = @message |> Signature.sign!(priv)
    # Store human version of the signature.
    human_sig = sig_as_comps |> Signature.to_human_from_components!()
    # Try to get back to components from human signature.
    comps_from_human_sig = human_sig |> Signature.from_human!() |> Signature.components!()
    # Recover public key from signature and message.
    rec_pub = @message |> Signature.digest() |> Signature.recover!(sig_as_comps)
    # Get the address from the recovered public key.
    addr_from_rec_pub = rec_pub |> Address.from_public_key!()
    human_addr_from_rec_pub = addr_from_rec_pub |> Address.to_human!()

    # Assert everything.
    assert sig_as_comps == comps_from_human_sig
    assert pub == rec_pub
    assert human_addr == human_addr_from_rec_pub
  end
end
