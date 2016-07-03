defmodule Mix.Tasks.Coherence.Install do
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto

  @shortdoc "Configure the Coherence Package"

  @moduledoc """
  Configure the Coherence User Model for your Phoenix application.

      mix coherence.install [--default] [--full] [--full_confirmable] [--full_invitable] [opts]

  A Coherence configuration will be appended to your `config/config.exs` file unless
  the `--log-only` option is given.

  A `--model=SomeModule` option can be given to override the default User module.

  A `--repo=CustomRepo` option can be given to override the default Repo module

  A `--default` option will include only `authenticatable`

  A `--full` option will include options `authenticatable`, `recoverable`, `lockable`, `trackable`, `unlockable_with_token`, `registerable`

  A `--full-confirmable` option will include the `--full` options in addition to the `--confirmable` option

  A `--full-invitable` option will include the `--full` options in addition to the `--invitable` option

  An `--authenticatable` option provides authentication support to your User model.

  A `--recoverable` option provides the ability to request a password reset email.

  A `--lockable` option provides login locking after too many failed login attempts.

  An `--unlockable_with_token` option provides the ability to request an unlock email.

  A `--trackable` option provides login count, current login timestamp, current login ip, last login timestamp, last login ip in your User model.

  A `--confirmable` option provides support for confirmation email before the account can be logged in.

  An `--invitable` option provides support for invitation emails, allowing the new user to create their account including password creation.

  A `--registerable` option provide support for new users to register for an account`

  Based on options provided, a migration will be created for the fields required for each of the options selected.

  """

  # :rememberable not supported yet
  @all_options       ~w(authenticatable recoverable lockable trackable) ++
                       ~w(unlockable_with_token confirmable invitable registerable)
  @all_options_atoms Enum.map(@all_options, &(String.to_atom(&1)))

  @default_options   ~w(authenticatable)
  @full_options      @all_options -- ~w(confirmable invitable)
  @full_confirmable  @all_options -- ~w(invitable)
  @full_invitable    @all_options -- ~w(confirmable)

  # the options that default to true, and can be disabled with --no-option
  @default_booleans  ~w(web views migrations templates boilerplate)

  # all boolean_options
  @boolean_options   @default_booleans ++ ~w(default full full_confirmable full_invitable) ++ @all_options

  # options that will set use_email? to true
  @email_options     Enum.map(~w(recoverable unlockable_with_token confirmable invitable), &(String.to_atom(&1)))

  @config_file "config/config.exs"

  def run(args) do
    switches = [user: :string, repo: :string, log_only: :boolean] ++
      Enum.map(@boolean_options, &({String.to_atom(&1), :boolean}))

    {opts, parsed, _} = OptionParser.parse(args, switches: switches)
    IO.puts "opts: #{inspect opts}"
    {bin_opts, opts} = parse_options(opts)

    binding = Mix.Project.config
    |> Keyword.fetch!(:app)
    |> Atom.to_string
    |> Mix.Phoenix.inflect

    IO.puts "binding: #{inspect binding}"
    base = binding[:base]

    repo = (opts[:repo] || "#{base}.Repo")
    |> String.split(".")
    |> Module.concat

    config =
    bin_opts
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})
    |> Map.put(:instructions, "")
    |> Map.put(:base, base)
    |> Map.put(:use_email?, Enum.any?(bin_opts, &(&1 in @email_options)))
    |> Map.put(:user_schema, opts[:model] || "#{base}.User")
    |> Map.put(:repo, repo)
    |> Map.put(:opts, bin_opts)
    |> Map.put(:log_only, opts[:log_only])
    |> do_default_config(opts)


    IO.puts "config: #{inspect config}"
    IO.puts "bin_opts: #{inspect bin_opts}"
    IO.puts "opts: #{inspect opts}"

    config
    |> generate_coherence_config
    |> write_config(config)
    |> log_config(config)
    |> gen_migration
    |> gen_invitable_migration
    |> gen_coherence_web(binding)
    |> gen_coherence_views(binding)
    |> gen_coherence_templates(binding)
    |> print_instructions

  end

  defp do_default_config(config, opts) do
    string_list_to_atoms(@default_booleans)
    |> Enum.reduce( config, fn opt, acc ->
      Map.put acc, opt, Keyword.get(opts, opt, true)
    end)
  end

  defp string_list_to_atoms(list), do: for opt <- list, do: String.to_atom(opt)

  defp generate_coherence_config(config) do
    from_email = if config[:use_email?] do
      ~s|  email_from: {"Your Name", "yourname@example.com"},\n|
    else
      ""
    end

    """
config :coherence,
  user_schema: #{config[:user_schema]},
  repo: #{config[:repo]},
  module: #{config[:base]},
  logged_out_url: "/",
""" <> from_email <>
    "  opts: #{inspect config[:opts]}\n"
    |> swoosh_config(config)
  end

  defp swoosh_config(string, %{use_email?: true}) do
    string <> "\n" <> """
config :coherence, Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"
"""
  end
  defp swoosh_config(string, _), do: string

  defp log_config(string, config) do

    instructions = """

    The following has been added to your #{@config_file} file.

    """ <> string

    save_instructions config, instructions
  end
  defp write_config(string, %{log_only: true} = config) do
    string
  end
  defp write_config(string, _config), do: string

  # defp prompt_yes(default, yes_prompt, prompt) do
  #   unless Mix.shell.yes? yes_prompt do
  #     Mix.shell.prompt prompt
  #   else
  #     default
  #   end
  # end

  # defp schema_exists?(module) do
  #   :erlang.function_exported(module, :__schema__, 1)
  # end

  defp parse_options(opts) do
    {opts_bin, opts} = Enum.reduce opts, {[], []}, fn
      {:default, true}, {acc_bin, acc} ->
        {list_to_atoms(@default_options) ++ acc_bin, acc}
      {:full, true}, {acc_bin, acc} ->
        {list_to_atoms(@full_options) ++ acc_bin, acc}
      {:full_confirmable, true}, {acc_bin, acc} ->
        {list_to_atoms(@full_confirmable) ++ acc_bin, acc}
      {:full_invitable, true}, {acc_bin, acc} ->
        {list_to_atoms(@full_invitable) ++ acc_bin, acc}
      {name, true}, {acc_bin, acc} when name in @all_options_atoms ->
        {[name | acc_bin], acc}
      # {_name, true}, acc ->
      #   acc
      {name, false}, {acc_bin, acc} when name in @all_options_atoms ->
        {acc_bin -- [name], acc}
      # {_name, false}, acc ->
      #   acc
      opt, {acc_bin, acc} ->
        {acc_bin, [opt | acc]}
    end
    {Enum.uniq(opts_bin), opts}
  end

  defp list_to_atoms(list), do: Enum.map(list, &(String.to_atom(&1)))

  defp gen_migration(%{migrations: true, boilerplate: true} = config) do
    do_gen_migration config, "add_coherence_to_user", fn repo, path, file, name ->
      adds =
        Enum.reduce(config[:opts], [], fn opt, acc ->
          case Coherence.Schema.schema_fields[opt] do
            nil -> acc
            list ->
              # IO.puts "list: #{inspect list}"
              acc ++ list
          end
        end)
        |> Enum.map(&("      " <> &1))
        |> Enum.join("\n")

      change = """
          alter table(:users) do
      #{adds}
          end
      """
      assigns = [mod: Module.concat([repo, Migrations, camelize(name)]),
                       change: change]
      create_file file, migration_template(assigns)
      config
    end
  end
  defp gen_migration(config), do: config

  defp gen_invitable_migration(%{invitable: true, migrations: true, boilerplate: true} = config) do
    do_gen_migration config, "create_coherence_invitable", fn repo, path, file, name ->
      change = """
          create table(:invitations) do
            add :name, :string
            add :email, :string
            add :token, :string
            timestamps
          end
          create unique_index(:invitations, [:email])
          create index(:invitations, [:token])
      """
      assigns = [mod: Module.concat([repo, Migrations, camelize(name)]),
                       change: change]
      create_file file, migration_template(assigns)
      config
    end
  end
  defp gen_invitable_migration(config), do: config

  defp do_gen_migration(config, name, fun) do
    repo = config[:repo]
    ensure_repo(repo, [])
    path = Path.relative_to(migrations_path(repo), Mix.Project.app_path)
    file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")
    fun.(repo, path, file, name)
  end

  defp gen_coherence_web(%{web: true, boilerplate: true} = config, binding) do
    Mix.Phoenix.copy_from paths(),
      "priv/templates/coherence.install", "", binding, [
        {:eex, "coherence_web.ex", "web/coherence_web.ex"},
      ]
    config
  end
  defp gen_coherence_web(config, _binding), do: config

  @view_files ~w(coherence_view.ex confirmation_view.ex email_view.ex invitation_view.ex layout_view.ex password_view.ex registration_view.ex session_view.ex unlock_view.ex)
  defp gen_coherence_views(%{views: true, boilerplate: true} = config, binding) do
    files = Enum.map(@view_files, &({:eex, &1, "web/views/coherence/#{&1}"}))
    Mix.Phoenix.copy_from paths(), "priv/templates/coherence.install/views/coherence", "", binding, files
    config
  end
  defp gen_coherence_views(config, _binding), do: config

  @template_files [
    email: ~w(confirmation invitation password unlock),
    invitation: ~w(edit new),
    layout: ~w(app email),
    password: ~w(edit new),
    registration: ~w(new),
    session: ~w(new),
    unlock: ~w(new)
  ]
  defp gen_coherence_templates(%{templates: true, boilerplate: true} = config, binding) do
    for {name, files} <- @template_files do
      copy_templates(binding, name, files)
    end
    config
  end
  defp gen_coherence_templates(config, _binding), do: config

  defp copy_templates(binding, name, file_list) do
    files = for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, "web/templates/coherence/#{name}/#{fname}"}
    end

    Mix.Phoenix.copy_from paths(),
      "priv/templates/coherence.install/templates/coherence/#{name}", "", binding, files
  end

  defp schema_instructions(%{base: base} = config), do: """
    Add the following items to your User model.

    defmodule #{base}.User do
      use #{base}.Web, :model
      use Coherence.Schema     # Add this

      schema "users" do
        field :name, :string
        field :email, :string
        coherence_schema       # Add this

        timestamps
      end

      @required_fields ~w(name email)
      @optional_fields ~w() ++ coherence_fields   # Add this

      def changeset(model, params \\ %{}) do
        model
        |> cast(params, @required_fields, @optional_fields)
        |> unique_constraint(:email)
        |> validate_coherence(params)             # Add this
      end
    end
    """
  defp router_instructions(%{base: base} = config), do: """
    Add the following to your router.ex file.

    defmodule #{base}.Router do
      use #{base}.Web, :router
      use Coherence.Router         # Add this

      pipeline :browser do
        plug :accepts, ["html"]
        # ...
        plug Coherence.Authentication.Database, db_model: #{base}.User  # Add this
      end

      pipeline :public do
        plug :accepts, ["html"]
        # ...
        plug Coherence.Authentication.Database, db_model: #{base}.User, login: false  # Add this
      end

      scope "/" do
        pipe_through :public
        coherence_routes           # Add this
        get "/", Admin1.PageController, :index
      end
      # ...
    end
    """

  defp migrate_instructions(%{base: base, migrations: true, boilerplate: true} = config), do: """
    Don't forget to run the new migrations with:
        $ mix ecto.migrate
    """
  defp migrate_instructions(_), do: ""

  defp print_instructions(%{instructions: instructions} = config) do
    Mix.shell.info instructions
    Mix.shell.info router_instructions(config)
    Mix.shell.info schema_instructions(config)
    Mix.shell.info migrate_instructions(config)

    config
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration
    def change do
  <%= @change %>
    end
  end
  """

  defp paths do
    [".", :coherence]
  end

  defp save_instructions(config, instructions) do
    update_in config, [:instructions], &(&1 <> instructions)
  end
end
