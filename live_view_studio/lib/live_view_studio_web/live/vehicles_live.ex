defmodule LiveViewStudioWeb.VehiclesLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Vehicles

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        vehicle: "",
        vehicles: [],
        loading: false,
        matches: []
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>🚙 Find a Vehicle 🚘</h1>
    <div id="vehicles">
      <form phx-submit="search" phx-change="suggest">
        <input
          type="text"
          name="query"
          value={@vehicle}
          placeholder="Make or model"
          autofocus
          autocomplete="off"
          readonly={@loading}
          list="matches"
          phx-debounce="1000"
        />

        <button>
          <img src="/images/search.svg" />
        </button>
      </form>

      <datalist id="matches">
        <option :for={vehicle <- @matches} value={vehicle}>
          {vehicle}
        </option>
      </datalist>

      <.loading_indicator visible={@loading} />

      <div class="vehicles">
        <ul>
          <li :for={vehicle <- @vehicles}>
            <span class="make-model">
              {vehicle.make_model}
            </span>
            <span class="color">
              {vehicle.color}
            </span>
            <span class={"status #{vehicle.status}"}>
              {vehicle.status}
            </span>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("suggest", %{"query" => prefix}, socket) do
    matches = Vehicles.suggest(prefix)
    {:noreply, assign(socket, matches: matches)}
  end

  def handle_event("search", %{"query" => vehicle}, socket) do
    send(self(), {:run_search, vehicle})

    socket =
      assign(socket,
        vehicle: vehicle,
        vehicles: [],
        loading: true
      )

    {:noreply, socket}
  end

  def handle_info({:run_search, vehicle}, socket) do
    socket =
      assign(socket,
        vehicles: Vehicles.search(vehicle),
        loading: false
      )

    {:noreply, socket}
  end
end
