defmodule EV.EctoTypes.JSONTest do
  use EV.TestCase, async: true

  describe "type/0" do
    test "should return `:jsonb`" do
      assert EV.EctoTypes.JSON.type() == :jsonb
    end
  end

  describe "cast/1" do
    test "given a map should stringify its keys" do
      assert EV.EctoTypes.JSON.cast(%{a: 1, b: 2}) == {:ok, %{"a" => 1, "b" => 2}}
    end

    test "given a list of maps should stringify their keys" do
      assert EV.EctoTypes.JSON.cast([%{a: 1, b: 2}, %{c: 3, d: 4}]) ==
               {:ok, [%{"a" => 1, "b" => 2}, %{"c" => 3, "d" => 4}]}
    end
  end

  describe "load/1" do
    test "given a string should cast it to atom" do
      assert EV.EctoTypes.JSON.load("{\"a\":1,\"b\":2}") ==
               {:ok, %{"a" => 1, "b" => 2}}
    end

    test "given an incompatible data type should return an error" do
      assert EV.EctoTypes.JSON.load(1) == :error
    end
  end

  describe "dump/1" do
    test "given a map should cast it to string" do
      assert EV.EctoTypes.JSON.dump(%{"a" => 1, "b" => 2}) ==
               {:ok, "{\"a\":1,\"b\":2}"}
    end
  end
end
