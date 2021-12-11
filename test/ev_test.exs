defmodule EvTest do
  use ExUnit.Case
  doctest Ev

  test "greets the world" do
    assert Ev.hello() == :world
  end
end
