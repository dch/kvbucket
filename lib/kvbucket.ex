defmodule KvBucket do
  @moduledoc """
  Documentation for `KvBucket`.
  """

  @doc """
  Start KvBucket

  ## Examples

      iex> KvBucket.start()
      :ok
      iex> KvBucket.get("key", "default")
      {:ok, "default"}
      iex> KvBucket.put("key", "value")
      :ok
      iex> KvBucket.get("key")
      {:ok, "value"}

  """
  @type key :: :khepri_path.unix_path()
  @type value :: any

  @cluster "anubis"

  @spec start() :: :ok
  def start do
    {:ok, :khepri} = :khepri_cluster.start(@cluster)

    case :khepri_cluster.is_store_running(:khepri) do
      true ->
        :ok

      false ->
        :ok = :khepri_cluster.wait_for_leader(:khepri, 3_000)
    end
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

  @doc """
  Returns the value of a key in the bucket if it exists.
  If not, it returns an error tuple.
  """
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

  @doc """
  Returns the value of a key in the bucket if it exists.
  If not, it returns the default value provided.
  """
  @spec get(key(), value()) :: {:ok, value()} | {:error, any()}
  def get(key, value) do
    case resp = get(key) do
      {:error, :not_found} -> {:ok, value}
      resp -> resp
    end
  end

  @spec put(key(), value()) :: :ok | {:error, any()}
  def put(key, value), do: :khepri.put(key, value)
end
