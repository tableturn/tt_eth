defmodule TTEth.Type.AddressTest do
  use ExUnit.Case
  alias TTEth.Type.Address
  doctest Address, import: true

  @human_address "0xC9c4496508E92A9FCB0Ffc8Cb6363f910C7E8AE3"
  @bin_address <<201, 196, 73, 101, 8, 233, 42, 159, 203, 15, 252, 140, 182, 54, 63, 145, 12, 126,
                 138, 227>>
  @human_public_key "0xf404e52676944e10ff3a42e67e7fdd64eddade9099e8dad5d156e1938543360e93bc673bd7ca4d50ddd585f72d6044e87a7602681fad69673ecc5a6311b387a3"
  @bin_public_key <<4, 244, 4, 229, 38, 118, 148, 78, 16, 255, 58, 66, 230, 126, 127, 221, 100,
                    237, 218, 222, 144, 153, 232, 218, 213, 209, 86, 225, 147, 133, 67, 54, 14,
                    147, 188, 103, 59, 215, 202, 77, 80, 221, 213, 133, 247, 45, 96, 68, 232, 122,
                    118, 2, 104, 31, 173, 105, 103, 62, 204, 90, 99, 17, 179, 135, 163>>

  describe "from_public_key/1" do
    test "accepts keys in binary format" do
      assert {:ok, @bin_address} = @bin_public_key |> Address.from_public_key()
    end

    test "accepts keys in readable format" do
      assert {:ok, @bin_address} = @human_public_key |> Address.from_public_key()
    end

    test "returns the :error code when the key is invalid" do
      assert {:error, :invalid_input} = @human_address |> Address.from_public_key()
    end
  end

  describe "type/0" do
    test "uses :binary as storage type" do
      assert Address.type() == :binary
    end
  end

  describe "cast/1 and load/1" do
    test "succeeds with a readable address" do
      assert {:ok, @human_address} == @human_address |> Address.cast()
      assert {:ok, @human_address} == @human_address |> Address.load()
    end

    test "succeeds with a binary address" do
      assert {:ok, @human_address} == @bin_address |> Address.cast()
      assert {:ok, @human_address} == @bin_address |> Address.load()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @human_address} == <<0x04, @bin_address>> |> Address.cast()
      assert {:ok, @human_address} == <<0x04, @bin_address>> |> Address.load()
    end

    test "fails properly with the :error return code" do
      assert :error == <<0x00, @bin_address>> |> Address.cast()
      assert :error == <<0x00, @bin_address>> |> Address.load()
    end
  end

  describe "dump/1" do
    test "succeeds with a readable address" do
      assert {:ok, @bin_address} == @human_address |> Address.dump()
    end

    test "succeeds with a binary address" do
      assert {:ok, @bin_address} == @bin_address |> Address.dump()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @bin_address} == <<0x04, @bin_address>> |> Address.dump()
    end

    test "fails properly with the :error return code" do
      assert :error == <<0x00, @bin_address>> |> Address.dump()
    end
  end

  describe "to_human/1" do
    test "succeeds with a readable address" do
      assert {:ok, @human_address} == @human_address |> Address.to_human()
    end

    test "succeeds with a binary address" do
      assert {:ok, @human_address} == @bin_address |> Address.to_human()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @human_address} == <<0x04, @bin_address>> |> Address.to_human()
    end

    test "fails properly with the :error return code" do
      assert {:error, :invalid_input} == <<0x00, @bin_address>> |> Address.to_human()
    end
  end

  describe "from_human/1" do
    test "succeeds with a readable address" do
      assert {:ok, @bin_address} == @human_address |> Address.from_human()
    end

    test "succeeds with a binary address" do
      assert {:ok, @bin_address} == @bin_address |> Address.from_human()
    end

    test "succeeds with a prefixed binary address" do
      assert {:ok, @bin_address} == <<0x04, @bin_address>> |> Address.from_human()
    end

    test "fails properly with the :error return code" do
      assert {:error, :invalid_input} == <<0x00, @bin_address>> |> Address.from_human()
    end
  end
end
