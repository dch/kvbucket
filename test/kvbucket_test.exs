defmodule KvBucketTest do
  use ExUnit.Case, async: false
  doctest KvBucket
  import Plug.Test
  import Plug.Conn
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

  test "Deleting an existing value works" do
    put("test", :a)
    assert get("test") == {:ok, :a}

    assert delete("test") == :ok
    assert get("test") == {:error, :not_found}
  end

  test "Deleting an existing value with return set to true returns the value as a tuple" do
    put("test_b", :a)
    assert get("test_b") == {:ok, :a}

    assert delete("test_b", true) == {:ok, :a}
    assert get("test_b") == {:error, :not_found}
  end

  describe "HTTP:" do
    @opts KvBucket.Router.init([])

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

      conn = conn(:put, "/#{key}", %{"value" => value})
      conn = KvBucket.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      conn = conn(:get, "/#{key}")
      conn = KvBucket.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      assert Jason.decode!(conn.resp_body) == value
    end

    test "delete '/test_delete' deletes key and returns the deleted value" do
      key = "test_delete"
      value = "test"

      conn = conn(:put, "/#{key}", %{"value" => value})
      conn = KvBucket.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      conn = conn(:get, "/#{key}")
      conn = KvBucket.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      conn = conn(:delete, "/#{key}")
      conn = KvBucket.Router.call(conn, @opts)

      assert conn.state == :sent
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
      conn = conn(:get, "idontexist?default=idoexist")
      conn = KvBucket.Router.call(conn, @opts)
      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == "idoexist"
    end
  end
end
