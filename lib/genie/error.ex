defmodule Genies.Error do
  import Genies.Utils, only: [changeset_error_to_string: 1]
  alias Genies.Error

  @type t :: %Error{}
  defexception [:message]

  @doc """
  Create the exception using either a message or a changeset who's errors are
  converted to a message.
  """
  @spec exception(message :: String.t() | Ecto.Changeset.t()) :: t()
  def exception(message) when is_binary(message) do
    %Error{message: message}
  end

  def exception(%Ecto.Changeset{} = changeset) do
    text_reason = changeset_error_to_string(changeset)
    %Error{message: text_reason}
  end
end
