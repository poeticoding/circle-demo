defmodule Circle.Videos.FFMpeg do
  @moduledoc """
  Functions to generate thumbnail, resize video
  """
  alias Circle.Videos.FFMpeg.ProgressCollector

  require Logger

  @doc """
  Runs `ffmpeg` to resize the original video
  `url`: original video presigned url
  `resized_video_path`: output video path
  `version`: atom (at the moment only :web), to get the right ffmpeg args
  `video_id`: DB video id
  `total_frames`: total number of frames (you can get with `get_total_frames`).
                  Needed to calculate the progress.

  Returns {output, exit_code}
  """
  def resize(url, resized_video_path, version, video_id, total_frames) do
    progress_collector = ProgressCollector.new(video_id, total_frames)

    System.cmd("ffmpeg", resize_args(url, resized_video_path, version), into: progress_collector)
  end

  @doc """
  Runs `ffprobe` to get the number of frames of the video.
  Returns the number of frames.
  """
  @spec get_total_frames(String.t()) :: {:ok, integer()} | {:error, String.t()}
  def get_total_frames(original_url) do
    {output, 0} =
      System.cmd("ffprobe", [
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=avg_frame_rate,duration",
        "-of",
        "csv=p=0",
        original_url
      ])

    regex = ~r/(?<frame_rate>\d+\/\d+|\d+\.\d+),\s*(?<duration>\d+\.\d+)/

    case Regex.run(regex, output) do
      [_, frame_rate_str, duration_str] ->
        # Parse frame rate and duration
        frame_rate = parse_frame_rate(frame_rate_str)
        duration = String.to_float(duration_str)

        # Calculate total number of frames
        total_frames = Float.round(frame_rate * duration) |> trunc()
        Logger.info("Total frames: #{total_frames}")
        {:ok, total_frames}

      _ ->
        {:error, "error parsing ffprobe"}
    end
  end

  defp parse_frame_rate(frame_rate_str) do
    case String.split(frame_rate_str, "/") do
      [numerator, denominator] ->
        String.to_integer(numerator) / String.to_integer(denominator)

      [frame_rate] ->
        String.to_integer(frame_rate)
    end
  end

  @doc """
  Runs FFMpeg to generate the preview image.
  """
  def generate_preview_image(url, image_path) do
    System.cmd("ffmpeg", [
      "-i",
      url,
      "-ss",
      "00:00:01",
      "-frames:v",
      "1",
      "-vf",
      "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2",
      image_path
    ])
  end

  defp resize_args(original_url, local_tmp_path, :web) do
    [
      "-i",
      original_url,
      "-aspect",
      "16:9",
      "-vf",
      "scale=1920:1280:force_original_aspect_ratio=decrease,pad=1920:1280:(ow-iw)/2:(oh-ih)/2:black",
      "-c:v",
      "h264",
      "-level",
      "4.0",
      "-profile:v",
      "main",
      "-pix_fmt",
      # 4:2:0 chroma subsampling
      "yuv420p",
      "-preset",
      "medium",
      # Ensure the frame rate does not exceed 60fps
      "-r",
      "30",
      "-maxrate",
      "2M",
      "-bufsize",
      "4M",
      # "slow",
      # "ultrafast",
      # "-crf",
      # "23",
      "-c:a",
      "aac",
      "-b:a",
      "96k",
      "-movflags",
      "+faststart",
      "-progress",
      "pipe:1",
      "-hide_banner",
      "-loglevel",
      "error",
      local_tmp_path
    ]
  end
end
