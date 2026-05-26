defmodule KvBucket.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: KvBucket.Worker.start_link(arg)
      # {KvBucket.Worker, arg}
      {Bandit, plug: KvBucket.Router, port: 4000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    KvBucket.start()
    opts = [strategy: :one_for_one, name: KvBucket.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
