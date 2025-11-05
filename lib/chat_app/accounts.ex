defmodule ChatApp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ChatApp.Repo
  alias ChatApp.Accounts.User

  @doc """
  Gets a single user by id.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by provider and provider_id.
  """
  def get_user_by_provider(provider, provider_id) do
    Repo.get_by(User, provider: provider, provider_id: provider_id)
  end

  @doc """
  Creates or updates a user from OAuth data.
  """
  def upsert_user_from_auth(%Ueberauth.Auth{} = auth) do
    provider = to_string(auth.provider)
    provider_id = auth.uid

    case get_user_by_provider(provider, provider_id) do
      nil ->
        # Create new user
        User.oauth_changeset(auth)
        |> Repo.insert()

      user ->
        # Update existing user with latest OAuth data
        params = %{
          email: auth.info.email,
          name: auth.info.name,
          avatar: auth.info.image,
          provider_token: auth.credentials.token
        }

        user
        |> User.changeset(params)
        |> Repo.update()
    end
  end
end
