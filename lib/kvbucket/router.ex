defmodule KvBucket.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get("/") do
    send_resp(conn, 200, "hi")
  end

  get "/get/:key" do
    default = conn.params["default"] || nil

    result =
      case default do
        nil -> KvBucket.get(key)
        default -> KvBucket.get(key, default)
      end

    case result do
      {:ok, value} ->
        send_resp(conn, 200, Jason.encode!(value))

      # Im sure these two can be combined into one
      {:error, {:khepri, :node_not_found, %{}}} ->
        send_resp(conn, 404, "Key was not found")

      {:error, :not_found} ->
        send_resp(conn, 404, "Key was not found")

      {:error, reason} ->
        send_resp(conn, 500, inspect(reason))
    end
  end

  put "/put" do
    case conn.body_params do
      %{"key" => key, "value" => value} ->
        case KvBucket.put(key, value) do
          :ok -> send_resp(conn, 200, "Added value `#{value}` to key `#{key}`.")
        end

      # change status code later
      _ ->
        send_resp(conn, 400, """
        Wrong format! Please use the following:
        {
          "key": <key>,
          "value": <value>
        }
        """)
    end
  end

  delete "/delete" do
    case conn.body_params do
      %{"key" => key} ->
        case KvBucket.delete(key, true) do
          {:ok, value} -> send_resp(conn, 200, Jason.encode!(value))
          {:error, :not_found} -> send_resp(conn, 404, "Key was not found.")
          {:error, reason} -> send_resp(conn, 404, reason)
        end

      _ ->
        send_resp(conn, 400, """
        Wrong format! Please use the following:
        {
          "key": <key>,
          "value": <value>
        }
        """)
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  # conn.body_params = body
end
