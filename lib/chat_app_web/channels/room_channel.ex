defmodule ChatAppWeb.RoomChannel do
  use ChatAppWeb, :channel

  @impl true
  def join("room:" <> room_id, _payload, socket) do
    # Create room if it doesn't exist and get message history
    ChatApp.Rooms.create_room(room_id)
    messages = ChatApp.Rooms.get_messages(room_id)

    socket = assign(socket, :room_id, room_id)
    {:ok, %{messages: messages}, socket}
  end

  @impl true
  def handle_in("new_message", %{"body" => body, "username" => username}, socket) do
    room_id = socket.assigns.room_id

    # Store message in ETS
    message = ChatApp.Rooms.add_message(room_id, username, body)

    # Broadcast to all users in this room
    broadcast!(socket, "new_message", message)
    {:noreply, socket}
  end
end
