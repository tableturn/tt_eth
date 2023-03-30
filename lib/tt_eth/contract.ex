defmodule TTEth.Contract do
  @moduledoc false
  alias TTEth.Type.Address
  import TTEth, only: [chain_client: 0, keccak: 1]

  defmacro __using__(opts) do
    abi_file = opts |> Keyword.fetch!(:abi_file)

    quote location: :keep do
      @external_resource unquote(abi_file)
      alias TTEth.Contract

      parsed_abi =
        unquote(abi_file)
        |> File.read!()
        |> Jason.decode!()
        |> ABI.parse_specification(include_events?: true)

      @abi parsed_abi
           |> Enum.reduce(%{}, fn sel, acc ->
             Map.put(acc, sel.function |> Contract.atomize(), sel)
           end)

      @event_selectors parsed_abi
                       |> Enum.filter(&match?(%{type: :event}, &1))
                       |> Enum.reduce(%{}, fn sel, acc ->
                         acc |> Map.put(Contract.atomize(sel.function), sel)
                       end)

      @events @event_selectors
              |> Enum.reduce(%{}, fn {event_kind, sel}, acc ->
                Map.put(acc, event_kind, sel |> Contract.build_event_topics())
              end)

      def call(contract_address, method, args \\ [], opts \\ []) do
        %{returns: return_abi} = abi = @abi[method]

        encoded_args =
          args
          |> ABI.TypeEncoder.encode(abi)
          |> Base.encode16(case: :lower)

        Contract.call(contract_address, encoded_args, return_abi, opts)
      end

      def event_selector(event_kind),
        do: @event_selectors[event_kind]

      def topic_for(event_kind),
        do: @events[event_kind].topic
    end
  end

  def call(contract_address, encoded_args, return_abi, opts \\ []) do
    with {_, {:ok, bytes}} <-
           {:call, chain_client().eth_call(contract_address, encoded_args, opts)},
         {_, decoded_bytes} <-
           {:decode_bytes, bytes |> String.slice(2..-1) |> Base.decode16!(case: :lower)},
         {_, decoded_values} <-
           {:decode_values, decoded_bytes |> ABI.TypeDecoder.decode_raw(return_abi)},
         {_, readable_values} <- {:humanize, decoded_values |> humanize_values(return_abi)} do
      {:ok, readable_values}
    end
  end

  def build_event_topics(sel) do
    method = ABI.FunctionSelector.encode(sel)
    %{method: method, topic: [encode_method(method)]}
  end

  def atomize(value),
    do: value |> Macro.underscore() |> String.to_atom()

  ## Private.

  defp encode_method(method),
    do: "0x" <> (method |> keccak() |> Base.encode16(case: :lower))

  defp humanize_values(values, abi) when is_tuple(values),
    do: humanize_values(Tuple.to_list(values), abi)

  defp humanize_values(values, abi) when is_tuple(abi),
    do: humanize_values(values, Tuple.to_list(abi))

  defp humanize_values(values, abi) do
    [values, List.wrap(abi)]
    |> Enum.zip()
    |> Enum.map(fn
      {val, :bool} -> val
      {val, :string} -> val
      {val, {:uint, _}} -> val
      {val, {:int, _}} -> val
      {val, {:bytes, _}} -> val
      {val, {:array, spec}} -> humanize_values(val, spec)
      {val, {:tuple, spec}} -> humanize_values(val, spec)
      {val, :address} -> Address.to_human!(val)
    end)
  end
end
