defmodule CircleWeb.PageController do
  use CircleWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    redirect(conn, to: ~p"/videos/new")
  end
end
