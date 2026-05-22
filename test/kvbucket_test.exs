defmodule KvBucketTest do
  use ExUnit.Case, async: true
  doctest KvBucket
  import KvBucket

  test "starts a kvb" do
    assert start() == :ok
  end

  test "stops a kvb" do
    assert stop() == :ok
  end
end
