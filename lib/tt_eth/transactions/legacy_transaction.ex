defmodule TTEth.Transactions.LegacyTransaction do
  @moduledoc """
  Ported from [`Blockchain`](https://hex.pm/packages/blockchain).
  """
  alias TTEth.{BitHelper, Wallet}
  alias TTEth.Behaviours.Transaction
  import BitHelper, only: [encode_unsigned: 1]

  @behaviour Transaction

  @type hash_v :: integer()
  @type hash_r :: integer()
  @type hash_s :: integer()

  @type val :: integer()
  @type address :: <<_::160>>
  @type hash :: <<_::256>>

  @base_v 27
  @base_v_eip_155 35

  @type t :: %__MODULE__{
          nonce: integer(),
          chain_id: integer(),
          gas_price: integer(),
          gas_limit: integer(),
          to: address() | <<_::0>>,
          value: integer(),
          v: hash_v(),
          r: hash_r(),
          s: hash_s(),
          init: binary(),
          data: binary()
        }

  defstruct nonce: 0,
            chain_id: 0,
            gas_price: 0,
            gas_limit: 0,
            to: <<>>,
            value: 0,
            v: 0,
            r: 0,
            s: 0,
            init: <<>>,
            data: <<>>

  @impl Transaction
  def new("" <> to_address, abi_data, nonce, opts) when is_integer(nonce),
    do: %__MODULE__{
      chain_id: opts |> Keyword.get(:chain_id),
      data: abi_data,
      gas_limit: opts |> Keyword.get(:gas_limit, 500_000),
      gas_price: opts |> Keyword.get(:gas_price, 1),
      nonce: nonce,
      to: to_address,
      value: opts |> Keyword.get(:value, 0)
    }

  @impl Transaction
  def build(%__MODULE__{} = trx, %Wallet{} = wallet),
    do:
      trx
      |> sign_transaction(wallet)
      |> serialize(_include_signature = true)
      |> rlp_encode()

  @doc """
  Delegate to ExRLP to RLP encode values.
  """
  def rlp_encode(data),
    do: data |> ExRLP.encode()

  @doc """
  Encodes a transaction such that it can be RLP-encoded.
  This is defined at L_T Eq.(14) in the Yellow Paper.

  ## Examples

      iex> LegacyTransaction.serialize(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<1::160>>, value: 8, v: 27, r: 9, s: 10, data: "hi"})
      [<<5>>, <<6>>, <<7>>, <<1::160>>, <<8>>, "hi", <<27>>, <<9>>, <<10>>]

      iex> LegacyTransaction.serialize(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 8, v: 27, r: 9, s: 10, init: <<1, 2, 3>>})
      [<<5>>, <<6>>, <<7>>, <<>>, <<8>>, <<1, 2, 3>>, <<27>>, <<9>>, <<10>>]

      iex> LegacyTransaction.serialize(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 8, v: 27, r: 9, s: 10, init: <<1, 2, 3>>}, false)
      [<<5>>, <<6>>, <<7>>, <<>>, <<8>>, <<1, 2, 3>>]

      iex> LegacyTransaction.serialize(%LegacyTransaction{ data: "", gas_limit: 21000, gas_price: 20000000000, init: "", nonce: 9, r: 0, s: 0, to: "55555555555555555555", v: 1, value: 1000000000000000000 })
      ["\t", <<4, 168, 23, 200, 0>>, "R\b", "55555555555555555555", <<13, 224, 182, 179, 167, 100, 0, 0>>, "", <<1>>, "", ""]

  """
  @spec serialize(t) :: ExRLP.t()
  def serialize(trx, include_vrs \\ true) do
    base = [
      trx.nonce |> encode_unsigned(),
      trx.gas_price |> encode_unsigned(),
      trx.gas_limit |> encode_unsigned(),
      trx.to,
      trx.value |> encode_unsigned(),
      if(trx.to == <<>>, do: trx.init, else: trx.data)
    ]

    if include_vrs do
      base ++
        [
          trx.v |> encode_unsigned(),
          trx.r |> encode_unsigned(),
          trx.s |> encode_unsigned()
        ]
    else
      base
    end
  end

  @doc """
  Returns a ECDSA signature (v,r,s) for a given hashed value.

  This implementes Eq.(207) of the Yellow Paper.

  ## Examples

      iex> wallet = TTEth.Wallet.from_private_key(_private_key = <<1::256>>)
      iex> LegacyTransaction.sign_hash(<<2::256>>, wallet)
      {28,
      38938543279057362855969661240129897219713373336787331739561340553100525404231,
      23772455091703794797226342343520955590158385983376086035257995824653222457926}

      iex> wallet = TTEth.Wallet.from_private_key(_private_key = <<1::256>>)
      iex> LegacyTransaction.sign_hash(<<5::256>>, wallet)
      {27,
      74927840775756275467012999236208995857356645681540064312847180029125478834483,
      56037731387691402801139111075060162264934372456622294904359821823785637523849}

      iex> data = "ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080" |> TTEth.BitHelper.from_hex
      iex> hash = data |> TTEth.keccak()
      iex> private_key = "4646464646464646464646464646464646464646464646464646464646464646" |> TTEth.BitHelper.from_hex
      iex> wallet = TTEth.Wallet.from_private_key(private_key)
      iex> LegacyTransaction.sign_hash(hash, wallet, 1)
      { 37, 18515461264373351373200002665853028612451056578545711640558177340181847433846, 46948507304638947509940763649030358759909902576025900602547168820602576006531 }

  """
  @spec sign_hash(BitHelper.keccak_hash(), Wallet.t(), integer() | nil) ::
          {hash_v, hash_r, hash_s}
  def sign_hash(hash, %Wallet{} = wallet, chain_id \\ nil) do
    {:ok, {<<r::size(256), s::size(256)>>, recovery_id}} =
      wallet
      |> Wallet.sign(hash)

    {recovery_id |> recovery_id_to_v(chain_id), r, s}
  end

  @doc """
  Returns a hash of a given transaction according to the
  formula defined in Eq.(214) and Eq.(215) of the Yellow Paper.

  Note: As per EIP-155 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md),
  we will append the chain-id and nil elements to the serialized transaction.

  ## Examples

      iex> LegacyTransaction.transaction_hash(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 5, init: <<1>>})
      <<127, 113, 209, 76, 19, 196, 2, 206, 19, 198, 240, 99, 184, 62, 8, 95, 9, 122, 135, 142, 51, 22, 61, 97, 70, 206, 206, 39, 121, 54, 83, 27>>

      iex> LegacyTransaction.transaction_hash(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<1>>, value: 5, data: <<1>>})
      <<225, 195, 128, 181, 3, 211, 32, 231, 34, 10, 166, 198, 153, 71, 210, 118, 51, 117, 22, 242, 87, 212, 229, 37, 71, 226, 150, 160, 50, 203, 127, 180>>

      iex> LegacyTransaction.transaction_hash(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<1>>, value: 5, data: <<1>>}, 1)
      <<132, 79, 28, 4, 212, 58, 235, 38, 66, 211, 167, 102, 36, 58, 229, 88, 238, 251, 153, 23, 121, 163, 212, 64, 83, 111, 200, 206, 54, 43, 112, 53>>

  """
  @spec transaction_hash(__MODULE__.t(), integer() | nil) :: BitHelper.keccak_hash()
  def transaction_hash(trx, chain_id \\ nil),
    do:
      trx
      |> serialize(false)
      # See EIP-155
      |> Kernel.++(if chain_id, do: [chain_id |> :binary.encode_unsigned(), <<>>, <<>>], else: [])
      |> rlp_encode()
      |> TTEth.keccak()

  @doc """
  Takes a given transaction and returns a version signed
  with the given private key. This is defined in Eq.(216) and
  Eq.(217) of the Yellow Paper.

  ## Examples

      iex> wallet = TTEth.Wallet.from_private_key(_private_key = <<1::256>>)
      iex> LegacyTransaction.sign_transaction(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 5, init: <<1>>}, wallet)
      %LegacyTransaction{data: <<>>, gas_limit: 7, gas_price: 6, init: <<1>>, nonce: 5, r: 97037709922803580267279977200525583527127616719646548867384185721164615918250, s: 31446571475787755537574189222065166628755695553801403547291726929250860527755, to: "", v: 27, value: 5}

      iex> wallet = TTEth.Wallet.from_private_key(_private_key = <<1::256>>)
      iex> LegacyTransaction.sign_transaction(%LegacyTransaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 5, init: <<1>>}, wallet, 1)
      %LegacyTransaction{data: <<>>, gas_limit: 7, gas_price: 6, init: <<1>>, nonce: 5, r: 25739987953128435966549144317523422635562973654702886626580606913510283002553, s: 41423569377768420285000144846773344478964141018753766296386430811329935846420, to: "", v: 38, value: 5}

  """
  @spec sign_transaction(__MODULE__.t(), Wallet.t(), integer() | nil) :: __MODULE__.t()
  def sign_transaction(trx, %Wallet{} = wallet, chain_id \\ nil) do
    {v, r, s} =
      trx
      |> transaction_hash(chain_id)
      |> sign_hash(wallet, chain_id)

    %{trx | v: v, r: r, s: s}
  end

  ## Private.

  defp recovery_id_to_v(recovery_id, _chain_id = nil),
    do: @base_v + recovery_id

  defp recovery_id_to_v(recovery_id, chain_id) when is_integer(chain_id),
    do: chain_id * 2 + @base_v_eip_155 + recovery_id
end
