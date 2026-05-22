defmodule KvBucket do
  @moduledoc """
  Documentation for `KvBucket`.
  """

  @doc """
  Start KvBucket

  ## Examples

      iex> KvBucket.start()
      :ok

  """

  @cluster "anubis"

  @spec start() :: :ok
  def start do
    {:ok, :khepri} = :khepri_cluster.start(@cluster)
    :ok
  end
  end
end
