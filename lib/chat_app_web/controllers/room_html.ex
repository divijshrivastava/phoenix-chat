defmodule ChatAppWeb.RoomHTML do
  @moduledoc """
  This module contains pages rendered by RoomController.
  """
  use ChatAppWeb, :html

  embed_templates "room_html/*"
end

