defmodule Circle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CircleWeb.Telemetry,
      Circle.Repo,
      {DNSCluster, query: Application.get_env(:circle, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Circle.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Circle.Finch},
      # Start a worker by calling: Circle.Worker.start_link(arg)
      # {Circle.Worker, arg},
      # Start to serve requests, typically the last entry
      CircleWeb.Endpoint
    ]

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
