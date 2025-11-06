defmodule ChatAppWeb.AuthController do
  use ChatAppWeb, :controller

  # Process callbacks through Ueberauth
  plug Ueberauth when action in [:callback]

  alias ChatApp.Accounts
  require Logger

  @doc """
  Initiates OAuth request - handled by Ueberauth plug
  """
  def request(conn, _params) do
    Ueberauth.call(conn, Ueberauth.init([]))
  end

  @doc """
  Handles the OAuth callback from providers (success or failure)
  """
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    Logger.info("OAuth callback success for provider: #{auth.provider}")

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

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.error("OAuth callback failure: #{inspect(fails)}")

    conn
    |> put_flash(:error, "Authentication failed. Please try again.")
    |> redirect(to: ~p"/")
  end

  # Catch-all for debugging
  def callback(conn, params) do
    Logger.error(
      "OAuth callback - no auth data in assigns. Params: #{inspect(params)}, Assigns: #{inspect(conn.assigns)}"
    )

    conn
    |> put_flash(:error, "Authentication error. Please try again.")
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
