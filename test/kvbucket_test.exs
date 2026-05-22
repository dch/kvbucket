defmodule KvbucketTest do
  use ExUnit.Case
  doctest Kvbucket

  test "greets the world" do
    assert Kvbucket.hello() == :world
  end
end
