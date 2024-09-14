defmodule Circle.VideoStore do
  alias Circle.SimpleS3Upload

  @tigris_host "fly.storage.tigris.dev"

  @presigned_url_default_options [
    expires_in: 300
  ]

  def bucket, do: System.fetch_env!("BUCKET_NAME")

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

  def key(video, :web) do
    Path.join(["videos", video.id, "web.mp4"])
  end

  def put(key, content, options \\ []) do
    ExAws.S3.put_object(bucket(), key, content, options)
    |> ExAws.request()
  end

  def put_preview_image(video, data) do
    put(key(video, :preview_image), data, content_type: "image/jpg")
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
  end

  ## PRESIGNED URL
  def presigned_download_url(video, version \\ :original, opts \\ []) do
    opts = Keyword.merge(@presigned_url_default_options, opts)

    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(:get, bucket(), key(video, version), opts)
  end

  @spec presigned_upload_form_url(Video.t(), Phoenix.LiveView.UploadEntry.t(), integer()) :: map()
  def presigned_upload_form_url(video, entry, max_file_size) do
    bucket = bucket()
    key = key(video, :original)

    config = %{
      region: System.get_env("AWS_REGION", "auto"),
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(config, bucket,
        key: key,
        content_type: entry.client_type,
        max_file_size: max_file_size,
        expires_in: :timer.hours(1)
      )

    host =
      Application.get_env(:ex_aws, :s3)
      |> Keyword.fetch!(:host)
      |> URI.parse()
      |> Map.get(:host, @tigris_host)

    url = "https://#{bucket}.#{host}"

    %{
      uploader: "Tigris",
      key: key,
      url: url,
      fields: fields
    }
  end
end
