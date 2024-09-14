defmodule CircleWeb.VideoHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use CircleWeb, :html

  embed_templates "video_html/*"
end
