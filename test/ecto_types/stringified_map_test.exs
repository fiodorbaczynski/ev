defmodule EV.EctoTypes.StringifiedMapTest do
  use EV.TestCase, async: true

  describe "type/0" do
    test "should return `:jsonb`" do
      assert EV.EctoTypes.StringifiedMap.type() == :jsonb
    end
  end

  describe "cast/1" do
    test "given a map should stringify its keys" do
      assert EV.EctoTypes.StringifiedMap.cast(%{a: 1, b: 2}) == {:ok, %{"a" => 1, "b" => 2}}
    end

    test "given an incompatible data type should return an error" do
      assert EV.EctoTypes.StringifiedMap.cast(1) == :error
    end
  end

  describe "load/1" do
    test "given a string should cast it to atom" do
      assert EV.EctoTypes.StringifiedMap.load("{\"a\":1,\"b\":2}") ==
               {:ok, %{"a" => 1, "b" => 2}}
    end

    test "given an incompatible data type should return an error" do
      assert EV.EctoTypes.StringifiedMap.load(1) == :error
    end
  end

  describe "dump/1" do
    test "given a map should cast it to string" do
      assert EV.EctoTypes.StringifiedMap.dump(%{"a" => 1, "b" => 2}) ==
               {:ok, "{\"a\":1,\"b\":2}"}
    end

    test "given an incompatible data type should return an error" do
      assert EV.EctoTypes.StringifiedMap.dump(1) == :error
    end
  end
end
