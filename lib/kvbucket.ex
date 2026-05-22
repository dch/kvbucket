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

  @spec stop() :: :ok
  def stop do
    :khepri = :khepri_cluster.get_default_store_id()

    case :khepri_cluster.stop(:khepri) do
      :ok -> :ok
      {:error, {:khepri, :not_a_khepri_store, %{}}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
