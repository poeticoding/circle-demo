defmodule Circle.Videos.Video do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "videos" do
    field :title, :string

    field :original_extension, :string
    field :original_filename, :string
    field :original_size, :integer
    field :original_uploaded_at, :utc_datetime

    field :web_uploaded_at, :utc_datetime
    field :preview_image_uploaded_at, :utc_datetime

    field :views_count, :integer
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :original_filename,
      :original_extension,
      :original_size,
      :original_uploaded_at,
      :web_uploaded_at,
      :preview_image_uploaded_at
    ])
  end

  def increment_views_count_query(video) do
    from(v in __MODULE__, where: v.id == ^video.id, update: [inc: [views_count: 1]])
  end
end
