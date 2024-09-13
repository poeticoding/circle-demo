defmodule Circle.Videos.FFMpeg.ProgressCollector do
  @moduledoc """
  Module which implements the `Collectable` protocol
  to parse the progress from stdout when running FFMpeg with `System.cmd`.
  It then broadcasts via pubsub the progress.
  """
  require Logger
  alias Circle.Videos

  defstruct [:video_id, :total_frames]

  def new(video_id, total_frames), do: %__MODULE__{video_id: video_id, total_frames: total_frames}

  defimpl Collectable, for: __MODULE__ do
    def into(coll) do
      Logger.metadata(video_id: coll.video_id)

      # Initial state (empty buffer)
      {:ok,
       fn
         _, {:cont, output} when is_binary(output) ->
           # Send output to the pid whenever there's new output

           case Regex.run(~r/frame\=(\d+)/, output) do
             [_, frame_str] ->
               Videos.pubsub_broadcast(
                 coll.video_id,
                 {:postprocessing, coll.video_id, {:progress, progress(coll, frame_str)}}
               )

               :ok

             error ->
               Logger.error("ProgressCollector.into/1 error: #{inspect(error)}")
               error
           end

         _, :done ->
           # When done, we can also send a :done message to the pid
           Videos.pubsub_broadcast(
             coll.video_id,
             {:postprocessing, coll.video_id, {:progress, :done}}
           )

           :ok

         _, :halt ->
           :ok

         _, _ ->
           :ok
       end}
    end

    defp progress(coll, frame_str) do
      round(String.to_integer(frame_str) * 100 / coll.total_frames)
    end
  end
end
