defmodule Genies.Openai.Thread.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Genies.Error
  alias Genies.Openai.Thread.Message
  alias Genies.Openai.Schema.MessageContent
  import Genies.Openai.Api

  require Logger

  @primary_key false
  embedded_schema do
    field(:id, :string)
    field(:object, :string)
    field(:created_at, :integer)
    field(:thread_id, :string)
    field(:role, Ecto.Enum, values: [:assistant, :user])

    embeds_many(:content, MessageContent)

    field(:file_ids, {:array, :string})
    field(:assistant_id, :string)
    field(:run_id, :string)

    field(:metadata, :map, default: %{})
  end

  @create_fields ~w(id object created_at thread_id role file_ids assistant_id run_id metadata)a

  def new(%{} = attrs \\ %{}) do
    %Message{}
    |> cast(attrs, @create_fields)
    |> cast_embed(:content)
    |> apply_action(:insert)
  end

  def new!(attrs \\ %{}) do
    case new(attrs) do
      {:ok, message} ->
        message

      {:error, changeset} ->
        raise Error, changeset
    end
  end

  def create(thread_id, chat_msg) do
    url = "/threads/#{thread_id}/messages"

    prepare(url)
    |> Req.post(body: Jason.encode!(Map.from_struct(chat_msg)))
    |> handle_response()
  end

  def list(thread_id) do
    url = "/threads/#{thread_id}/messages"

    prepare(url)
    |> Req.get()
    |> handle_response()
  end

  def retrieve(thread_id, message_id) do
    url = "/threads/#{thread_id}/messages"

    prepare(url <> "/#{message_id}")
    |> Req.get()
    |> handle_response()
  end

  def modify(thread_id, message_id, metadata) do
    url = "/threads/#{thread_id}/messages"

    prepare(url <> "/#{message_id}")
    |> Req.post(body: Jason.encode!(%{metadata: metadata}))
    |> handle_response()
  end

  defp handle_response(res) do
    res
    |> case do
      {:ok, %Req.Response{body: data}} ->
        case data["error"] do
          true ->
            {:error, data["error"]["message"]}

          _ ->
            case data["object"] do
              "list" -> data["data"] |> Enum.map(&Message.new!(&1))
              _ -> Message.new!(data)
            end
        end

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}

      other ->
        Logger.error("Unexpected and unhandled API response! #{inspect(other)}")
        other
    end
  end
end
