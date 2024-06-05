defmodule Genies.Openai.Thread.Run do
  use Ecto.Schema
  import Ecto.Changeset

  alias Genies.Error
  alias Genies.Openai.Thread.Run
  alias Genies.Openai.Schema.{RunError, RunRequiredAction, Tool}

  import Genies.Openai.Api

  require Logger

  @status ~w(queued in_progress requires_action cancelling cancelled failed completed expired)a

  @primary_key false
  embedded_schema do
    field(:id, :string)
    field(:object, :string)
    field(:created_at, :integer)
    field(:assistant_id, :string)
    field(:thread_id, :string)
    field(:status, Ecto.Enum, values: @status)
    embeds_one(:required_action, RunRequiredAction)
    field(:started_at, :integer)
    field(:expires_at, :integer)
    field(:cancelled_at, :integer)
    field(:failed_at, :integer)
    field(:completed_at, :integer)
    embeds_one(:last_error, RunError)
    field(:model, :string)
    field(:instructions, :string)
    embeds_many(:tools, Tool)
    field(:file_ids, {:array, :string})
    field(:metadata, :map, default: %{})
  end

  @create_fields ~w(id object created_at assistant_id thread_id status started_at expires_at cancelled_at failed_at completed_at model instructions file_ids metadata)a

  def new(%{} = attrs \\ %{}) do
    %Run{}
    |> cast(attrs, @create_fields)
    |> cast_embed(:last_error)
    |> cast_embed(:tools)
    |> cast_embed(:required_action)
    |> apply_action(:insert)
  end

  def new!(attrs \\ %{}) do
    case new(attrs) do
      {:ok, run} ->
        run

      {:error, changeset} ->
        raise Error, changeset
    end
  end

  # TODO: can apply paging with query params
  # https://platform.openai.com/docs/api-reference/runs/listRuns
  def list(thread_id) do
    url = "/threads/#{thread_id}/runs"

    prepare(url)
    |> Req.get()
    |> handle_response()
  end

  def create(assistant_id, thread_id) do
    url = "/threads/#{thread_id}/runs"

    prepare(url)
    |> Req.post(body: Jason.encode!(%{assistant_id: assistant_id}))
    |> handle_response()
  end

  def retrieve(thread_id, run_id) do
    url = "/threads/#{thread_id}/runs/#{run_id}"

    prepare(url)
    |> Req.get()
    |> handle_response()
  end

  # NOTE: Cancels a run that is in_progress.
  # https://platform.openai.com/docs/api-reference/runs/cancelRun
  def cancel(thread_id, run_id) do
    url = "/threads/#{thread_id}/runs/#{run_id}"

    prepare(url)
    |> Req.post()
    |> handle_response()
  end

  @doc """
    tool_outputs is a list
    https://platform.openai.com/docs/api-reference/runs/submitToolOutputs?lang=curl
  """
  def submit_tool_out_put(thread_id, run_id, tool_outputs) do
    url = "/threads/#{thread_id}/runs/#{run_id}/submit_tool_outputs"

    prepare(url)
    |> Req.post(body: Jason.encode!(%{tool_outputs: tool_outputs}))
  end

  defp handle_response(res) do
    res
    |> case do
      {:ok, %Req.Response{body: data}} ->
        case data["object"] do
          "list" -> data["data"] |> Enum.map(&Run.new!(&1))
          _ -> Run.new!(data)
        end

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}

      other ->
        Logger.error("Unexpected and unhandled API response! #{inspect(other)}")
        other
    end
  end
end
