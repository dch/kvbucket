defmodule Kvbucket.MixProject do
  use Mix.Project

  def project do
    [
      app: :kvbucket,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Kvbucket.Application, []}
    ]
  end

  defp deps do
    [
      {:khepri, "~> 0.18"},
    ]
  end
end
