defmodule PhxAppWeb.Dashboard.Form do
  alias PhxApp.Dashboard
  use PhxAppWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: to_form(%{}))}
  end

  def handle_event("add", %{"name" => name_param}, socket) do
    if name_param != "", do: Dashboard.Room.insert_name("dashboard", name_param)
    {:noreply, socket}
  end
end
