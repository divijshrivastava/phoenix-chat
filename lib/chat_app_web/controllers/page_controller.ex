defmodule ChatAppWeb.PageController do
  use ChatAppWeb, :controller

  def home(conn, _params) do
    username = get_session(conn, :username)
    user_id = get_session(conn, :user_id)

    user_token =
      if user_id do
        Phoenix.Token.sign(conn, "user socket", user_id)
      else
        nil
      end

    render(conn, :home, username: username, room_id: nil, user_token: user_token)
  end

  def room(conn, %{"id" => room_id}) do
    username = get_session(conn, :username)
    user_id = get_session(conn, :user_id)

    if username && user_id do
      user_token = Phoenix.Token.sign(conn, "user socket", user_id)
      render(conn, :home, username: username, room_id: room_id, user_token: user_token)
    else
      conn
      |> put_session(:return_to, "/room/#{room_id}")
      |> put_flash(:info, "Please sign in to join the chat room.")
      |> redirect(to: ~p"/")
    end
  end

  def create_room(conn, _params) do
    username = get_session(conn, :username)

    if username do
      room_id = ChatApp.Rooms.generate_room_id()
      redirect(conn, to: ~p"/room/#{room_id}")
    else
      conn
      |> put_flash(:info, "Please sign in to create a chat room.")
      |> redirect(to: ~p"/")
    end
  end
end
