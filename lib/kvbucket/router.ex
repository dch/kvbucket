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

  def init(opts), do: opts

  # https://plug.hexdocs.pm/Plug.Conn.html#assign/3
  def call(conn, opts) do
    conn
    |> assign(:bucket, opts[:bucket])
    |> super(opts)
  end

  get "/" do
    send_resp(conn, 200, "hi")
  end

  get "/:key" do
    {status, response_body} =
      handle_get(conn.assigns.bucket, key, conn.query_params["default"])

    send_resp(conn, status, response_body)
  end

  def handle_get(bucket, key, default) do
    result =
      case default do
        nil -> KvBucket.get(bucket, key)
        default -> KvBucket.get(bucket, key, default)
      end

    case result do
      {:ok, value} ->
        {200, Jason.encode!(value)}

      {:error, :not_found} ->
        {404, "Key could not be found"}

      {:error, reason} ->
        {404, inspect(reason)}
    end
  end

  put "/:key" do
    case conn.body_params do
      %{"value" => value} ->
        case KvBucket.put(conn.assigns.bucket, key, value) do
          :ok ->
            send_resp(conn, 200, "Added value `#{value}` to key `#{key}`.")
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

  delete "/:key" do
    case KvBucket.delete(conn.assigns.bucket, key, true) do
      {:ok, value} -> send_resp(conn, 200, Jason.encode!(value))
      {:error, :not_found} -> send_resp(conn, 404, "Key was not found.")
      {:error, reason} -> send_resp(conn, 404, inspect(reason))
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
