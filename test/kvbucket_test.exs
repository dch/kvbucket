defmodule KvBucketTest do
  use ExUnit.Case, async: true
  doctest KvBucket
  import KvBucket

  setup_all do
    clean_working_dir()
  end

  defp clean_working_dir() do
    File.rm_rf!("anubis")
    :ok
  end

  test "starts a kvb" do
    assert start() == :ok
  end

  test "stops a kvb" do
    assert stop() == :ok
  end
end
