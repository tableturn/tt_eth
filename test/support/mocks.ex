import Hammox, only: [defmock: 2]

TTEth.all_mocks()
|> Enum.map(&defmock(&1.mock, for: &1.behaviour))
