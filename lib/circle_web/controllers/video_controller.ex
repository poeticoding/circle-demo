defmodule CircleWeb.VideoController do
  use CircleWeb, :controller

  alias Circle.VideoStore
  alias Circle.Videos
  alias Circle.Videos.Video

  plug :fetch_video

  def show(conn, _params) do
    Videos.increment_views_count(conn.assigns.video)
    {:ok, url} = VideoStore.presigned_download_url(conn.assigns.video, :web)
    render(conn, "show.html", video_url: url)
  end

  def download(conn, _params) do
    {:ok, url} = VideoStore.presigned_download_url(conn.assigns.video, :web)
    redirect(conn, external: url)
  end

  def preview_image(conn, _params) do
    case VideoStore.get_preview_image(conn.assigns.video) do
      {:ok, image_data} ->
        send_download(conn, {:binary, image_data},
          filename: "preview.png",
          content_type: "image/png"
        )

      _ ->
        conn
        |> put_status(404)
        |> halt()
    end
  end

  defp fetch_video(conn, _opts) do
    case Videos.get_video(conn.params["id"]) do
      %Video{} = video ->
        assign(conn, :video, video)

      _ ->
        conn
        |> put_status(:not_found)
        |> halt()
    end
  end
end
