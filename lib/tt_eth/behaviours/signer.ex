defmodule TTEth.Behaviours.Signer do
  @moduledoc """
  Defines a behaviour to encapsulate a signer.
  """

  @callback sign_transaction(transaction :: binary(), private_key :: binary()) ::
              {:ok, {r_s :: binary(), v :: non_neg_integer()}}
              | {:error, term()}
end
