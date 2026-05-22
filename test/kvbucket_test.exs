defmodule KvBucketTest do
  use ExUnit.Case
  # doctest KvBucket
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

  test "get/1 returns not found if value doesn't exist" do
    assert get("test") == {:error, :not_found}
  end

  test "stops a kvb" do
    assert stop() == :ok
  end
end
