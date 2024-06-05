defmodule Genies.Openai.Schema.MessageContent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Genies.Openai.Schema.MessageContent.{Text, Image}

  @primary_key false
  embedded_schema do
    field(:type, Ecto.Enum, values: [:image_file, :text])
    embeds_one(:text, Text)
    embeds_one(:image, Image)
  end

  def changeset(content, attrs) do
    content
    |> cast(attrs, [:type])
    |> cast_embed(:text)
    |> cast_embed(:image)
  end
end

defmodule Genies.Openai.Schema.MessageContent.Text do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:value, :string)
    field(:annotations, {:array, :map})
  end

  def changeset(_, attrs) when is_nil(attrs), do: nil

  def changeset(text, attrs) do
    text
    |> cast(attrs, [:value, :annotations])
  end
end

defmodule Genies.Openai.Schema.MessageContent.Image do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:image_file, :map)
  end

  def changeset(_, attrs) when is_nil(attrs), do: nil

  def changeset(image, attrs) do
    image
    |> cast(attrs, [:image_file])
  end
end
