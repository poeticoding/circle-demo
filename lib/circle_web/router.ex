defmodule CircleWeb.Router do
  use CircleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CircleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CircleWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/videos/new", VideoLive.Upload, :new

    get "/videos/:id", VideoController, :show
    get "/videos/:id/preview.jpg", VideoController, :preview_image
    get "/videos/:id/download", VideoController, :download
  end

  # Other scopes may use custom stacks.
  # scope "/api", CircleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:circle, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CircleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp auth(conn, _opts) do
    Plug.BasicAuth.basic_auth(conn, Application.fetch_env!(:circle, :basic_auth))
  end
end
