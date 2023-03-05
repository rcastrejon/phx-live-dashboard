defmodule PhxApp.Dashboard.RoomSupervisor do
  use DynamicSupervisor
  alias PhxApp.Dashboard

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_room(name) do
    DynamicSupervisor.start_child(__MODULE__, {Dashboard.Room, name})
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
