# lib/pento_web/live/my_page_live.ex
defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    ChatWeb.Endpoint.subscribe(topic)
    {:ok, assign(socket, room_id: room_id, topic: topic, messages: ["Hello Twitch!"])}
  end

  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    Logger.info(message: message)
    {:noreply, socket}
  end
  
end