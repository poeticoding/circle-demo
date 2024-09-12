defmodule Circle.Repo do
  use Ecto.Repo,
    otp_app: :circle,
    adapter: Ecto.Adapters.Postgres
end
