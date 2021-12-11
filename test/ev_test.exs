defmodule EVTest do
  use ExUnit.Case
  doctest EV

  test "greets the world" do
    assert EV.hello() == :world
  end
end
