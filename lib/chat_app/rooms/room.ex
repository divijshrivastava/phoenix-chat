defmodule ChatApp.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :room_id, :string
    field :name, :string
    field :is_private, :boolean, default: false
    belongs_to :created_by, ChatApp.Accounts.User, foreign_key: :created_by_id
    has_many :room_members, ChatApp.Rooms.RoomMember

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:room_id, :name, :is_private, :created_by_id])
    |> validate_required([:room_id, :created_by_id])
    |> unique_constraint(:room_id)
  end
end

