defmodule Circle.VideoStore do
  alias Circle.Videos

  @bucket "circle-dev"

  @presigned_url_default_options [
    expires_in: 300
  ]

  def bucket, do: @bucket

  @doc """
  `:preview_image` videos' thumbnail
  `:original` original uploaded video
  `:web` video used by the app player
  """
  def key(video, :preview_image) do
    Path.join(["videos", video.id, "preview.jpg"])
  end

  def key(video, :original) do
    Path.join(["videos", video.id, "original#{video.original_extension}"])
  end

  def object_key(video, :web) do
    Path.join(["videos", video.id, "web.mp4"])
  end

  def put(key, content, options \\ []) do
    ExAws.S3.put_object(bucket(), key, content, options)
    |> ExAws.request()
  end

  def put_preview_image(video, data) do
    put(object_key(video, :preview_image), data, content_type: "image/jpg")
  end

  def get(key) do
    ExAws.S3.get_object(bucket(), key)
    |> ExAws.request()
    |> then(fn
      {:ok, %{body: data}} -> {:ok, data}
      error -> error
    end)
  end

  def get_preview_image(video) do
    video
    |> key(:preview_image)
    |> get()
  end

  def save_video_file(video, local_video_path, version) do
    local_video_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket(), key(video, version), content_type: "video/mp4")
    |> ExAws.request()
    |> case do
      {:ok, _} ->
        Videos.update_video(video, %{web_uploaded_at: DateTime.utc_now()})

      error ->
        error
    end
  end

  def download_presigned_url(video, version \\ :original, opts \\ []) do
    opts = Keyword.merge(@presigned_url_default_options, opts)

    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(:get, bucket(), object_key(video, version), opts)
  end
end
