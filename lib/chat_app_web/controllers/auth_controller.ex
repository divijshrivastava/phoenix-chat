defmodule ChatAppWeb.AuthController do
  use ChatAppWeb, :controller
  plug Ueberauth

  alias ChatApp.Accounts

  @doc """
  Handles the OAuth callback from providers (success or failure)
  """
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.upsert_user_from_auth(auth) do
      {:ok, user} ->
        return_to = get_session(conn, :return_to) || ~p"/"

        conn
        |> put_session(:user_id, user.id)
        |> put_session(:username, user.name || user.email)
        |> delete_session(:return_to)
        |> put_flash(:info, "Welcome, #{user.name || user.email}!")
        |> redirect(to: return_to)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to authenticate. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed. Please try again.")
    |> redirect(to: ~p"/")
  end

  @doc """
  Signs the user out
  """
  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/")
  end
end
