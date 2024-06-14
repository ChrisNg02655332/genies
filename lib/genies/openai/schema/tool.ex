defmodule Genies.Openai.Schema.Tool do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, Ecto.Enum, values: [:retrieval, :code_interpreter, :function])

    embeds_one :function, Function, primary_key: false do
      field(:name, :string)
      field(:description, :string)
      field(:parameters, :map)
    end
  end

  def changeset(_, attrs) when is_nil(attrs), do: nil

  def changeset(tool, attrs) do
    tool
    |> cast(attrs, [:type])
    |> cast_embed(:function, with: &function_changeset/2)
  end

  def function_changeset(function, attrs \\ %{}) do
    function
    |> cast(attrs, [:name, :description, :parameters])
  end
end
