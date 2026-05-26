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

    case KvBucket.get(key, default) do
      {:ok, value} ->
        send_resp(conn, 200, Jason.encode!(value))

      {:error, {:khepri, :node_not_found, %{}}} ->
        send_resp(conn, 404, "Key was not found")

      {:error, _reason} ->
        send_resp(conn, 404, "An unknown error occured.")
    end
  end

  put "/put" do
    IO.inspect(conn.body_params)
    send_resp(conn, 200, "Success")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  # conn.body_params = body
end
