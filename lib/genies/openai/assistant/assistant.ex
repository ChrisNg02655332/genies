defmodule Genies.Openai.Assistant do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  @url "/assistants"
  @derive {Jason.Encoder, only: [:name, :model, :instructions, :tools, :file_ids]}

  alias Genies.Error
  alias Genies.Openai.Assistant
  alias Genies.Openai.Schema.Tool

  import Genies.Openai.Api

  @create_fields ~w(id model object created_at name description instructions file_ids metadata)a
  @required_fields ~w(model name instructions)a

  @primary_key false
  embedded_schema do
    field(:id, :string)
    field(:model, :string, default: "gpt-3.5-turbo")
    field(:object, :string)
    field(:created_at, :integer)
    field(:name, :string)
    field(:description, :string)
    field(:instructions, :string)
    embeds_many(:tools, Tool)
    field(:file_ids, {:array, :string}, default: [])
    field(:metadata, :map, default: %{})
  end

  def new(%{} = attrs \\ %{}) do
    %Assistant{}
    |> cast(attrs, @create_fields)
    |> cast_embed(:tools)
    |> common_validation()
    |> apply_action(:insert)
  end

  def new!(attrs \\ %{}) do
    case new(attrs) do
      {:ok, assistant} ->
        assistant

      {:error, changeset} ->
        raise Error, changeset
    end
  end

  defp common_validation(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def create(%Assistant{} = attrs) do
    prepare(@url)
    |> Req.post(body: Jason.encode!(attrs))
    |> handle_response()
  end

  def modify(assist_id, attrs) do
    prepare(@url <> "/#{assist_id}")
    |> Req.post(body: Jason.encode!(attrs))
    |> handle_response()
  end

  def retrieve(assist_id) do
    prepare(@url <> "/#{assist_id}")
    |> Req.get()
    |> handle_response()
  end

  def delete(assist_id) do
    prepare(@url <> "/#{assist_id}")
    |> Req.delete()
    |> handle_response(:delete)
  end

  defp handle_response(res, method \\ nil) do
    res
    |> case do
      {:ok, %Req.Response{body: data}} ->
        case method do
          :delete -> %{id: data["id"], object: data["object"], deleted: data["deleted"]}
          _ -> Assistant.new!(data)
        end

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}

      other ->
        Logger.error("Unexpected and unhandled API response! #{inspect(other)}")
        other
    end
  end
end
