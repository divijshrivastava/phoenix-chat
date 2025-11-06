defmodule ChatAppWeb.RoomChannel do
  use ChatAppWeb, :channel

  @impl true
  def join("room:" <> room_id, _payload, socket) do
    # Create room if it doesn't exist and get message history
    ChatApp.Rooms.create_room(room_id)
    messages = ChatApp.Rooms.get_messages(room_id)

    socket = assign(socket, :room_id, room_id)
    {:ok, %{messages: messages, username: socket.assigns.username}, socket}
  end

  @impl true
  def handle_in("new_message", %{"body" => body}, socket) do
    room_id = socket.assigns.room_id
    username = socket.assigns.username
    user_id = socket.assigns.user_id

    # Store message in ETS
    message = ChatApp.Rooms.add_message(room_id, username, body)

    # Broadcast to all users in this room (including user_id to prevent duplicates)
    broadcast!(socket, "new_message", Map.put(message, :user_id, user_id))
    {:noreply, socket}
  end
end
