defmodule TTEth.Transactions.EIP1559TransactionTest do
  use TTEth.Case
  alias TTEth.Transactions.EIP1559Transaction
  alias TTEth.Type.{Address, PrivateKey, PublicKey}
  alias TTEth.Wallet

  # Polygon Mumbai.
  @chain_id 80_001

  @private_key_human "0x62aa6ec41b56439d2c5df352c45a00389cef262b3761e13c6481e35ab027d262"
  @to_address_human "0x38f153fdd399ff2cf64704c6a4b16d3fd9ddcd69"
  @to_address @to_address_human |> Address.from_human!()
  # transfer(address,uint256)
  @tx_data_human "a9059cbb00000000000000000000000038f153fdd399ff2cf64704c6a4b16d3fd9ddcd69000000000000000000000000000000000000000000000000000000000000000a"
  @tx_data @tx_data_human |> Base.decode16!(case: :lower)

  # Expected valid transaction data.
  @valid_transaction_data "0x02f8b2830138810184b2d05e0184b2d05e008252089438f153fdd399ff2cf6" <>
                            "4704c6a4b16d3fd9ddcd6980b844a9059cbb000000000000000000000000" <>
                            "38f153fdd399ff2cf64704c6a4b16d3fd9ddcd6900000000000000000000" <>
                            "0000000000000000000000000000000000000000000ac001a027995f5230" <>
                            "24701f3eb15f1a664651f127c09a70aacbc334dbe36c2fb9b87c4ea03572" <>
                            "c5dfa49a14fce646eb8de6a4f3d6e2e25dacbb7a0dca8891f0f3e6cb801f"

  @nonce 1

  describe "new/4" do
    test "returns an EIP1559 transaction struct" do
      @to_address
      |> EIP1559Transaction.new(
        @tx_data,
        @nonce,
        _opts = [chain_id: @chain_id]
      )
      |> assert_match(%EIP1559Transaction{
        type: 2,
        nonce: @nonce,
        chain_id: @chain_id,
        gas_limit: 500_000,
        max_fee_per_gas: 500_000,
        max_priority_fee_per_gas: 500_000,
        init: <<>>,
        data: @tx_data,
        to: @to_address,
        access_list: [],
        y_parity: 0,
        r: 0,
        s: 0
      })
    end
  end

  describe "build/2" do
    setup [
      :build_trx,
      :build_wallet
    ]

    test "builds a signed transaction", %{trx: trx, wallet: wallet} do
      trx
      |> EIP1559Transaction.build(wallet)
      |> encode_and_pad()
      |> assert_match(@valid_transaction_data)
    end

    test "from address is correct when checking signature", %{trx: trx, wallet: wallet} do
      # Build the trx_data but randomize the nonce.
      built_trx_data =
        %{trx | nonce: Enum.random(10..100)}
        |> EIP1559Transaction.build(wallet)
        |> encode_and_pad()

      # Decode the transaction data.
      decoded = built_trx_data |> fully_decode_trx_data()

      # Get signature params.
      [y_parity, r, s] = decoded |> Enum.take(_signature_params = -3)

      # Get the raw public key from the signature.
      {:ok, public_raw} =
        decoded
        |> Enum.take(_everything_but_the_signature = 9)
        |> ExRLP.encode()
        |> put_trx_envelope()
        |> TTEth.keccak()
        |> TTEth.Secp256k1.ecdsa_recover_compact(
          _signature = r <> s,
          _recovery_id = y_parity |> :binary.decode_unsigned()
        )

      # Get the formatted public key from the private key.
      original_public_key =
        @private_key_human
        |> PrivateKey.from_human!()
        |> PublicKey.from_private_key!()
        |> Address.from_public_key!()
        |> Address.encode_eth_address!()

      # Attempt to match the public key from the signature with the private key's public key.
      public_raw
      |> Address.from_public_key!()
      |> Address.encode_eth_address!()
      |> assert_match(^original_public_key)
    end
  end

  ## Private.

  defp build_trx(_),
    do: %{
      trx: %EIP1559Transaction{
        to: @to_address,
        data: @tx_data,
        chain_id: @chain_id,
        nonce: @nonce,
        gas_limit: 21_000,
        max_fee_per_gas: 3_000_000_000,
        max_priority_fee_per_gas: 3_000_000_001,
        value: 0
      }
    }

  defp build_wallet(_),
    do: %{wallet: @private_key_human |> Wallet.from_private_key()}

  ## Helpers.

  defp encode_and_pad(bin),
    do:
      bin
      |> Base.encode16(case: :lower)
      |> TTEth.hex_prefix!()

  # Decode the hex encoded transaction.
  defp fully_decode_trx_data("0x" <> data),
    do:
      data
      |> Base.decode16!(case: :lower)
      |> :binary.bin_to_list()
      |> Enum.drop(_drop_transaction_envelope = 1)
      |> :binary.list_to_bin()
      |> ExRLP.decode()

  defp put_trx_envelope(data),
    do: <<2>> <> data
end
