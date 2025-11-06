defmodule ChatAppWeb.RoomChannel do
  use ChatAppWeb, :channel

  alias ChatApp.Rooms

  @impl true
  def join("room:" <> room_id, _payload, socket) do
    user_id = socket.assigns.user_id
    username = socket.assigns.username

    # Get or create room in database
    room = Rooms.get_room(room_id)

    if room do
      # Check if user is banned
      room_member = Rooms.get_room_member(room_id, user_id)

      if room_member && room_member.banned do
        {:error, %{reason: "You are banned from this room"}}
      else
        # Add user as member if not already a member
        {final_member, is_new_member} = if !room_member do
          # Check if room is private
          is_private = room.is_private

          # For public rooms, auto-approve. For private rooms, require approval
          auto_approve = !is_private

          case Rooms.add_member(room_id, user_id, %{role: "user", approved: auto_approve}) do
            {:ok, member} -> {member, true}
            {:error, _} -> {nil, false}
          end
        else
          {room_member, false}
        end

        # Check if approval is required
        pending_approval = if final_member && !final_member.approved do
          true
        else
          false
        end

        if pending_approval do
          {:error, %{reason: "Waiting for admin approval"}}
        else
          # Get message history
          messages = Rooms.get_messages(room_id)

          # Broadcast join notification if this is a new member joining
          if is_new_member do
            broadcast!(socket, "user_joined", %{username: username})
          end

          socket = assign(socket, :room_id, room_id)
          {:ok, %{messages: messages, username: socket.assigns.username}, socket}
        end
      end
    else
      # Room doesn't exist in database, create it (default to public)
      case Rooms.create_room(%{room_id: room_id, created_by_id: user_id, is_private: false}) do
        {:ok, _new_room} ->
          # Add creator as admin
          Rooms.add_member(room_id, user_id, %{role: "admin", approved: true})

          messages = Rooms.get_messages(room_id)
          socket = assign(socket, :room_id, room_id)
          {:ok, %{messages: messages, username: socket.assigns.username}, socket}

        {:error, _} ->
          {:error, %{reason: "Failed to create room"}}
      end
    end
  end

  @impl true
  def handle_in("new_message", %{"body" => body}, socket) do
    room_id = socket.assigns.room_id
    username = socket.assigns.username
    user_id = socket.assigns.user_id

    # Check if user is banned or not approved
    room_member = Rooms.get_room_member(room_id, user_id)
    
    if room_member && room_member.banned do
      {:reply, {:error, %{reason: "You are banned from this room"}}, socket}
    else
      if room_member && !room_member.approved do
        {:reply, {:error, %{reason: "You are not approved to send messages"}}, socket}
      else
        # Store message in ETS (including user_id)
        message = Rooms.add_message(room_id, username, body, user_id)

        # Broadcast to all users in this room (user_id already included in message)
        broadcast!(socket, "new_message", message)
        {:noreply, socket}
      end
    end
  end
end
