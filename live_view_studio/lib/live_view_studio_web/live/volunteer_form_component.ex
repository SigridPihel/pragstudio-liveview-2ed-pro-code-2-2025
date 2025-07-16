defmodule LivewViewStudioWeb.VolunteerFormComponent do
  use LiveViewStudioWeb, :live_component

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(socket) do

    changeset = Volunteers.change_volunteer(%Volunteer{})

    {:ok, assign(socket, :form, to_form(changeset))}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:count, assigns.count + 1)

    {:ok, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    volunteer = Volunteers.get_volunteer!(id)
    {:ok, _volunteer} = Volunteers.delete_volunteer(volunteer)

    socket = stream_delete(socket, :volunteers, volunteer)

    IO.inspect(socket.assigns.streams.volunteers, label: "delete")

    {:noreply, socket}
  end

  def handle_event("validate", %{"volunteer" => volunteer_params}, socket) do

    # IO.inspect(socket.assigns.streams.volunteers, label: "validate")

    changeset =
      %Volunteer{}
      |> Volunteers.change_volunteer(volunteer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"volunteer" => volunteer_params}, socket) do
    case Volunteers.create_volunteer(volunteer_params) do
      {:ok, volunteer} ->
        send(self(), {__MODULE__, :volunteer_created, volunteer})

        # IO.inspect(socket.assigns.streams.volunteers, label: "save")

        socket = put_flash(socket, :info, "Volunteer successfully checked in!")
        changeset = Volunteers.change_volunteer(%Volunteer{})
        {:noreply, assign_form(socket, changeset)}

      {:error, changeset} ->
        socket = put_flash(socket, :error, "Error appeared")
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end


end
