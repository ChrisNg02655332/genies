defmodule Genies.Openai do
  alias Genies.Openai.Assistant

  def assistants(asst_id), do: Assistant.retrieve(asst_id)
end
