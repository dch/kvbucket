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
    GenServer.start_link(__MODULE__, %{store: store, cluster_name: nil})
  end

  @spec init(any()) :: {:ok, any()}
  def init(state = %{store: store}) do
    {:ok, cluster_name} = :khepri_cluster.start(store)

    case :khepri_cluster.is_store_running(cluster_name) do
      true -> :ok
      false -> :khepri_cluster.wait_for_leader(cluster_name, 3_000)
    end

    {:ok, %{state | cluster_name: cluster_name}}
  end

  def stop do
    :khepri = :khepri_cluster.get_default_store_id()

    case :khepri_cluster.stop(:khepri) do
      :ok -> :ok
      {:error, {:khepri, :not_a_khepri_store, %{}}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def put(bucket, key, value),
    do: GenServer.call(bucket, {:put, key, value})

  def get(bucket, key),
    do: GenServer.call(bucket, {:get, key})

  @spec get(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any(), any()) :: any()
  def get(bucket, key, default),
    do: GenServer.call(bucket, {:get, key, default})

  def delete(bucket, key, return \\ false),
    do: GenServer.call(bucket, {:delete, key, return})

  def handle_call({:put, key, value}, _from, state) do
    {:reply, handle_put(key, value), state}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, handle_get(key), state}
  end

  def handle_call({:get, key, default}, _from, state) do
    {:reply, handle_get(key, default), state}
  end

  def handle_call({:delete, key, return}, _from, state) do
    {:reply, handle_delete(key, return), state}
  end

  defp handle_get(key) do
    case :khepri.get(key) do
      {:ok, _} = ok -> ok
      {:error, {:khepri, :node_not_found, %{}}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_get(key, default) do
    case handle_get(key) do
      {:error, :not_found} ->
        {:ok, default}

      resp ->
        resp
    end
  end

  defp handle_delete(key, return) do
    # :khepri.delete returns :ok even if the value doesnt exist
    # so we use our get function
    # for user transparency
    case handle_get(key) do
      {:ok, value} ->
        :khepri.delete(key)
        if return, do: {:ok, value}, else: :ok

      error ->
        error
    end
  end

  defp handle_put(key, value), do: :khepri.put(key, value)
end
