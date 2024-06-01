defmodule Genie.Openai.Tool do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, Ecto.Enum, values: [:retrieval, :code_interpreter, :function])
  end

  def changeset(_, attrs) when is_nil(attrs), do: nil

  def changeset(tool, attrs) do
    tool
    |> cast(attrs, [:type])
  end
end
