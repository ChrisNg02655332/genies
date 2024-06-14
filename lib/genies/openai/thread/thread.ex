defmodule Genies.Openai.Thread do
  @moduledoc """
  The Thread context 
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Genies.Error
  alias Genies.Openai.Thread
  import Genies.Openai.Api

  require Logger

  @url "/threads"

  @primary_key false
  embedded_schema do
    field(:id, :string)
    field(:object, :string)
    field(:created_at, :integer)
    field(:metadata, :map, default: %{})
  end

  @create_fields ~w(id object created_at metadata)a

  def new(%{} = attrs \\ %{}) do
    %Thread{}
    |> cast(attrs, @create_fields)
    |> apply_action(:insert)
  end

  def new!(attrs \\ %{}) do
    case new(attrs) do
      {:ok, thread} ->
        thread

      {:error, changeset} ->
        raise Error, changeset
    end
  end

  @doc """
  Creates a new thread.

  See: https://platform.openai.com/docs/api-reference/threads/createThread

  ## Example request
    
    iex> create(%{})
    {:ok, %Thread{}}

  """
  def create(attrs \\ %{}) do
    prepare(@url)
    |> Req.post(body: Jason.encode!(attrs))
    |> handle_response()
  end

  @doc """
  Retrieves a single thread.

  See: https://platform.openai.com/docs/api-reference/threads/getThread

  ## Example request
    
    iex> retrieve("thread_")
    {:ok, %Thread{}}

  """
  def retrieve(thread_id) do
    prepare(@url <> "/#{thread_id}")
    |> Req.get()
    |> handle_response()
  end

  @doc """
  Retrieves a single thread.

  See: https://platform.openai.com/docs/api-reference/threads/deleteThread

  ## Example request
    
    iex> delete("thread_")
    {:ok, 
      %{
        "id": "asst_abc123",
        "object": "assistant.deleted",
        "deleted": true
      }
    }

  """

  def delete(thread_id) do
    prepare(@url <> "/#{thread_id}")
    |> Req.delete()
    |> handle_response(:delete)
  end

  defp handle_response(res, method \\ nil) do
    res
    |> case do
      {:ok, %Req.Response{body: data}} ->
        case method do
          :delete -> %{id: data["id"], object: data["object"], deleted: data["deleted"]}
          _ -> Thread.new!(data)
        end

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}

      other ->
        Logger.error("Unexpected and unhandled API response! #{inspect(other)}")
        other
    end
  end
end
