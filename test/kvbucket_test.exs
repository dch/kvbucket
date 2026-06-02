defmodule KvBucketTest do
  use ExUnit.Case, async: false
  doctest KvBucket

  import Plug.Test
  import Plug.Conn
  import KvBucket

  setup_all do
    on_exit(fn -> tear_down() end)
    :ok = clean_working_dir()

    {:ok, bucket} = start_link(store: "test")

    {:ok, bucket: bucket}
  end

  defp clean_working_dir do
    File.rm_rf!("anubis")
    :ok
  end

  defp tear_down do
    stop()
    clean_working_dir()
  end

  test "get/1 returns not found if value doesn't exist", %{bucket: bucket} do
    assert get(bucket, "test") == {:error, :not_found}
  end

  test "Deleting an existing value works", %{bucket: bucket} do
    put(bucket, "test", :a)
    assert get(bucket, "test") == {:ok, :a}

    assert delete(bucket, "test") == :ok
    assert get(bucket, "test") == {:error, :not_found}
  end

  test "Deleting an existing value with return set to true returns the value as a tuple", %{
    bucket: bucket
  } do
    put(bucket, "test_b", :a)
    assert get(bucket, "test_b") == {:ok, :a}

    assert delete(bucket, "test_b", true) == {:ok, :a}
    assert get(bucket, "test_b") == {:error, :not_found}
  end

  describe "HTTP:" do
    defp start_http_bucket do
      {:ok, bucket} = start_link(store: "http_test")
      bucket
    end

    @opts KvBucket.Router.init(bucket: start_http_bucket())

    test "get '/' returns 'hi'" do
      conn = conn(:get, "/")

      conn = KvBucket.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "hi"
    end

    test "put '/test_put' creates new entry" do
      key = "test_put"
      value = "test"

      conn =
        conn(:put, "/#{key}", %{"value" => value})
        |> KvBucket.Router.call(@opts)

      assert conn.status == 200

      conn =
        conn(:get, "/#{key}")
        |> KvBucket.Router.call(@opts)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == value
    end

    test "delete '/test_delete' deletes key and returns the deleted value" do
      key = "test_delete"
      value = "test"

      conn =
        conn(:put, "/#{key}", %{"value" => value})
        |> KvBucket.Router.call(@opts)

      conn =
        conn(:delete, "/#{key}")
        |> KvBucket.Router.call(@opts)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == value
    end

    test "get '/idontexist' returns 404 for missing key" do
      conn = conn(:get, "/idontexist")
      conn = KvBucket.Router.call(conn, @opts)
      assert conn.status == 404
    end

    test "delete '/idontexist' returns 404 for missing key" do
      conn = conn(:delete, "/idontexist", %{"key" => "idontexist"})
      conn = KvBucket.Router.call(conn, @opts)
      assert conn.status == 404
    end

    test "put '/wrong' returns 400 for missing key/value" do
      conn = conn(:put, "/wrong", %{"wrong" => "format"})
      conn = KvBucket.Router.call(conn, @opts)
      assert conn.status == 400
    end

    test "get /idontexist?default=idoexist returns default value" do
      conn = conn(:get, "/idontexist?default=idoexist")
      conn = KvBucket.Router.call(conn, @opts)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == "idoexist"
    end
  end

  test "multiple buckets are isolated" do
    {:ok, b1} = start_link(store: "t1")
    {:ok, b2} = start_link(store: "t2")

    put(b1, "x", 1)
    put(b2, "x", 2)

    assert get(b1, "x") == {:ok, 1}
    assert get(b2, "x") == {:ok, 2}
  end
end
