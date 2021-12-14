defmodule EV.EctoTypes.AtomTest do
  use EV.TestCase, async: true

  describe "type/0" do
    test "should return `:string`" do
      assert EV.EctoTypes.Atom.type() == :string
    end
  end

  describe "cast/1" do
    test "given an atom should pass it through" do
      assert EV.EctoTypes.Atom.cast(:some_atom) == {:ok, :some_atom}
    end

    test "given a string should cast it to atom" do
      assert EV.EctoTypes.Atom.cast("some_string") == {:ok, :some_string}
    end

    test "given an incompatible data type should return an error" do
      assert EV.EctoTypes.Atom.cast(1) == :error
    end
  end

  describe "load/1" do
    test "given a string should cast it to atom" do
      assert EV.EctoTypes.Atom.load("some_string") == {:ok, :some_string}
    end

    test "given an incompatible data type should return an error" do
      assert EV.EctoTypes.Atom.load(1) == :error
    end
  end

  describe "dump/1" do
    test "given an atom should cast it to string" do
      assert EV.EctoTypes.Atom.dump(:some_atom) == {:ok, "some_atom"}
    end

    test "given an incompatible data type should return an error" do
      assert EV.EctoTypes.Atom.dump(1) == :error
    end
  end
end
