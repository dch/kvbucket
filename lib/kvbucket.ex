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
  @type key :: :khepri_path.unix_path()
  @type value :: any

  @cluster "anubis"

  @spec start() :: :ok
  def start do
    {:ok, :khepri} = :khepri_cluster.start(@cluster)
    true = :khepri_cluster.is_store_running(:khepri)
    :ok = :khepri_cluster.wait_for_leader(:khepri)
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

  @spec get(key()) :: {:ok, value()} | {:error, any()}
  def get(key) do
    case resp = :khepri.get(key) do
      {:ok, _} ->
        resp

      {:error, {:khepri, :node_not_found, %{}}} ->
        {:error, :not_found}

      {:error, _reason} ->
        resp
    end
  end

  def get(key, value) do
  end
end
