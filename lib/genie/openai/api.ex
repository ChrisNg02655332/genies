defmodule Genie.Openai.Api do
  alias Genie.Config

  @base_url "https://api.openai.com/v1"
  @receive_timeout 60_000

  def prepare(url) do
    Req.new(
      url: @base_url <> url,
      auth: {:bearer, get_api_key()},
      receive_timeout: @receive_timeout,
      retry: :transient,
      max_retries: 3,
      retry_delay: fn attempt -> 300 * attempt end
    )
    |> maybe_add_org_id_header()
    |> put_header("OpenAI-Beta", "assistants=v2")
  end

  def put_header(%Req.Request{} = req, key, value) do
    Req.Request.put_header(req, key, value)
  end

  defp get_api_key() do
    Config.resolve(:openai)[:api_key]
  end

  defp get_org_id() do
    Config.resolve(:openai)[:api_org]
  end

  defp maybe_add_org_id_header(%Req.Request{} = req) do
    org_id = get_org_id()

    if org_id do
      Req.Request.put_header(req, "OpenAI-Organization", org_id)
    else
      req
    end
  end
end
