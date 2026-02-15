defmodule ChatAppWeb.AuthController do
  use ChatAppWeb, :controller

  # Process callbacks through Ueberauth
  plug Ueberauth when action in [:callback]

  alias ChatApp.Accounts
  require Logger

  @doc """
  Initiates OAuth request - handled by Ueberauth plug
  """
  def request(%{path_params: %{"provider" => provider}} = conn, _params) do
    case strategy_for_provider(provider) do
      {:ok, strategy} ->
        if configured_oauth_provider?(strategy) do
          Ueberauth.call(conn, Ueberauth.init([]))
        else
          conn
          |> put_flash(
            :error,
            "#{String.capitalize(provider)} login is not configured on this server."
          )
          |> redirect(to: ~p"/")
        end

      :error ->
        conn
        |> put_flash(:error, "Unsupported authentication provider.")
        |> redirect(to: ~p"/")
    end
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

  defp strategy_for_provider("google"), do: {:ok, Ueberauth.Strategy.Google.OAuth}
  defp strategy_for_provider("github"), do: {:ok, Ueberauth.Strategy.Github.OAuth}
  defp strategy_for_provider(_provider), do: :error

  defp configured_oauth_provider?(strategy) do
    config = Application.get_env(:ueberauth, strategy, [])
    client_id = Keyword.get(config, :client_id)
    client_secret = Keyword.get(config, :client_secret)

    present_string?(client_id) and present_string?(client_secret)
  end

  defp present_string?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_string?(_value), do: false
end
