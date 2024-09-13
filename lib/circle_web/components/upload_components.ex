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
end
