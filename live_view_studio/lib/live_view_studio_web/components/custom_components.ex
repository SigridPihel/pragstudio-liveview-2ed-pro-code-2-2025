defmodule LiveViewStudioWeb.CustomComponents do

  use Phoenix.Component

  attr :expiration, :integer, default: 24
  attr :minutes, :integer
  slot :legal
  slot :inner_block, required: true

  def promo(assigns) do
    assigns = assign_new(assigns, :minutes, fn -> assigns.expiration * 60 end)

    ~H"""
    <div class="promo">
      <div class="deal">
        <%= render_slot(@inner_block) %>
      </div>
      <div class="expiration">
        Deal expires in <%= @expiration %> hours and in <%= @minutes %> minutes
      </div>
      <div class="legal">
        <%= render_slot(@legal) %>
      </div>
    </div>
    """
  end

  attr :visible, :boolean, default: false

  def loading_indicator(assigns) do
    ~H"""
    <div :if={@visible} class="flex justify-center my-10 relative">
      <div>
        <span class="animate-perspective inline-flex h-6 w-6 bg-indigo-500"></span>
      </div>
    </div>
    """
  end

end
