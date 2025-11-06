defmodule ChatApp.Rooms.RoomMember do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ["admin", "editor", "user"]

  schema "room_members" do
    field :role, :string, default: "user"
    field :approved, :boolean, default: false
    field :banned, :boolean, default: false
    belongs_to :user, ChatApp.Accounts.User
    belongs_to :room, ChatApp.Rooms.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room_member, attrs) do
    room_member
    |> cast(attrs, [:user_id, :room_id, :role, :approved, :banned])
    |> validate_required([:user_id, :room_id])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:user_id, :room_id])
  end
end

