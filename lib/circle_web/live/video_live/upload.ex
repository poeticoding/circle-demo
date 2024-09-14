defmodule CircleWeb.VideoLive.Upload do
  use CircleWeb, :live_view


  alias Circle.Videos
  alias Circle.Videos.Video
  alias Circle.VideoStore

  import CircleWeb.UploadComponents

  require Logger

  @impl true
  @max_file_size 5_000_000_000
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(Videos.change_video(%Video{}, %{})))
      |> assign(:processing_progress, nil)
      |> allow_upload(:video,
        accept: ~w(.mov .mp4 .avi),
        max_entries: 1,
        external: &presign_upload/2,
        max_file_size: @max_file_size
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Upload a new video")
  end

  @impl true
  def handle_event("validate-upload", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save-upload", _params, socket) do
    Logger.info("VideoLive.Upload: save-upload")

    video = socket.assigns.video
    key = video && VideoStore.key(video, :original)

    uploaded_video =
      consume_uploaded_entries(socket, :video, fn
        %{key: ^key}, %{cancelled?: false} = _entry ->
          {:ok, video} =
            Videos.update_video(video, %{
              original_uploaded_at: DateTime.utc_now()
            })

          Videos.process(video)

          {:ok, video}

        _, _entry ->
          {:error, :cancelled}
      end)
      |> List.first()

    socket = if uploaded_video, do: assign(socket, :processing_progress, 0), else: socket
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    Logger.info("VideoLive.Upload: cancel-upload")

    {:noreply,
     socket
     |> cancel_upload(:video, ref)
     |> assign(:video, nil)}
  end

  @impl true

  def handle_info({:postprocessing, _video_id, :started}, socket) do
    {:noreply, socket}
  end

  def handle_info({:preview_image, _video_id, :ready}, socket) do
    {:noreply, assign(socket, :preview_image, ~p"/videos/#{socket.assigns.video}/preview.jpg")}
  end

  def handle_info({:postprocessing, _video_id, {:progress, :done}}, socket) do
    {:noreply, socket}
  end

  def handle_info({:postprocessing, _video_id, {:progress, progress}}, socket) do
    {:noreply, assign(socket, :processing_progress, progress)}
  end

  def handle_info({:postprocessing, _video_id, :done}, socket) do
    socket =
      socket
      |> assign(:processing_progress, nil)
      |> redirect(to: ~p"/videos/#{socket.assigns.video}")

    {:noreply, socket}
  end

  def handle_info({:ffmpeg, _video_id, {:progress, :done}}, socket) do
    {:noreply, socket}
  end

  defp presign_upload(entry, socket) do
    uploads = socket.assigns.uploads

    case Videos.create_video(entry.client_name, entry.client_size) do
      {:ok, video} ->
        meta = VideoStore.presigned_upload_form_url(video, entry, uploads[entry.upload_config].max_file_size)
        # subscribing to get upload progress
        Videos.pubsub_subscribe(video.id)

        {:ok, meta, assign(socket, :video, video)}

      {:error, _changeset} = error ->
        error
    end
  end
end
