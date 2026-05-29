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

  get "/:key" do
    {status, response_body} = handle_get(key, conn.query_params["default"])
    send_resp(conn, status, response_body)
  end

  @spec handle_get(String.t(), String.t() | nil) :: {integer(), String.t()}
  def handle_get(key, default) do
    result =
      case default do
        nil -> KvBucket.get(key)
        default -> KvBucket.get(key, default)
      end

    case result do
      {:ok, value} ->
        {200, Jason.encode!(value)}

      {:error, {:khepri, :node_not_found, %{}}} ->
        {404, "Key could not be found"}

      {:error, reason} ->
        {404, inspect(reason)}
    end
  end

  put "/:key" do
    case conn.body_params do
      %{"value" => value} ->
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

  delete "/:key" do
    case KvBucket.delete(key, true) do
      {:ok, value} -> send_resp(conn, 200, Jason.encode!(value))
      {:error, :not_found} -> send_resp(conn, 404, "Key was not found.")
      {:error, reason} -> send_resp(conn, 404, reason)
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  # conn.body_params = body
end
