defmodule Mix.Tasks.Coherence.Gen.Controllers do
  @moduledoc """
  Generate Coherence controllers.

  Use this task to generate the Coherence controllers when
  you what to customize the controllers' behavior.

  ## Examples

      # Install all the controllers for the coherence opts
      # defined in your `config/config.exs` file
      mix coherence.gen.controllers

  Once the controllers have been generated, you must update your
  `router.ex` file to properly scope the generated controller(s).

  For example:

      # lib/my_app_web
      def MyApp.Router do
        # ...

        scope "/", MyApp do
          pipe_through :browser
          coherence_routes()
        end
        scope "/", MyApp do
          pipe_through :protected
          coherence_routes :protected
        end
        # ...
      end
  """
  use Mix.Task

  @shortdoc "Generate Coherence Controllers"

  @controller_files [
    confirmable: "confirmation_controller.ex",
    invitable: "invitation_controller.ex",
    recoverable: "password_controller.ex",
    registerable: "registration_controller.ex",
    authenticatable: "session_controller.ex",
    unlockable_with_token: "unlock_controller.ex"
  ]

  @default_booleans ~w(confirm)

  @switches [web_path: :string] ++
    Enum.map(@default_booleans, & {String.to_atom(&1), :boolean} )

  def run(args) do
    {opts, parsed, _unknown} = OptionParser.parse(args, switches: @switches)

    opts
    |> do_config(parsed)
    |> do_run
    |> router_instructions
  end

  defp do_run(config) do
    gen_controllers(config)
  end

  defp gen_controllers(%{binding: binding} = config) do
    files =
      @controller_files
      |> Enum.filter(&installed_option?(config, elem0(&1)))
      |> Enum.map(& {:eex, elem1(&1), elem1(&1)})

    copy_from paths(), "priv/templates/coh.gen.controllers/controllers/coherence",
      web_path("controllers/coherence"), binding, files, config
  end

  defp router_instructions(config) do
    web_base = ", " <> config.binding[:web_base]
    router = Application.get_env(:coherence, :router) |> inspect

    Mix.shell.info """
    Modify your router.ex file and change the name spaces as indicated below:

    defmodule #{router} do
      # ...

      # Change this block
      scope "/"#{web_base} do
        pipe_through :browser
        coherence_routes()
      end

      # Change this block
      scope "/"#{web_base} do
        pipe_through :protected
        coherence_routes :protected
      end

      # ...
    end
    """
  end

  defp do_config(opts, _parsed) do
    binding =
      Mix.Project.config
      |> Keyword.fetch!(:app)
      |> Atom.to_string
      |> Mix.Phoenix.inflect

    base     = opts[:module] || binding[:base]
    web_base = opts[:web_module] || base

    binding =
      Enum.into binding, [
        base: base,
        web_base: web_base,
        opts: Keyword.put(opts, :base, base),
        web_path: opts[:web_path] || web_path(),
        web_module: web_base <> ".Coherence.Web"
      ]

    %{
      binding: binding,
      config_opts: get_config_opts()
     }
     |> do_default_opts(opts)
  end

  def do_default_opts(config, opts) do
    @default_booleans
    |> Enum.map(&String.to_atom/1)
    |> Enum.reduce(config, fn opt, config ->
      value = if opts[opt] == false, do: false, else: true
      Map.put config, opt, value
    end)
  end

  defp paths do
    [".", :coherence]
  end

  def copy_from(apps, source_dir, target_dir, binding, mapping, config) when is_list(mapping) do
    roots = Enum.map(apps, &to_app_source(&1, source_dir))

    # create_opts = if config[:confirm], do: [], else: [force: true]
    create_opts = []

    for {format, source_file_path, target_file_path} <- mapping do
      source =
        Enum.find_value(roots, fn root ->
          source = Path.join(root, source_file_path)
          if File.exists?(source), do: source
        end) || raise("could not find #{source_file_path} in any of the sources")

      target = Path.join(target_dir, target_file_path)
      contents =
        case format do
          :text -> File.read!(source)
          :eex  -> EEx.eval_file(source, binding)
        end
      Mix.Generator.create_file(target, contents, create_opts)
    end
    config
  end

  defp to_app_source(path, source_dir) when is_binary(path),
    do: Path.join(path, source_dir)
  defp to_app_source(app, source_dir) when is_atom(app),
    do: Application.app_dir(app, source_dir)

  defp get_config_opts do
    :coherence
    |> Application.get_env(:opts, [])
    |> Enum.map(fn
      {opt, _} -> opt
      opt      -> opt
    end)
  end

  defp installed_option?(config, option) do
    option in config.config_opts
  end

  defp elem0(tuple), do: elem(tuple, 0)
  defp elem1(tuple), do: elem(tuple, 1)

  defp web_path(path \\ "") do
    Path.join ["web", path]
  end
end

