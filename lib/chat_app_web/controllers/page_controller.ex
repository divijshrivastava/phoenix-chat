defmodule ChatAppWeb.PageController do
  use ChatAppWeb, :controller

  alias ChatApp.Accounts
  alias ChatApp.Rooms

  def home(conn, _params) do
    username = get_session(conn, :username)
    user_id = get_session(conn, :user_id)

    user_token =
      if user_id do
        Phoenix.Token.sign(conn, "user socket", user_id)
      else
        nil
      end

    user_rooms =
      case user_id do
        nil -> []
        id -> Rooms.list_user_rooms(id)
      end

    render(conn, :home,
      username: username,
      room_id: nil,
      user_token: user_token,
      user_rooms: user_rooms
    )
  end

  def profile(conn, _params) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = Accounts.get_user(user_id)

      user_rooms =
        Rooms.list_rooms()
        |> Enum.filter(fn room -> room.created_by_id == user_id end)

      render(conn, :profile, user: user, user_rooms: user_rooms)
    else
      conn
      |> put_flash(:info, "Please sign in to view your profile.")
      |> redirect(to: ~p"/")
    end
  end

  def public_profile(conn, %{"id" => user_id_str}) do
    current_user_id = get_session(conn, :user_id)

    case Integer.parse(user_id_str) do
      {user_id, ""} ->
        user = Accounts.get_user(user_id)

        if user do
          # Get rooms created by this user
          user_rooms =
            Rooms.list_rooms()
            |> Enum.filter(fn room -> room.created_by_id == user_id end)

          render(conn, :public_profile,
            user: user,
            user_rooms: user_rooms,
            is_own_profile: current_user_id == user_id
          )
        else
          conn
          |> put_flash(:error, "User not found.")
          |> redirect(to: ~p"/")
        end

      _ ->
        conn
        |> put_flash(:error, "Invalid user ID.")
        |> redirect(to: ~p"/")
    end
  end

  def room(conn, %{"id" => room_id}) do
    username = get_session(conn, :username)
    user_id = get_session(conn, :user_id)

    if username && user_id do
      user_token = Phoenix.Token.sign(conn, "user socket", user_id)

      # Get room details including name and user role
      room = Rooms.get_room(room_id)
      room_member = if room, do: Rooms.get_room_member(room_id, user_id), else: nil

      render(conn, :home,
        username: username,
        room_id: room_id,
        user_token: user_token,
        room: room,
        room_member: room_member
      )
    else
      conn
      |> put_session(:return_to, "/room/#{room_id}")
      |> put_flash(:info, "Please sign in to join the chat room.")
      |> redirect(to: ~p"/")
    end
  end

  def create_room(conn, _params) do
    user_id = get_session(conn, :user_id)

    if user_id do
      render(conn, :create_room)
    else
      conn
      |> put_flash(:info, "Please sign in to create a chat room.")
      |> redirect(to: ~p"/")
    end
  end

  def create_room_post(conn, %{"room" => room_params}) do
    user_id = get_session(conn, :user_id)

    if user_id do
      name = room_params["name"] |> String.trim() |> then(&((&1 != "" && &1) || nil))
      is_private = room_params["is_private"] == "true"

      attrs = %{
        created_by_id: user_id,
        name: name,
        is_private: is_private
      }

      case Rooms.create_room(attrs) do
        {:ok, room} ->
          # Add creator as admin
          Rooms.add_member(room.room_id, user_id, %{role: "admin", approved: true})

          conn
          |> put_flash(:info, "Room created successfully!")
          |> redirect(to: ~p"/room/#{room.room_id}")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to create room. Please try again.")
          |> redirect(to: ~p"/create_room")
      end
    else
      conn
      |> put_flash(:info, "Please sign in to create a chat room.")
      |> redirect(to: ~p"/")
    end
  end
end
