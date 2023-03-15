defmodule EmlTest do
  use ExUnit.Case
  doctest Eml

  test "greets the world" do
    assert Eml.hello() == :world
  end
end
