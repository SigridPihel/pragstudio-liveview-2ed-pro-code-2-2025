defmodule LiveViewStudioWeb.PresenceLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence

  @topic "users:video"

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @topic, current_user.id, %{
          username: current_user.email |> String.split("@") |> hd(),
          is_playing: false
        })
    end

    presences = Presence.list(@topic)

    socket =
      socket
      |> assign(:is_playing, false)
      |> assign(:presences, simple_presence_map(presences))

    {:ok, socket}
  end

  def simple_presence_map(presences) do
    # %{
    #   "1" => %{
    #     metas: [
    #       %{username: "bond", phx_ref: "GFtStDzqeGk0rA7j", is_playing: false},
    #       %{username: "bond", phx_ref: "GFtSvmknq-40rA9D", is_playing: false}
    #     ]
    #   }
    # }

    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)

    # %{
    #   "1" => %{username: "bond", phx_ref: "GFtStDzqeGk0rA7j", is_playing: false}
    # }
  end

  def render(assigns) do
    ~H"""
    <pre>
      <%!-- <%= inspect(@presences, pretty: true) %> --%>
    </pre>

    <div id="presence">
      <div class="users">
        <h2>Who's Here?</h2>
        <ul>
          <li :for={{_user_id, meta} <- @presences}>
            <span class="status">
              <%= if meta.is_playing, do: "👀", else: "🙈" %>
            </span>
            <span class="username">
              <%= meta.username %>
            </span>
          </li>
        </ul>
      </div>
      <div class="video" phx-click="toggle-playing">
        <%= if @is_playing do %>
          <Heroicons.pause class="w-16 h-16" />
        <% else %>
          <Heroicons.play class="w-16 h-16" />
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("toggle-playing", _, socket) do
    socket = update(socket, :is_playing, fn playing -> !playing end)
    {:noreply, socket}
  end
end
