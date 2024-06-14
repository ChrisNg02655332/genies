defmodule Genies.Openai.Chain do
  @moduledoc """
  The Chain context
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Genies.Error
  alias Genies.Openai.{Assistant, Function, Chain, Message, Thread}

  @primary_key false
  embedded_schema do
    field(:assistant_id, :string)
    field(:thread_id, :string)
    field(:functions, {:array, :any}, default: [], virtual: true)
    field(:_function_map, :map, default: %{}, virtual: true)
  end

  @create_fields ~w(assistant_id thread_id)a
  @required_fields ~w(assistant_id)a

  def new(%{} = attrs \\ %{}) do
    %Chain{}
    |> cast(attrs, @create_fields)
    |> common_validation()
    |> apply_action(:insert)
  end

  def new!(attrs \\ %{}) do
    case new(attrs) do
      {:ok, chain} ->
        chain

      {:error, changeset} ->
        raise Error, changeset
    end
  end

  def common_validation(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> build_functions_map_from_functions()
  end

  def add_functions(%Chain{} = chain, %Function{} = function) do
    add_functions(chain, [function])
  end

  def add_functions(%Chain{functions: existing} = chain, functions) when is_list(functions) do
    updated = existing ++ functions

    chain
    |> change()
    |> cast(%{functions: updated}, [:functions])
    |> build_functions_map_from_functions()
    |> apply_action!(:update)
  end

  defp build_functions_map_from_functions(changeset) do
    functions = get_field(changeset, :functions, [])

    # get a list of all the functions indexed into a map by name
    fun_map =
      Enum.reduce(functions, %{}, fn f, acc ->
        Map.put(acc, f.name, f)
      end)

    put_change(changeset, :_function_map, fun_map)
  end

  def add_message(%Chain{} = chain, %Message{} = message) do
    Thread.Message.create(chain.thread_id, message)
    chain
  end

  @doc """
  Runs a chain

  ## Example
    
    iex> %{assistant_id: assistant.asst_id, thread_id: thread_id}
          |> Chain.new!()
          |> Chain.run()

  """
  def run(%Chain{} = chain) do
    tools =
      chain.functions
      |> Enum.map(fn item ->
        %{
          type: "function",
          function: %{name: item.name, description: item.description, parameters: item.parameters}
        }
      end)

    if length(tools) > 0 do
      Assistant.modify(chain.assistant_id, %{tools: tools})
    end

    run = Thread.Run.create(chain.assistant_id, chain.thread_id)
    excute_run_fn(chain._function_map, run.thread_id, run.id)
  end

  defp excute_run_fn(function_map, thread_id, run_id) do
    Process.sleep(500)
    run = Thread.Run.retrieve(thread_id, run_id)

    case run.status do
      :queued ->
        excute_run_fn(function_map, run.thread_id, run.id)

      :in_progress ->
        excute_run_fn(function_map, thread_id, run_id)

      :requires_action ->
        tool_call_id =
          List.first(run.required_action.submit_tool_outputs["tool_calls"], %{})["id"]

        function =
          List.first(run.required_action.submit_tool_outputs["tool_calls"], %{})["function"]

        args =
          case Jason.decode(function["arguments"]) do
            {:ok, args} ->
              args

            {:error, error} ->
              dbg(error)
              %{}
          end

        func = function_map[function["name"]]

        result = if !is_nil(func), do: func.function.(args), else: ""

        Thread.Run.submit_tool_out_put(thread_id, run.id, [
          %{tool_call_id: tool_call_id, output: result}
        ])

        excute_run_fn(function_map, thread_id, run_id)

      :completed ->
        [message | _] = Thread.Message.list(run.thread_id)
        message
    end
  end
end
