defmodule ChatAppWeb.RoomController do
  use ChatAppWeb, :controller

  alias ChatApp.Rooms

  def members(conn, %{"id" => room_id}) do
    user_id = get_session(conn, :user_id)

    if user_id do
      room = Rooms.get_room(room_id)
      room_member = if room, do: Rooms.get_room_member(room_id, user_id), else: nil

      # Only allow approved members to see the member list
      if room_member && room_member.approved && !room_member.banned do
        members = Rooms.list_room_members(room_id)
        |> Enum.filter(fn m -> m.approved end)
        |> Enum.map(fn m ->
          %{
            id: m.user.id,
            name: m.user.name || m.user.email,
            role: m.role
          }
        end)

        json(conn, %{members: members})
      else
        json(conn, %{error: "Unauthorized"})
      end
    else
      json(conn, %{error: "Unauthorized"})
    end
  end

  def manage(conn, %{"id" => room_id}) do
    user_id = get_session(conn, :user_id)

    if user_id do
      room = Rooms.get_room(room_id)
      room_member = if room, do: Rooms.get_room_member(room_id, user_id), else: nil

      # Allow both admins and editors to access the manage page
      if room_member && (room_member.role == "admin" || room_member.role == "editor") do
        pending_approvals = Rooms.list_pending_approvals(room_id)
        room_members = Rooms.list_room_members(room_id)

        render(conn, :manage,
          room: room,
          room_id: room_id,
          room_member: room_member,
          pending_approvals: pending_approvals,
          room_members: room_members
        )
      else
        conn
        |> put_flash(:error, "You don't have permission to manage this room.")
        |> redirect(to: ~p"/room/#{room_id}")
      end
    else
      conn
      |> put_flash(:info, "Please sign in to manage rooms.")
      |> redirect(to: ~p"/")
    end
  end

  def rename(conn, %{"id" => room_id, "room" => %{"name" => name}}) do
    user_id = get_session(conn, :user_id)

    if user_id do
      room = Rooms.get_room(room_id)

      if room && Rooms.can_rename_room?(room_id, user_id) do
        trimmed_name = name |> String.trim() |> then(&(&1 != "" && &1 || nil))

        case Rooms.update_room(room, %{name: trimmed_name}) do
          {:ok, _updated_room} ->
            conn
            |> put_flash(:info, "Room name updated successfully!")
            |> redirect(to: ~p"/room/#{room_id}/manage")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Failed to update room name.")
            |> redirect(to: ~p"/room/#{room_id}/manage")
        end
      else
        conn
        |> put_flash(:error, "You don't have permission to rename this room.")
        |> redirect(to: ~p"/room/#{room_id}")
      end
    else
      conn
      |> put_flash(:info, "Please sign in.")
      |> redirect(to: ~p"/")
    end
  end

  def approve_user(conn, %{"id" => room_id, "user_id" => user_id_to_approve}) do
    user_id = get_session(conn, :user_id)

    if user_id && Rooms.can_approve_users?(room_id, user_id) do
      case Rooms.approve_user(room_id, String.to_integer(user_id_to_approve)) do
        {:ok, _member} ->
          conn
          |> put_flash(:info, "User approved successfully!")
          |> redirect(to: ~p"/room/#{room_id}/manage")

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Failed to approve user.")
          |> redirect(to: ~p"/room/#{room_id}/manage")
      end
    else
      conn
      |> put_flash(:error, "You don't have permission to approve users.")
      |> redirect(to: ~p"/room/#{room_id}")
    end
  end

  def ban_user(conn, %{"id" => room_id, "user_id" => user_id_to_ban}) do
    user_id = get_session(conn, :user_id)

    if user_id && Rooms.can_ban_users?(room_id, user_id) do
      case Rooms.ban_user(room_id, String.to_integer(user_id_to_ban)) do
        {:ok, _member} ->
          conn
          |> put_flash(:info, "User banned successfully!")
          |> redirect(to: ~p"/room/#{room_id}/manage")

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Failed to ban user.")
          |> redirect(to: ~p"/room/#{room_id}/manage")
      end
    else
      conn
      |> put_flash(:error, "You don't have permission to ban users.")
      |> redirect(to: ~p"/room/#{room_id}")
    end
  end

  def unban_user(conn, %{"id" => room_id, "user_id" => user_id_to_unban}) do
    user_id = get_session(conn, :user_id)

    if user_id && Rooms.can_ban_users?(room_id, user_id) do
      case Rooms.unban_user(room_id, String.to_integer(user_id_to_unban)) do
        {:ok, _member} ->
          conn
          |> put_flash(:info, "User unbanned successfully!")
          |> redirect(to: ~p"/room/#{room_id}/manage")

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Failed to unban user.")
          |> redirect(to: ~p"/room/#{room_id}/manage")
      end
    else
      conn
      |> put_flash(:error, "You don't have permission to unban users.")
      |> redirect(to: ~p"/room/#{room_id}")
    end
  end
end

