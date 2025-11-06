defmodule ChatAppWeb.UserSocket do
  use Phoenix.Socket

  alias ChatApp.Accounts

  # Define channels
  channel "room:*", ChatAppWeb.RoomChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # Verify the token and get user_id
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 86400) do
      {:ok, user_id} ->
        case Accounts.get_user(user_id) do
          nil ->
            :error

          user ->
            socket =
              socket
              |> assign(:user_id, user.id)
              |> assign(:username, user.name || user.email)

            {:ok, socket}
        end

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
