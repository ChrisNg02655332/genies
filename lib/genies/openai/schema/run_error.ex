defmodule Genies.Openai.Schema.RunError do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:code, Ecto.Enum, values: [:server_error, :rate_limit_exceeded])
    field(:message, :string)
  end

  def changeset(_, attrs) when is_nil(attrs), do: nil

  def changeset(run_error, attrs) do
    run_error
    |> cast(attrs, [:code, :message])
  end
end
