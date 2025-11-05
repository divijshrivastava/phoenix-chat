defmodule ChatApp.Rooms do
  @moduledoc """
  Manages chat rooms and message history using ETS.
  Each room stores the last 50 messages in memory.
  """

  @table_name :chat_rooms
  @max_messages_per_room 50

  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
  end

  def create_room(room_id) do
    case :ets.lookup(@table_name, room_id) do
      [] ->
        :ets.insert(@table_name, {room_id, []})
        {:ok, room_id}
      _ ->
        {:ok, room_id}
    end
  end

  def add_message(room_id, username, message) do
    create_room(room_id)

    message_data = %{
      username: username,
      body: message,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    messages = get_messages(room_id)
    updated_messages = Enum.take([message_data | messages], @max_messages_per_room)

    :ets.insert(@table_name, {room_id, updated_messages})
    message_data
  end

  def get_messages(room_id) do
    case :ets.lookup(@table_name, room_id) do
      [{^room_id, messages}] -> Enum.reverse(messages)
      [] -> []
    end
  end

  def room_exists?(room_id) do
    case :ets.lookup(@table_name, room_id) do
      [] -> false
      _ -> true
    end
  end

  def generate_room_id do
    :crypto.strong_rand_bytes(6)
    |> Base.url_encode64(padding: false)
    |> String.downcase()
  end
end
