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
  use GenServer

  @type key :: :khepri_path.unix_path()
  @type value :: any

  def start_link(store: store) do
    GenServer.start_link(__MODULE__, dbg(%{store: store, cluster_name: nil}), name: __MODULE__)
  end

  @spec init(any()) :: {:ok, any()}
  def init(state = %{store: store}) do
    {:ok, cluster_name} = :khepri_cluster.start(store)

    case :khepri_cluster.is_store_running(cluster_name) do
      true ->
        :ok

      false ->
        :ok = :khepri_cluster.wait_for_leader(cluster_name, 3_000)
    end

    {:ok, %{state | cluster_name: cluster_name}}
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
    case get(key) do
      {:error, :not_found} -> {:ok, value}
      resp -> resp
    end
  end

  @spec put(key(), value()) :: :ok | {:error, any()}
  def put(key, value), do: :khepri.put(key, value)

  @doc """
  Deletes the value provided if it exists in the bucket.
  If not, it returns an error
  You can provide an optional variable to return a tuple with the deleted value
  but only if it exists prior to deletion
  """
  @spec delete(key(), value()) :: :ok | {:error, any()}
  def delete(key, return \\ false) do
    # :khepri.delete returns :ok even if the value doesnt exist
    # so we use our get function
    # for user transparency
    case get(key) do
      {:ok, value} ->
        :khepri.delete(key)
        if return, do: {:ok, value}, else: :ok

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
