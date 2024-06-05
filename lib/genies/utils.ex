defmodule Genies.Utils do
  defp translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      try do
        String.replace(acc, "%{#{key}}", to_string(value))
      rescue
        e ->
          IO.warn(
            """
            the fallback message translator for the form_field_error function cannot handle the given value.

            Hint: you can set up the `error_translator_function` to route all errors to your application helpers:

              config :genies, :error_translator_function, {MyAppWeb.ErrorHelpers, :translate_error}

            Given value: #{inspect(value)}

            Exception: #{Exception.message(e)}
            """,
            __STACKTRACE__
          )

          "invalid value"
      end
    end)
  end

  defp translator_from_config do
    case Application.get_env(:genies, :error_translator_function) do
      {module, function} -> &apply(module, function, [&1])
      nil -> nil
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    translate_error = translator_from_config() || (&translate_error/1)
    for {^field, {msg, opts}} <- errors, do: translate_error.({msg, opts})
  end

  @doc """
  Return changeset errors as text with comma separated description.
  """
  def changeset_error_to_string(%Ecto.Changeset{valid?: true}), do: nil

  def changeset_error_to_string(%Ecto.Changeset{valid?: false} = changeset) do
    fields = changeset.errors |> Keyword.keys() |> Enum.uniq()

    fields
    |> Enum.reduce([], fn f, acc ->
      field_errors =
        changeset.errors
        |> translate_errors(f)
        |> Enum.join(", ")

      acc ++ ["#{f}: #{field_errors}"]
    end)
    |> Enum.join("; ")
  end
end
