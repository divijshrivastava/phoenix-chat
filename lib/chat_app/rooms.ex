defmodule ChatApp.Rooms do
  @moduledoc """
  Manages chat rooms, room members, and message history.
  Uses ETS for message storage (last 50 messages per room).
  """

  import Ecto.Query, warn: false
  alias ChatApp.Repo
  alias ChatApp.Rooms.{Room, RoomMember}

  @table_name :chat_rooms
  @max_messages_per_room 50

  # Initialize ETS table for message storage
  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
  end

  # Room Management
  def create_room(attrs \\ %{}) do
    room_id = attrs[:room_id] || generate_room_id()

    %Room{}
    |> Room.changeset(Map.put(attrs, :room_id, room_id))
    |> Repo.insert()
  end

  def get_room(room_id) do
    Repo.get_by(Room, room_id: room_id)
    |> Repo.preload([:created_by, room_members: [:user]])
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  def list_rooms do
    Repo.all(Room)
    |> Repo.preload([:created_by])
  end

  # Room Member Management
  def add_member(room_id, user_id, attrs \\ %{}) do
    room = get_room(room_id)
    if room do
      %RoomMember{}
      |> RoomMember.changeset(
        Map.merge(attrs, %{
          user_id: user_id,
          room_id: room.id,
          role: attrs[:role] || "user",
          approved: attrs[:approved] || false
        })
      )
      |> Repo.insert()
    else
      {:error, :room_not_found}
    end
  end

  def get_room_member(room_id, user_id) do
    room = Repo.get_by(Room, room_id: room_id)

    if room do
      Repo.get_by(RoomMember, room_id: room.id, user_id: user_id)
      |> Repo.preload([:user, :room])
    else
      nil
    end
  end

  def update_room_member(%RoomMember{} = member, attrs) do
    member
    |> RoomMember.changeset(attrs)
    |> Repo.update()
  end

  def get_user_role(room_id, user_id) do
    case get_room_member(room_id, user_id) do
      nil -> nil
      member -> member.role
    end
  end

  def is_admin?(room_id, user_id) do
    get_user_role(room_id, user_id) == "admin"
  end

  def is_editor_or_admin?(room_id, user_id) do
    role = get_user_role(room_id, user_id)
    role in ["admin", "editor"]
  end

  def can_rename_room?(room_id, user_id) do
    is_editor_or_admin?(room_id, user_id)
  end

  def can_ban_users?(room_id, user_id) do
    is_admin?(room_id, user_id)
  end

  def can_approve_users?(room_id, user_id) do
    is_admin?(room_id, user_id)
  end

  def ban_user(room_id, user_id_to_ban) do
    case get_room_member(room_id, user_id_to_ban) do
      nil -> {:error, :member_not_found}
      member -> update_room_member(member, %{banned: true})
    end
  end

  def unban_user(room_id, user_id_to_unban) do
    case get_room_member(room_id, user_id_to_unban) do
      nil -> {:error, :member_not_found}
      member -> update_room_member(member, %{banned: false})
    end
  end

  def approve_user(room_id, user_id_to_approve) do
    case get_room_member(room_id, user_id_to_approve) do
      nil -> {:error, :member_not_found}
      member -> update_room_member(member, %{approved: true})
    end
  end

  def list_pending_approvals(room_id) do
    room = Repo.get_by(Room, room_id: room_id)

    if room do
      from(rm in RoomMember,
        where: rm.room_id == ^room.id and rm.approved == false and rm.banned == false,
        preload: [:user]
      )
      |> Repo.all()
    else
      []
    end
  end

  def list_room_members(room_id) do
    room = Repo.get_by(Room, room_id: room_id)

    if room do
      from(rm in RoomMember,
        where: rm.room_id == ^room.id and rm.banned == false,
        preload: [:user]
      )
      |> Repo.all()
    else
      []
    end
  end

  # Message storage (using ETS - keeping existing functionality)
  def create_room_ets(room_id) do
    case :ets.lookup(@table_name, room_id) do
      [] ->
        :ets.insert(@table_name, {room_id, []})
        {:ok, room_id}
      _ ->
        {:ok, room_id}
    end
  end

  def add_message(room_id, username, message, user_id \\ nil) do
    create_room_ets(room_id)

    message_data = %{
      username: username,
      body: message,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      user_id: user_id
    }

    messages = get_messages(room_id)
    updated_messages = Enum.take([message_data | messages], @max_messages_per_room)

    :ets.insert(@table_name, {room_id, updated_messages})
    message_data
  end

  def get_messages(room_id) do
    case :ets.lookup(@table_name, room_id) do
      [{^room_id, messages}] -> Enum.reverse(messages)
      [] -> []
    end
  end

  def room_exists_ets?(room_id) do
    case :ets.lookup(@table_name, room_id) do
      [] -> false
      _ -> true
    end
  end

  def generate_room_id do
    :crypto.strong_rand_bytes(6)
    |> Base.url_encode64(padding: false)
    |> String.downcase()
  end
end
