defmodule KvBucketTest do
  use ExUnit.Case, async: true
  doctest KvBucket
  import KvBucket

  test "starts a kvb" do
    assert KvBucket.start() == :id
  end
end
