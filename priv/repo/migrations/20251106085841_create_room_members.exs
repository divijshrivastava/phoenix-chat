defmodule ChatApp.Repo.Migrations.CreateRoomMembers do
  use Ecto.Migration

  def change do
    create table(:room_members) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :room_id, references(:rooms, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "user"
      add :approved, :boolean, null: false, default: false
      add :banned, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:room_members, [:user_id, :room_id])
    create index(:room_members, :room_id)
    create index(:room_members, :user_id)
  end
end

