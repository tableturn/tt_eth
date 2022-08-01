defmodule TTEth.Type do
  @moduledoc """
  In the database, ethereum related stuff is stored as normalized binaries. This ecto abstract
  type allows to quickly compose new ethereum types that must conform to a certain size.
  """

  defmacro __using__(opts) do
    byte_size = opts |> Keyword.fetch!(:size)
    hex_size = byte_size * 2

    quote do
      use Ecto.Type
      alias ExthCrypto.Key

      @type t :: binary

      @byte_size unquote(byte_size)
      @hex_size unquote(hex_size)

      @spec data_size() :: unquote(byte_size)
      def data_size(),
        do: @byte_size

      @spec hex_data_size() :: unquote(hex_size)
      def hex_data_size(),
        do: @hex_size

      @spec type() :: :binary
      def type(),
        do: :binary

      @spec cast(any) :: {:ok, String.t()} | :error
      def cast(val) do
        val
        |> to_human()
        |> case do
          {:ok, _} = ret -> ret
          {:error, _} -> :error
        end
      end

      @spec load(any) :: {:ok, String.t()} | :error
      def load(val) do
        val
        |> to_human()
        |> case do
          {:ok, _} = ret -> ret
          {:error, _} -> :error
        end
      end

      @spec dump(any) :: {:ok, binary} | :error
      def dump(val) do
        val
        |> from_human()
        |> case do
          {:ok, _} = ret -> ret
          {:error, _} -> :error
        end
      end

      @spec from_human(any) :: {:ok, binary} | {:error, :invalid_input | :decoding_error}
      # Cast from a binary format without any prefix. This means that the passed
      # value is exactly the right size.
      def from_human(<<val::binary-size(unquote(byte_size))>>),
        do: {:ok, val}

      # Casts from a human-readable value, prefixed with "0x". It implies
      # that the passed value is two extra bytes more than the declared
      # `size` option.
      def from_human(<<"0x"::binary, val::binary-size(unquote(hex_size))>>) do
        val
        |> Base.decode16(case: :mixed)
        |> case do
          {:ok, _} = ret -> ret
          :error -> {:decoding_error}
        end
      end

      # Casts from a DER-prefixed value directly in binary format. It implies
      # that the passed value is one extra byte more than the declared
      # `size` option.
      def from_human(<<0x04, val::binary-size(unquote(byte_size))>>),
        do: {:ok, val}

      def from_human(_),
        do: {:error, :invalid_input}

      @spec from_human!(binary) :: binary
      def from_human!(val) do
        {:ok, val} = from_human(val)
        val
      end

      @doc "Converts back to a human-readable format."
      @spec to_human(any) :: {:ok, <<_::16, _::_*8>>} | {:error, :invalid_input}
      def to_human(val) do
        val
        |> from_human()
        |> case do
          {:ok, val} -> {:ok, postprocess_human("0x" <> Base.encode16(val, case: :lower))}
          {:error, _} = ret -> ret
        end
      end

      @spec to_human!(any) :: <<_::16, _::_*8>>
      def to_human!(val) do
        {:ok, val} = to_human(val)
        val
      end

      @spec postprocess_human(<<_::16, _::_*8>>) :: <<_::16, _::_*8>>
      def postprocess_human(val),
        do: val

      defoverridable postprocess_human: 1
    end
  end
end
