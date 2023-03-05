defmodule PhxAppWeb.DashboardLive do
  use PhxAppWeb, :live_view
  alias PhxApp.Dashboard.Room
  alias PhxAppWeb.Endpoint

  def mount(_params, _session, socket) do
    if connected?(socket) do
      names = Room.join("dashboard")
      Endpoint.subscribe("dashboard")
      {:ok, assign(socket, :names, names)}
    else
      {:ok, assign(socket, :names, [])}
    end
  end

  def terminate(_reason, _socket) do
    Endpoint.unsubscribe("dashboard")
    Room.leave("dashboard")
  end

  def handle_info({:update_names, names}, socket) do
    {:noreply, assign(socket, :names, names)}
  end
end
