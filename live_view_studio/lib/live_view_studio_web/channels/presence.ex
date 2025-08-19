defmodule LiveViewStudioWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :live_view_studio,
    pubsub_server: LiveViewStudio.PubSub

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(LiveViewStudio.PubSub, topic)
  end

  def list_users(topic) do
    list(topic)
  end

  def update_user(user, topic, new_meta) do
    %{metas: [meta | _]} = get_by_key(topic, user.id)

    update(self(), topic, user.id, Map.merge(meta, new_meta))
  end

  def track_user(user, topic, meta \\ %{}) do
    default_meta = %{
      username: user.email |> String.split("@") |> hd()
    }

    track(self(), topic, user.id, Map.merge(default_meta, meta))
  end

  def add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))

    Phoenix.Component.assign(socket, presences: presences)
  end

  def remove_presences(socket, leaves) do
    user_ids = Enum.map(leaves, fn {user_id, _} -> user_id end)

    presences = Map.drop(socket.assigns.presences, user_ids)

    Phoenix.Component.assign(socket, presences: presences)
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

  def handle_diff(socket, diff) do
    socket
    |> remove_presences(diff.leaves)
    |> add_presences(diff.joins)
  end
end
