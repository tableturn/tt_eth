defmodule TTEth.UnmockedCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  import Hammox, only: [stub_with: 2]

  setup _tags do
    TTEth.all_mocks()
    |> Enum.each(&stub_with(&1.mock, &1.impl))
  end
end
