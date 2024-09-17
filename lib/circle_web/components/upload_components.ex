defmodule CircleWeb.UploadComponents do
  use Phoenix.Component

  @doc """
  Shows the upload progress bar

  ## Examples

      <.progress_bar color="blue" label={entry.client_name} progress={entry.progress} />
  """
  attr :label, :string, required: true
  attr :progress, :integer, required: true
  attr :color, :string

  def progress_bar(assigns) do
    ~H"""
    <div class="flex mb-2 items-center justify-between">
      <div>
        <span class={"text-xs font-semibold inline-block py-1 px-2 uppercase rounded-full text-#{@color}-600 bg-#{@color}-200"}>
          <%= @label %>
        </span>
      </div>

      <div class="text-right">
        <span class={"text-xs font-semibold inline-block text-#{@color}-600"}>
          <%= @progress %>%
        </span>
      </div>
    </div>

    <div class={"w-full rounded-full h-2.5 bg-#{@color}-100 dark:bg-#{@color}-100"}>
      <div class={"bg-#{@color}-600 h-2.5 rounded-full"} style={"width: #{@progress}%"}></div>
    </div>
    """
  end

  attr :video_id, :string
  attr :title, :string

  def video_meta(assigns) do
    ~H"""
    <meta property="og:title" content={@title} />
    <!-- A brief description of your video content -->
    <meta property="og:description" content={@title} />
    <!-- The URL of your content -->
    <meta property="og:url" content={"https://circle.poeticoding.com/videos/#{@video_id}"} />
    <!-- The type of content; for videos, use 'video.other' -->
    <meta property="og:type" content="video.other" />
    <!-- The URL of the video file or video landing page -->
    <meta property="og:video" content={"https://circle.poeticoding.com/videos/#{@video_id}"} />
    <!-- The URL of the preview image (thumbnail) for your video -->
    <meta
      property="og:image"
      content={"https://circle.poeticoding.com/videos/#{@video_id}/preview.jpg"}
    />
    <!-- The width and height of the video, optional but recommended -->
    <meta property="og:video:width" content="1920" />
    <meta property="og:video:height" content="1080" />
    <!-- The MIME type of the video -->
    <meta property="og:video:type" content="video/mp4" />
    <!-- If your video is hosted on YouTube or Vimeo, you may also want to include the following -->
    <meta property="og:video:url" content={"https://circle.poeticoding.com/videos/#{@video_id}"} />
    """
  end
end
