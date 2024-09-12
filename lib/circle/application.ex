defmodule Circle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @flame_timeout 10 * 60_000

  @impl true
  def start(_type, _args) do
    flame_parent = FLAME.Parent.get()

    children =
      [
        CircleWeb.Telemetry,
        Circle.Repo,
        {DNSCluster, query: Application.get_env(:circle, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Circle.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: Circle.Finch},
        {
          FLAME.Pool,
          # 10 mins timeout
          name: Circle.FFMpegRunner,
          min: 0,
          max: 10,
          max_concurrency: 2,
          timeout: @flame_timeout,
          idle_shutdown_after: 30_000
        },
        !flame_parent && CircleWeb.Endpoint
      ]
      |> Enum.filter(& &1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Circle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CircleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
