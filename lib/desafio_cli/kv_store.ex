defmodule DesafioCli.KVStore do
  use GenServer

  # Public API
  def start_link(_, dets_file \\ :kvstore_dets) do
    GenServer.start_link(__MODULE__, %{dets_file: dets_file}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    case :dets.open_file(state.dets_file, type: :set) do
      {:ok, _} ->
        {:ok, Map.put(state, :transactions, [])}

      {:error, reason} ->
        {:stop, {:error, reason}}
    end
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def set(key, value)
      when is_binary(key) and (is_integer(value) or is_boolean(value) or is_binary(value)) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  def get(key) when is_binary(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def begin_transaction do
    GenServer.call(__MODULE__, :begin)
  end

  def rollback_transaction do
    GenServer.call(__MODULE__, :rollback)
  end

  def commit_transaction do
    GenServer.call(__MODULE__, :commit)
  end

  # GenServer calls

  @impl true
  def handle_call(:stop, _from, state) do
    :dets.close(state.dets_file)
    {:stop, :normal, :ok, state}
  end

  def handle_call({:set, key, value}, _from, state) do
    current_level = length(state[:transactions])

    case :dets.lookup(state.dets_file, key) do
      [] ->
        if current_level == 0 do
          :dets.insert(state.dets_file, {key, value})
          {:reply, {:FALSE, value}, state}
        else
          new_state =
            Map.update!(state, :transactions, fn [head | tail] ->
              [Map.put(head, key, value) | tail]
            end)

          {:reply, {:FALSE, value}, new_state}
        end

      [{_, _}] ->
        if current_level == 0 do
          :dets.insert(state.dets_file, {key, value})
          {:reply, {:TRUE, value}, state}
        else
          new_state =
            Map.update!(state, :transactions, fn [head | tail] ->
              [Map.put(head, key, value) | tail]
            end)

          {:reply, {:TRUE, value}, new_state}
        end
    end
  end

  def handle_call({:get, key}, _from, state) do
    case find_in_transactions(key, state[:transactions]) do
      {:ok, value} ->
        {:reply, value, state}

      :not_found ->
        case :dets.lookup(state.dets_file, key) do
          [] -> {:reply, :NIL, state}
          [{_, value}] -> {:reply, value, state}
        end
    end
  end

  def handle_call(:begin, _from, state) do
    new_transactions = [Map.new() | state[:transactions]]
    {:reply, length(new_transactions), Map.put(state, :transactions, new_transactions)}
  end

  def handle_call(:rollback, _from, state) do
    case state[:transactions] do
      [] ->
        {:reply, {:error, "No transaction"}, state}

      [_current | rest] ->
        {:reply, length(rest), Map.put(state, :transactions, rest)}
    end
  end

  def handle_call(:commit, _from, state) do
    case state[:transactions] do
      [] ->
        {:reply, {:error, "No transaction"}, state}

      [current | rest] ->
        Enum.each(current, fn {key, value} -> :dets.insert(state.dets_file, {key, value}) end)
        {:reply, length(rest), Map.put(state, :transactions, rest)}
    end
  end

  defp find_in_transactions(key, transactions) do
    transactions
    |> Enum.find_value(:not_found, fn transaction ->
      Map.get(transaction, key, :not_found)
    end)
    |> case do
      :not_found -> :not_found
      value -> {:ok, value}
    end
  end
end
