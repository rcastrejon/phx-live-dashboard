defmodule PhxApp.Dashboard.Room do
  use GenServer, restart: :transient
  alias PhxApp.Dashboard
  alias Phoenix.PubSub

  @registry :dashboard_registry
  @pubsub PhxApp.PubSub
  @topic "dashboard"

  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(name))
  end

  def join(name) do
    case Registry.lookup(@registry, name) do
      [{pid, _}] ->
        GenServer.call(pid, {:join, self()})

      [] ->
        {:ok, pid} = Dashboard.RoomSupervisor.start_room(name)
        GenServer.call(pid, {:join, self()})
    end
  end

  def leave(name) do
    case Registry.lookup(@registry, name) do
      [{pid, _}] ->
        GenServer.cast(pid, {:leave, self()})

      [] ->
        :ok
    end
  end

  def insert_name(room_name, name, position \\ 0) do
    names = GenServer.call(via_tuple(room_name), {:insert_name, name, position})
    PubSub.broadcast(@pubsub, @topic, {:update_names, names})
  end

  def remove_name(room_name, position) do
    names = GenServer.call(via_tuple(room_name), {:remove_name, position})
    PubSub.broadcast(@pubsub, @topic, {:update_names, names})
  end

  def change_name_position(room_name, from_position, to_position) do
    names =
      GenServer.call(via_tuple(room_name), {:change_name_position, from_position, to_position})

    PubSub.broadcast(@pubsub, @topic, {:update_names, names})
  end

  defp via_tuple(name) do
    {:via, Registry, {@registry, name}}
  end

  # CALLBACKS

  def init([]) do
    {:ok, %{clients: [], names: []}}
  end

  def handle_cast({:leave, _pid}, %{clients: [_first]} = state) do
    {:stop, :normal, state}
  end

  def handle_cast({:leave, client_pid}, %{clients: clients} = state) do
    {:noreply, %{state | clients: List.delete(clients, client_pid)}}
  end

  def handle_call({:join, client_pid}, _from, %{clients: clients, names: names} = state) do
    clients =
      MapSet.new([client_pid | clients])
      |> MapSet.to_list()

    {:reply, names, %{state | clients: clients}}
  end

  def handle_call({:insert_name, new_name, position}, _from, %{names: names} = state) do
    names = cb_insert_name(names, new_name, position)
    {:reply, names, %{state | names: names}}
  end

  def handle_call({:remove_name, position}, _from, %{names: names} = state) do
    names = cb_remove_name(names, position)
    {:reply, names, %{state | names: names}}
  end

  def handle_call(
        {:change_name_position, from_position, to_position},
        _from,
        %{names: names} = state
      ) do
    names = cb_change_name_position(names, from_position, to_position)
    {:reply, names, %{state | names: names}}
  end

  defp cb_insert_name(list, new_name, 0) do
    case List.last(list) do
      nil ->
        [{1, new_name}]

      {pos, _} ->
        list ++ [{pos + 1, new_name}]
    end
  end

  defp cb_insert_name(list, new_name, position) when position > 0 do
    case List.keyfind(list, position, 0) do
      nil ->
        List.insert_at(list, position - 1, {position, new_name})

      {position, _} ->
        Enum.map(list, &if(elem(&1, 0) >= position, do: {elem(&1, 0) + 1, elem(&1, 1)}, else: &1))
        |> List.insert_at(position - 1, {position, new_name})
    end
  end

  defp cb_remove_name(list, position) do
    case List.keyfind(list, position, 0) do
      nil ->
        list

      {position, _} ->
        Enum.map(list, &if(elem(&1, 0) > position, do: {elem(&1, 0) - 1, elem(&1, 1)}, else: &1))
        |> List.delete_at(position - 1)
    end
  end

  defp cb_change_name_position(list, current_position, new_position) do
    case List.keyfind!(list, current_position, 0) do
      {current_position, name} ->
        list
        |> cb_remove_name(current_position)
        |> cb_insert_name(name, new_position)
    end
  end
end
