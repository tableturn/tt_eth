defmodule TTEth.ContractTest do
  use TTEth.Case, async: true
  alias TTEth.{Contract, TestToken}

  @address "0xb24ff6887BC32F900Fe820d97570F36D63E9d000"
  @someone_address "0xe689a751a95286d7c101451b8f02743017c0e62e"

  @total_supply_args "18160ddd"
  @total_supply_return "0x0000000000000000000000000000000000000000000000000000010501672080"

  @balance_of_args "70a08231000000000000000000000000e689a751a95286d7c101451b8f02743017c0e62e"
  @balance_of_return "70a08231000000000000000000000000e689a751a95286d7c101451b8f02743017c0e62e"

  describe "call/2+1" do
    test "delegates properly without encodable arguments" do
      ChainClientMock
      |> expect(:eth_call, fn @address, @total_supply_args ->
        {:ok, @total_supply_return}
      end)

      @address |> TestToken.call(:total_supply)
    end

    test "delegates properly with encodable arguments" do
      ChainClientMock
      |> expect(:eth_call, fn @address, @balance_of_args ->
        {:ok, @balance_of_return}
      end)

      @address
      |> TestToken.call(:balance_of, [@someone_address |> TTEth.Type.Address.from_human!()])
    end
  end

  describe "event_selector/1" do
    test "returns the correct function selector" do
      :transfer
      |> TestToken.event_selector()
      |> assert_equal(%ABI.FunctionSelector{
        function: "Transfer",
        input_names: ["from", "to", "value"],
        inputs_indexed: [true, true, false],
        method_id: <<221, 242, 82, 173>>,
        returns: [],
        type: :event,
        types: [:address, :address, {:uint, 256}]
      })
    end
  end

  describe "topic_for/1" do
    test "returns a topic for a given event" do
      TestToken.topic_for(:issuance)
      |> assert_match(["0xff28963fd3b5063e201cc16e9a4b9a952897d716091d5d5956454ff81929ab80"])
    end
  end

  describe "atomize/1" do
    for {subject, expected} <- [
          {"approve", :approve},
          {"transferFrom", :transfer_from},
          {"Transfer", :transfer},
          {"ERR_OWNER_SAME_AS_RECIPIENT", :err_owner_same_as_recipient}
        ] do
      test "takes `#{subject}` and returns `#{inspect(expected)}`" do
        Contract.atomize(unquote(subject))
        |> assert_match(unquote(expected))
      end
    end
  end
end
