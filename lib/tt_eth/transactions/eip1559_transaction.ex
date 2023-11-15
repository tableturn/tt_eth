defmodule TTEth.Transactions.EIP1559Transaction do
  @moduledoc """
  Represents an EIP1559 transaction.

  SEE: https://eips.ethereum.org/EIPS/eip-1559
  """
  alias TTEth.BitHelper
  alias TTEth.Behaviours.Transaction
  import BitHelper, only: [encode_unsigned: 1]
  import TTEth, only: [signer_module: 0]

  @behaviour Transaction

  defstruct type: 2,
            nonce: 0,
            chain_id: 0,
            gas_limit: 0,
            max_fee_per_gas: 0,
            max_priority_fee_per_gas: 0,
            to: <<>>,
            value: 0,
            access_list: [],
            y_parity: 0,
            r: 0,
            s: 0,
            init: <<>>,
            data: <<>>

  # The transaction envelope version for an EIP-1559 transaction.
  # SEE: https://eips.ethereum.org/EIPS/eip-2718
  # SEE: https://eips.ethereum.org/EIPS/eip-1559
  @transaction_type 2

  @doc """
  Creates a new type 2 transaction that can be signed.
  """
  @impl Transaction
  def new("" <> to_address, abi_data, nonce, opts) when is_integer(nonce),
    do: %__MODULE__{
      type: @transaction_type,
      chain_id: opts[:chain_id],
      data: abi_data,
      gas_limit: opts |> Keyword.get(:gas_limit, 500_000),
      max_fee_per_gas: opts |> Keyword.get(:max_fee_per_gas, 500_000),
      max_priority_fee_per_gas: opts |> Keyword.get(:max_priority_fee_per_gas, 500_000),
      nonce: nonce,
      to: to_address,
      value: opts |> Keyword.get(:value, 0)
    }

  @doc """
  Take a transaction `trx` and build it into a signed transaction.

  This will return a binary which can then be base16 encoded etc.
  """
  @impl Transaction
  def build(%__MODULE__{} = trx, private_key),
    do:
      trx
      |> sign_transaction(private_key)
      |> serialize(_include_signature = true)
      |> rlp_encode()
      |> put_transaction_envelope(trx)

  @doc """
  Delegate to ExRLP to RLP encode values.
  """
  def rlp_encode(data),
    do: data |> ExRLP.encode()

  @doc """
  Encodes a transaction such that it can be RLP-encoded.
  """
  def serialize(%__MODULE__{} = trx, include_vrs \\ true),
    do:
      [
        trx.chain_id |> encode_unsigned(),
        trx.nonce |> encode_unsigned(),
        trx.max_priority_fee_per_gas |> encode_unsigned(),
        trx.max_fee_per_gas |> encode_unsigned(),
        trx.gas_limit |> encode_unsigned(),
        trx.to,
        trx.value |> encode_unsigned(),
        if(trx.to == <<>>, do: trx.init, else: trx.data),
        trx.access_list
      ]
      |> maybe_add_yrs(trx, include_vrs)

  @doc """
  Returns a ECDSA signature (v,r,s) for a given hashed value.
  """
  def sign_hash(hash, private_key) do
    {:ok, {<<r::size(256), s::size(256)>>, v}} =
      signer_module().sign_transaction(hash, private_key)

    {v, r, s}
  end

  @doc """
  Returns a hash of a given transaction.
  """
  def transaction_hash(%__MODULE__{} = trx),
    do:
      trx
      |> serialize(_include_signature = false)
      |> rlp_encode()
      |> put_transaction_envelope(trx)
      |> TTEth.keccak()

  @doc """
  Takes a given transaction and returns a version signed with the given private key.
  """
  def sign_transaction(%__MODULE__{} = trx, private_key) when is_binary(private_key) do
    {y_parity, r, s} =
      trx
      |> transaction_hash()
      |> sign_hash(private_key)

    %{trx | y_parity: y_parity, r: r, s: s}
  end

  @doc """
  Wraps the RLP encoded transaction in a transaction envelope.
  SEE: https://eips.ethereum.org/EIPS/eip-2718
  """
  def put_transaction_envelope(encoded, %__MODULE__{} = trx) when is_binary(encoded),
    do: <<trx.type>> <> encoded

  ## Private.

  # Optionally add the YRS values.
  defp maybe_add_yrs(base, %__MODULE__{} = trx, _include_vrs = true),
    do:
      base ++
        [
          trx.y_parity |> encode_unsigned(),
          trx.r |> encode_unsigned(),
          trx.s |> encode_unsigned()
        ]

  defp maybe_add_yrs(base, %__MODULE__{}, _dont_include_vrs), do: base
end
