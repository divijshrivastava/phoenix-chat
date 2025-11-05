defmodule ChatApp.Repo.Migrations.CreateOauthUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string
      add :avatar, :string
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_token, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:provider, :provider_id])
    create unique_index(:users, [:email])
  end
end
