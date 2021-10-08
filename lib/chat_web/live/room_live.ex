# lib/pento_web/live/my_page_live.ex
defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)
    if connected?(socket) do 
      ChatWeb.Endpoint.subscribe(topic)
      ChatWeb.Presence.track(self(), topic, username, %{})
    end
    {:ok, assign(
      socket, 
      is_typing_user: "",
      is_typing_message: %{content: "", type: :system, username: "system", uuid: UUID.uuid4()},
      room_id: room_id, 
      topic: topic, 
      username: username,
      user_list: [],
      message: "",
      messages: [], 
      temporary_assigns: [messages: []]
    )}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
    
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new_message", message)
    is_typing = %{uuid: UUID.uuid4(), type: :system, content: "", username: "system"}
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "finished_typing", socket.assigns.username)
    {:noreply, assign(socket, message: "", is_typing_message: is_typing)}
  end

  @impl true
  def handle_event("update_form", %{"chat" => %{"message" => message}}, socket) do
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "is_typing", socket.assigns.username)
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{event: "new_message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(%{event: "finished_typing", payload: user}, socket) do
    message = %{uuid: UUID.uuid4(), type: :system, content: "", username: "system"}
    {:noreply, assign(socket, is_typing_message: message)}
  end

  @impl true
  def handle_info(%{event: "is_typing", payload: user}, socket) do
    message = %{uuid: UUID.uuid4(), type: :system, content: user <> " is typing...", username: "system"}
    {:noreply, assign(socket, is_typing_user: user, is_typing_message: message)}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username -> 
        %{type: :system,
        uuid: UUID.uuid4(), 
        content: "#{username} joined", 
        username: "system"} end)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username -> 
        %{type: :system,
        uuid: UUID.uuid4(), 
        content: "#{username} left", 
        username: "system"} end)

    user_list = ChatWeb.Presence.list(socket.assigns.topic)
    |> Map.keys()

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
  end

  def display_message(%{type: :system, uuid: uuid, content: content}) do
    ~E"""
    <p id="<%= uuid %>"><em><%= content %></em></p>
    """
  end
  
  def display_message(%{uuid: uuid, content: content, username: username}) do
    ~E"""
    <p id="<%= uuid %>"><strong><%= username %></strong>: <%= content %></p>
    """
  end


end