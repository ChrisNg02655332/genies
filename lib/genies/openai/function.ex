defmodule Genies.Openai.Function do
  use Ecto.Schema
  import Ecto.Changeset

  alias Genies.Error
  alias Genies.Openai.Function

  require Logger

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:description, :string)
    field(:function, :any, virtual: true)
    field(:parameters, :map)
  end

  @create_fields ~w(name description parameters function)a
  @required_fields ~w(name)a

  def new(%{} = attrs \\ %{}) do
    %Function{}
    |> cast(attrs, @create_fields)
    |> common_validation()
    |> apply_action(:insert)
  end

  def new!(attrs \\ %{}) do
    case new(attrs) do
      {:ok, function} ->
        function

      {:error, changeset} ->
        raise Error, changeset
    end
  end

  defp common_validation(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> validate_length(:name, max: 64)
  end

  def execute(%Function{function: fun} = function, arguments, context) do
    Logger.debug("Executing function #{inspect(function.name)}")
    fun.(arguments, context)
  end
end
