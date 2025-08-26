defmodule LiveViewStudioWeb.PresenceLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence

  @topic "users:video"

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Presence.subscribe(@topic)

      {:ok, _} =
        Presence.track_user(current_user, @topic, %{
          is_playing: false
        })
    end

    presences = Presence.list_users(@topic)

    like_count = 0

    socket =
      socket
      |> assign(:is_playing, false)
      |> assign(:like_count, like_count)
      |> assign(:presences, Presence.simple_presence_map(presences))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="presence">
      <div class="users">
        <h2>
          Who's Here?
          <button
            phx-click={JS.toggle(to: "#presences")}
          >
           <Heroicons.list_bullet class="w-16 h-16" />
          </button>
        </h2>
        <ul id="presences">
          <li :for={{_user_id, meta} <- @presences}>
            <span class="status">
              {if meta.is_playing, do: "👀", else: "🙈"}
            </span>
            <span class="username">
              {meta.username}
            </span>
          </li>
        </ul>
      </div>
      <div>
        <div class="video" phx-click="toggle-playing">
          <%= if @is_playing do %>
            <Heroicons.pause class="w-16 h-16" />
          <% else %>
            <Heroicons.play class="w-16 h-16" />
          <% end %>
        </div>
        <div phx-click="click-like">
          <p>
            If you like this video then give a thumbs up
            <Heroicons.hand_thumb_up class="inline w-6 h-6 ml-2" />
            {@like_count}
          </p>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("click-like", _, socket) do
    new_count = socket.assigns.like_count + 1

    Phoenix.PubSub.broadcast(
      LiveViewStudio.PubSub,
      @topic,
      %{event: "like_count_updated", like_count: new_count}
    )

    {:noreply, assign(socket, :like_count, new_count)}
  end

  def handle_info(%{event: "like_count_updated", like_count: like_count}, socket) do
    {:noreply, assign(socket, :like_count, like_count)}
  end

  def handle_event("toggle-playing", _, socket) do
    socket = update(socket, :is_playing, fn playing -> !playing end)

    %{current_user: current_user} = socket.assigns

    Presence.update_user(current_user, @topic, %{
      is_playing: socket.assigns.is_playing
    })

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    {:noreply, Presence.handle_diff(socket, diff)}
  end
end
