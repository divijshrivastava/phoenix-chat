defmodule ChatAppWeb.PageController do
  use ChatAppWeb, :controller

  def home(conn, _params) do
    username = get_session(conn, :username)
    render(conn, :home, username: username, room_id: nil)
  end

  def room(conn, %{"id" => room_id}) do
    username = get_session(conn, :username)

    if username do
      render(conn, :home, username: username, room_id: room_id)
    else
      conn
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

  def sign_in(conn, %{"username" => username}) do
    conn
    |> put_session(:username, username)
    |> put_flash(:info, "Welcome, #{username}!")
    |> redirect(to: ~p"/")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been signed out.")
    |> redirect(to: ~p"/")
  end
end
