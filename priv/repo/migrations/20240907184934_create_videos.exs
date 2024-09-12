defmodule Circle.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string

      add :original_filename, :text, null: false
      add :original_extension, :string, null: false
      add :original_size, :bigint

      add :views_count, :bigint, default: 0, null: false

      add :original_uploaded_at, :utc_datetime
      add :web_uploaded_at, :utc_datetime
      add :preview_image_uploaded_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:videos, :original_uploaded_at)
    create index(:videos, :web_uploaded_at)
  end
end
