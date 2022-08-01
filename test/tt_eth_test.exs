defmodule TTEthTest do
  use TTEth.Case, async: true
  doctest TTEth, import: true

  @chain_id 12345

  describe "new_keypair/0" do
    test "generates a public and private key" do
      {pub, priv} = TTEth.new_keypair()
      assert byte_size(pub) == 65
      assert byte_size(priv) == 32
    end
  end

  describe "keccak/1" do
    test "generates the sha3 hash of the input data" do
      assert "OsIlFo31QhKiXBwB/TW+v+pAj9rC4x3db4Cku/ml8cs=" ==
               "a" |> TTEth.keccak() |> Base.encode64()
    end
  end

  describe "send_raw_transaction/4+1" do
    test "retrieves the sender account nonce and uses it for the transaction" do
      wallet = Wallet.new()
      to_human = Faker.Blockchain.Ethereum.address()
      to = to_human |> TTEth.Type.Address.from_human!()
      recipient = Faker.Blockchain.Ethereum.address()
      raw_recipient = recipient |> TTEth.Type.Address.from_human!()

      ChainClientMock
      # We want to make sure that the account nonce is fetched.
      |> expect(:eth_get_transaction_count, fn account, block_id ->
        assert account == wallet.human_address
        assert block_id == "pending"
        {:ok, "0x123"}
      end)
      # We don't care about encoding and signing in this test.
      |> expect(:eth_send_raw_transaction, fn _, _ -> {:ok, "0x0"} end)

      wallet
      |> TTEth.send_raw_transaction(to, "transfer(address,uint256)", [raw_recipient, 1],
        chain_id: @chain_id
      )
    end

    test "encodes and signs the transaction using deterministic parameters" do
      private_key = "0x7275e4e1f0e3851062d029e4f10f725af5da05818f652e1fc451674f44bde367"
      wallet = private_key |> Wallet.from_private_key()
      to_human = "0x5b1149599100b424315695a0f7d4c205114c1452"
      to = to_human |> TTEth.Type.Address.from_human!()
      recipient = "0x907bd49fb2669ecbe8fc8c0d8463cc5ba32c777f"
      raw_recipient = recipient |> TTEth.Type.Address.from_human!()
      nonce_hex = "0x42"
      nonce_dec = 66
      method = "transfer(address,uint256)"
      args = [raw_recipient, 1]
      abi_data = method |> ABI.encode(args)

      tx_data =
        to
        |> TTEth.ChainClient.build_tx_data(abi_data, wallet.private_key, nonce_dec,
          chain_id: @chain_id
        )

      ChainClientMock
      # We don't care about this in this test.
      |> expect(:eth_get_transaction_count, fn _, _ -> {:ok, nonce_hex} end)
      # We want to make sure that the transaction building function was called with the correct params.
      |> expect(:build_tx_data, fn to_, abi_data_, private_key_, nonce_, opts_ ->
        assert to_ == to
        assert abi_data == abi_data_
        assert private_key_ == wallet.private_key
        assert nonce_ == nonce_dec
        assert opts_ == [chain_id: @chain_id]
        tx_data
      end)

      # The underlying function should have been given the transaction data directly.
      |> expect(:eth_send_raw_transaction, fn tx_data_, [chain_id: chain_id] ->
        assert tx_data_ == tx_data
        assert chain_id == @chain_id
      end)

      wallet
      |> TTEth.send_raw_transaction(to, "transfer(address,uint256)", args, chain_id: @chain_id)
    end

    test "allows overriding of the options passed to the chain client" do
      ChainClientMock
      # We don't care about this in this test.
      |> expect(:eth_get_transaction_count, fn _, _ -> {:ok, "0x123"} end)
      # We want to make sure that options are passed to the chain client direclty.
      |> expect(:eth_send_raw_transaction, fn _, opts ->
        assert opts == [foo: :bar, chain_id: @chain_id]
      end)

      Wallet.new()
      |> TTEth.send_raw_transaction(
        _to = Faker.Blockchain.Ethereum.address() |> TTEth.Type.Address.from_human!(),
        "transfer(address,uint256)",
        [
          _recipient = Faker.Blockchain.Ethereum.address() |> TTEth.Type.Address.from_human!(),
          _amount = 1
        ],
        foo: :bar,
        chain_id: @chain_id
      )
    end
  end
end
