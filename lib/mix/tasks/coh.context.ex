defmodule Mix.Tasks.Coh.Context do
  @shortdoc "Generates a context with functions around an Ecto schema representing a User"

  @moduledoc """
  Generates a context with functions around an Ecto schema representing a User.
      mix coh.context Accounts name:string email:string
  """
  
  # Code shamelessly stolen from the Phx default context generator with minor changes

  use Mix.Task

  alias Mix.Phoenix.{Context}
  alias Mix.Tasks.Phx.Gen

  @switches [binary_id: :boolean, table: :string, web: :string,
             schema: :boolean, context: :boolean, context_app: :string]

  @default_opts [schema: true, context: true]

  # Hardcoded schema name:
  @schema_name "User"
  @plural "users"

  @doc false
  def run(args) do
    if Mix.Project.umbrella? do
      Mix.raise "mix coh.context can only be run inside an application directory"
    end

    {context, schema} = build(args)
    binding = [context: context, schema: schema]
    # Use the Coherence templates instead of the phoenix templates
    # unless no such template is defined by Coherence, in which case
    # reuse the corresponding phoenix template.
    # This allows us to override some functions but still use the Phx
    # generators to do some of the heavy lifting
    paths = coherence_generator_paths()

    prompt_for_conflicts(context)

    context
    |> copy_new_files(paths, binding)
    |> print_shell_instructions()
  end

  defp coherence_generator_paths do
    # We need to provide our own paths to the templates.
    # The :phoenix app must be added to the path because we call some
    # phoenix functions that use templates defined in the phoenix repo
    # but use the path we supply as argument instead of the one defined
    # in their mix task.
    [".", :coherence, :phoenix]
  end

  defp prompt_for_conflicts(context) do
    context
    |> files_to_be_generated()
    |> Mix.Phoenix.prompt_for_conflicts()
  end

  @doc false
  def build(args) do
    {opts, parsed, _} = parse_opts(args)
    [context_name | schema_args] = validate_args!(parsed)
    # Use the hardcoded schema name and plural instead of parsing it from the arguments
    # The next two lines are the only major difference from the default Phx generator mix task
    schema_module = inspect(Module.concat(context_name, @schema_name))
    schema = Gen.Schema.build([schema_module, @plural | schema_args], opts, __MODULE__)
    context = Context.new(context_name, schema, opts)
    {context, schema}
  end

  defp parse_opts(args) do
    {opts, parsed, invalid} = OptionParser.parse(args, switches: @switches)
    merged_opts =
      @default_opts
      |> Keyword.merge(opts)
      |> put_context_app(opts[:context_app])

    {merged_opts, parsed, invalid}
  end
  defp put_context_app(opts, nil), do: opts
  defp put_context_app(opts, string) do
    Keyword.put(opts, :context_app, String.to_atom(string))
  end

  @doc false
  def files_to_be_generated(%Context{schema: schema}) do
    if schema.generate? do
      Gen.Schema.files_to_be_generated(schema)
    else
      []
    end
  end

  @doc false
  def copy_new_files(%Context{schema: schema} = context, paths, binding) do
    if schema.generate?, do: Gen.Schema.copy_new_files(schema, paths, binding)
    inject_schema_access(context, paths, binding)
    inject_tests(context, paths, binding)

    context
  end

  defp inject_schema_access(%Context{file: file} = context, paths, binding) do
    unless Context.pre_existing?(context) do
      Mix.Generator.create_file(file, Mix.Phoenix.eval_from(paths, "priv/templates/coh.context/context.ex", binding))
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/coh.context/schema.ex", binding)
    |> inject_eex_before_final_end(file, binding)
  end

  defp write_file(content, file) do
    File.write!(file, content)
  end

  defp inject_tests(%Context{test_file: test_file} = context, paths, binding) do
    unless Context.pre_existing_tests?(context) do
      Mix.Generator.create_file(test_file, Mix.Phoenix.eval_from(paths, "priv/templates/coh.context/context_test.exs", binding))
    end
  
    paths
    |> Mix.Phoenix.eval_from("priv/templates/coh.context/test_cases.exs", binding)
    |> inject_eex_before_final_end(test_file, binding)
  end

  defp inject_eex_before_final_end(content_to_inject, file_path, binding) do
    file = File.read!(file_path)

    if String.contains?(file, content_to_inject) do
      :ok
    else
      Mix.shell.info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      file
      |> String.trim_trailing()
      |> String.trim_trailing("end")
      |> EEx.eval_string(binding)
      |> Kernel.<>(content_to_inject)
      |> Kernel.<>("end\n")
      |> write_file(file_path)
    end
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema}) do
    if schema.generate? do
      Gen.Schema.print_shell_instructions(schema)
    else
      :ok
    end
  end

  defp validate_args!([context | _] = args) do
    cond do
      not Context.valid?(context) ->
        raise_with_help "Expected the context, #{inspect context}, to be a valid module name"
      true ->
        args
    end
  end

  defp validate_args!(_) do
    raise_with_help "Invalid arguments"
  end

  @doc false
  @spec raise_with_help(String.t) :: no_return()
  def raise_with_help(msg) do
    Mix.raise """
    #{msg}
    mix coh.context expect a context module name followed by any number of attributes.
    These attributes must be present in the YourApp.Coherence.User module generated by Coherence.
    This is not checked in any way, so be sure you supply the correct attributes and types.
    For example:

        mix coh.context Accounts name:string email:string
    
    The context serves as the API boundary for the given resource.
    Multiple resources may belong to a context and a resource may be
    split over distinct contexts (such as Accounts.User and Payments.User).
    """
  end
end