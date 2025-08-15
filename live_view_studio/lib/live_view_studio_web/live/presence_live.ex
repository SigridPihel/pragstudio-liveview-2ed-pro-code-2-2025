defmodule LiveViewStudioWeb.PresenceLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence

  @topic "users:video"

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveViewStudio.PubSub, @topic)

      {:ok, _} =
        Presence.track(self(), @topic, current_user.id, %{
          username: current_user.email |> String.split("@") |> hd(),
          is_playing: false
        })
    end

    presences = Presence.list(@topic)

    like_count = 0

    socket =
      socket
      |> assign(:is_playing, false)
      |> assign(:like_count, like_count)
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
    <div id="presence">
      <div class="users">
        <h2>Who's Here?</h2>
        <ul>
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

    %{metas: [meta | _]} = Presence.get_by_key(@topic, current_user.id)

    new_meta = %{meta | is_playing: socket.assigns.is_playing}

    Presence.update(self(), @topic, current_user.id, new_meta)

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    {:noreply, socket}
  end

  defp add_presences(socket, joins) do
    simple_presence_map(joins)
    |> Enum.reduce(socket, fn {user_id, meta}, socket ->
      update(socket, :presences, &Map.put(&1, user_id, meta))
    end)
  end

  defp remove_presences(socket, leaves) do
    simple_presence_map(leaves)
    |> Enum.reduce(socket, fn {user_id, _}, socket ->
      update(socket, :presences, &Map.delete(&1, user_id))
    end)
  end
end
