defmodule KvBucket.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "hi")
  end

  get _ do
    send_resp(conn, 404, "Not found")
  end
end
