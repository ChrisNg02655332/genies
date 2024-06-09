# Genie

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `genies` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:genie, "~> 0.0.1"}
  ]
end
```

## Configuration
You can configure openai in your mix config.exs (default $project_root/config/config.exs). If you're using Phoenix add the configuration in your config/dev.exs|test.exs|prod.exs files. An example config is:

```elixir
import Config

config :genies, :openai, 
    # find it at https://platform.openai.com/account/api-keys
    api_key: System.get_env("OPENAI_API_KEY"),
    # find it at https://platform.openai.com/account/org-settings under "Organization ID"
    api_org: System.get_env("OPENAI_ORG")
```
Note: you can load your os ENV variables in the configuration file, if you set an env variable for API key named `OPENAI_API_KEY` you can get it in the code by doing `System.get_env("OPENAI_API_KEY")`.

⚠️`config.exs` is compile time, so the `get_env/1` function is executed during the build, if you want to get the env variables during runtime please use `runtime.exs` instead of `config.exs` in your application ([elixir doc ref](https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html#configuration)).

## Usage overview
Get your API key from https://platform.openai.com/account/api-keys

### retrieve(assistant_id)
Retrieves an assistant by its id.
  
#### Example request
```elixir
Genies.Openai.Assistant.retrieve("asst_...")
```
#### Example response
```elixir
{:ok, %Assistant{}}
```
See: https://platform.openai.com/docs/api-reference/assistants/getAssistant

### create(params)
Creates a new assistant.

#### Example request
```elixir
Genies.Openai.Assistant.create(%Assistant{})
{:ok, %Assistant{}}
```

### modify(assistant_id, attrs)
Modifies an existing assistant.

#### Example request
```elixir
Genies.Openai.Assistant.modify(
  "asst_...",
  %{name: "My upgraded assistant"}
)
```

#### Example response
```elixir
{:ok, %Assistant{}}
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/genies>.

