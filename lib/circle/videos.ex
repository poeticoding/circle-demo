defmodule Circle.Videos do
  @moduledoc """
  The Videos context.
  """

  import Ecto.Query, warn: false
  alias Circle.Repo
  alias Circle.Videos.FFMpeg
  alias Circle.Videos.Video
  alias Circle.VideoStore

  require Logger

  @flame_timeout 10 * 60_000

  def get_video(id) do
    Repo.get(Video, id)
  end

  @doc """
  Creates a video with the given `filename` and `size`.
  """
  def create_video(filename, size) do
    %Video{}
    |> Video.changeset(%{
      title: filename,
      original_filename: filename,
      original_extension: Path.extname(String.downcase(filename)),
      original_size: size
    })
    |> Repo.insert()
  end

  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  def increment_views_count(video) do
    video
    |> Video.increment_views_count_query()
    |> Repo.update_all([])
  end

  @doc """
  Runs a FLAME job to:
  1. Extract the preview image and uploads it to the cloud store.
  2. Resize the video and make it compatible to be played by the web player.
  """
  def process(video) do
    Logger.metadata(video_id: video.id)

    FLAME.place_child(
      Circle.FFMpegRunner,
      Task.child_spec(fn ->
        pubsub_broadcast(video, {:postprocessing, video.id, :started})

        with {:ok, video} <- generate_preview_image(video),
             {:ok, video} <- resize(video, :web) do
          {:ok, video}
        else
          error ->
            Logger.error("FFMpegRunner resize error: #{inspect(error)}")
            error
        end
        |> tap(fn _ -> pubsub_broadcast(video, {:postprocessing, video.id, :done}) end)
      end),
      timeout: @flame_timeout
    )
  end

  defp resize(video, version) do
    resized_video_path =
      Path.join([System.tmp_dir!(), "#{Atom.to_string(version)}_#{video.id}.mp4"])

    with {:download_url, {:ok, url}} <-
           {:download_url, VideoStore.download_presigned_url(video, :original)},
         {:total_frames, {:ok, total_frames}} <- {:total_frames, FFMpeg.get_total_frames(url)},
         {:ffmpeg_resize, {_output, 0}} <-
           {:ffmpeg_resize,
            FFMpeg.resize(url, resized_video_path, version, video.id, total_frames)},
         {:upload, {:ok, _}} <-
           {:upload, VideoStore.save_video_file(video, resized_video_path, version)},
         {:update, {:ok, video}} <-
           {:update, update_video(video, %{web_uploaded_at: DateTime.utc_now()})} do
      # removing local temporary file
      Logger.info("Resized to #{version} and saved to Tigris")
      File.rm!(resized_video_path)
      {:ok, video}
    end
  end

  def generate_preview_image(video) do
    local_preview_image_path = Path.join([System.tmp_dir!(), Ecto.UUID.generate() <> ".jpg"])

    with {:presigned_url, {:ok, original_url}} <-
           {:presigned_url, VideoStore.download_presigned_url(video, :original)},
         {:ffmpeg, {_, 0}} <-
           {:ffmpeg, FFMpeg.generate_preview_image(original_url, local_preview_image_path)},
         {:read_image, {:ok, image_data}} <- {:read_image, File.read(local_preview_image_path)},
         {:upload, {:ok, _}} <-
           {:upload, VideoStore.put_preview_image(video, image_data)},
         {:update, {:ok, video}} <-
           {:update, update_video(video, %{preview_image_uploaded_at: DateTime.utc_now()})} do
      File.rm!(local_preview_image_path)
      pubsub_broadcast(video, {:preview_image, video.id, :ready})
      {:ok, video}
    else
      error ->
        Logger.error("Videos.resize/2 ERROR: #{inspect(error)}")
        error
    end
  end

  ### PubSub
  def pubsub_subscribe(video_id) do
    Phoenix.PubSub.subscribe(Circle.PubSub, pubsub_topic(video_id))
  end

  def pubsub_broadcast(video_id, message) do
    Phoenix.PubSub.broadcast(Circle.PubSub, pubsub_topic(video_id), message)
  end

  defp pubsub_topic(video_id) do
    "video:#{video_id}"
  end
end
