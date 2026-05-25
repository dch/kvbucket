defmodule KvBucketTest do
  use ExUnit.Case, async: true
  doctest KvBucket
  import KvBucket

  setup_all do
    on_exit(fn -> tear_down() end)
    :ok == clean_working_dir()
    start()
  end

  defp clean_working_dir() do
    File.rm_rf!("anubis")
    :ok
  end

  defp tear_down do
    :ok == stop()
    clean_working_dir()
  end

  test "get/1 returns not found if value doesn't exist" do
    assert get("test") == {:error, :not_found}
  end
end
