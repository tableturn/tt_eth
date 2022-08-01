ExUnit.start()

TTEth.all_mocks()
|> Enum.map(&Application.put_env(:tt_eth, &1.name, &1.mock))
