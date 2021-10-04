# lib/pento_web/live/my_page_live.ex
defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    {:ok, assign(socket, room_id: room_id)}
  end
  
end