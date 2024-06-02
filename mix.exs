defmodule Genie.MixProject do
  use Mix.Project

  @source_url "https://github.com/ChrisNg02655332/genie.git"
  @version "0.0.1"

  def project do
    [
      app: :genies,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.4.0"},
      {:ecto, "~> 3.0"}
    ]
  end

  defp description() do
    """
    This library wraps API to integrate with external AI such as openai 
    """
  end

  defp package do
    [
      maintainers: ["Chris Nguyen"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(mix.exs lib README.md LICENSE.md)
    ]
  end
end
