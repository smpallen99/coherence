defmodule Mix.Tasks.Coherence.Install do
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto

  @shortdoc "Configure the Coherence Package"

  @moduledoc """
  Configure the Coherence User Model for your Phoenix application. Coherence
  is composed of a number of modules that can be enabled with this installer.

  This installer will normally do the following unless given an option not to do so:

  * Append the :coherence configuration to your `config/config.exs` file.
  * Generate appropriate migration files.
  * Generate appropriate view files.
  * Generate appropriate template files.
  * Generate a `web/coherence_web.ex` file.

  ## Examples

      # Install with only the `authenticatable` option
      mix coherence.install

      # Install all the options except `confirmable` and `invitable`
      mix coherence.install --full

      # Install all the options except `invitable`
      mix coherence.install --full-confirmable

      # Install all the options except `confirmable`
      mix coherence.install --full-invitable

      # Install the `full` options except `lockable` and `trackable`
      mix coherence.install --full --no-lockable --no-trackable

      # Remove all the coherence generated boilerplate files
      # mix coherence.install --clean

  ## Option list

  A Coherence configuration will be appended to your `config/config.exs` file unless
  the `--no-config` option is given.

  A `--model=SomeModule` option can be given to override the default User module.

  A `--repo=CustomRepo` option can be given to override the default Repo module

  A `--default` option will include only `authenticatable`

  A `--full` option will include options `authenticatable`, `recoverable`, `lockable`, `trackable`, `unlockable_with_token`, `registerable`

  A `--full-confirmable` option will include the `--full` options in addition to the `--confirmable` option

  A `--full-invitable` option will include the `--full` options in addition to the `--invitable` option

  An `--authenticatable` option provides authentication support to your User model.

  A `--recoverable` option provides the ability to request a password reset email.

  A `--lockable` option provides login locking after too many failed login attempts.

  An `--unlockable-with-token` option provides the ability to request an unlock email.

  A `--trackable` option provides login count, current login timestamp, current login ip, last login timestamp, last login ip in your User model.

  A `--confirmable` option provides support for confirmation email before the account can be logged in.

  An `--invitable` option provides support for invitation emails, allowing the new user to create their account including password creation.

  A `--registerable` option provide support for new users to register for an account`

  A `--clean` option will all the coherence boilerplate

  ## Disable Options

  * `--no-config` -- Don't append to your `config/config.exs` file.
  * `--no-web` -- Don't create the `coherence_web.ex` file.
  * `--no-views` -- Don't create the `web/views/coherence/` files.
  * `--no-migrations` -- Don't create the migration files.
  * `--no-templates` -- Don't create the `web/templates/coherence` files.
  * `--no-boilerplate` -- Don't create any of the boilerplate files.

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
  @default_booleans  ~w(config web views migrations templates boilerplate)

  # all boolean_options
  @boolean_options   @default_booleans ++ ~w(default full full_confirmable full_invitable) ++ @all_options

  # options that will set use_email? to true
  @email_options     Enum.map(~w(recoverable unlockable_with_token confirmable invitable), &(String.to_atom(&1)))

  @config_file "config/config.exs"

  @config_marker_start "%% Coherence Configuration %%"
  @config_marker_end   "%% End Coherence Configuration %%"

  def run(args) do
    switches = [user: :string, repo: :string, clean: :boolean] ++
      Enum.map(@boolean_options, &({String.to_atom(&1), :boolean}))

    {opts, _parsed, _} = OptionParser.parse(args, switches: switches)
    # IO.puts "opts: #{inspect opts}"
    {bin_opts, opts} = parse_options(opts)


    # IO.puts "config: #{inspect config}"

    # IO.puts "bin_opts: #{inspect bin_opts}"
    # IO.puts "opts: #{inspect opts}"

    do_config(opts, bin_opts)
    |> do_clean
    |> do_run
  end

  defp do_clean(%{clean: true} = config) do
    if Mix.shell.yes? "Are you sure you want to delete coherence files?" do
      rm_dir! "web/views/coherence"
      rm_dir! "web/templates/coherence"
      rm_dir! "web/emails"
      rm! "web/coherence_web.ex"
      Mix.shell.info """

      You must manually remove the migration files and the
      config/config.exs configuration
      """
    else
      Mix.shell.info "Skipping the cleaning!"
    end
    config
  end
  defp do_clean(config), do: config

  defp do_run(%{clean: false} = config) do
    # IO.puts "config: #{inspect config}"
    config
    |> gen_coherence_config
    |> gen_migration
    |> gen_invitable_migration
    |> gen_coherence_web
    |> gen_coherence_views
    |> gen_coherence_templates
    |> gen_coherence_mailer
    |> print_instructions
  end
  defp do_run(config), do: config

  defp gen_coherence_config(config) do
    from_email = if config[:use_email?] do
      ~s|  email_from: {"Your Name", "yourname@example.com"},\n|
    else
      ""
    end

    """
# #{@config_marker_start}   Don't remove this line
config :coherence,
  user_schema: #{config[:user_schema]},
  repo: #{config[:repo]},
  module: #{config[:base]},
  logged_out_url: "/",
""" <> from_email <>
    "  opts: #{inspect config[:opts]}\n"
    |> swoosh_config(config)
    |> add_end_marker
    |> write_config(config)
    |> log_config(config)
  end

  defp swoosh_config(string, %{base: base, use_email?: true}) do
    string <> "\n" <> """
config :coherence, #{base}.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"
"""
  end
  defp swoosh_config(string, _), do: string

  defp add_end_marker(string) do
    string <> "# #{@config_marker_end}\n"
  end

  defp log_config(string, config) do
    instructions = """

    The following has been added to your #{@config_file} file.

    """ <> string

    save_instructions config, instructions
  end

  defp write_config(string, %{config: true}) do
    if File.exists? @config_file do
      source = File.read!(@config_file)
      continue? = if String.contains? source, @config_marker_start do
        Mix.shell.yes? "Your config file already contains Coherence configuration. Are you sure you add another?"
      else
        true
      end
      if continue?, do: File.write!(@config_file, source <> "\n" <> string),
        else: Mix.shell.info "Configuration was not added!"
    else
      Mix.shell.error "Could not find #{@config_file}. Configuration was not added!"
    end
    string
  end
  defp write_config(string, _config), do: string

  defp gen_migration(%{migrations: true, boilerplate: true} = config) do
    do_gen_migration config, "add_coherence_to_user", fn repo, _path, file, name ->
      adds =
        Enum.reduce(config[:opts], [], fn opt, acc ->
          case Coherence.Schema.schema_fields[opt] do
            nil -> acc
            list -> acc ++ list
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
    do_gen_migration config, "create_coherence_invitable", fn repo, _path, file, name ->
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
    |> String.split(".")
    |> Module.concat
    ensure_repo(repo, [])
    path = Path.relative_to(migrations_path(repo), Mix.Project.app_path)
    file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")
    fun.(repo, path, file, name)
  end

  defp gen_coherence_web(%{web: true, boilerplate: true, binding: binding} = config) do
    Mix.Phoenix.copy_from paths(),
      "priv/templates/coherence.install", "", binding, [
        {:eex, "coherence_web.ex", "web/coherence_web.ex"},
      ]
    config
  end
  defp gen_coherence_web(config), do: config

  @view_files [
    all: "coherence_view.ex",
    confirmable: "confirmation_view.ex",
    use_email?: "email_view.ex",
    invitable: "invitation_view.ex",
    all: "layout_view.ex",
    recoverable: "password_view.ex",
    registerable: "registration_view.ex",
    authenticatable: "session_view.ex",
    unlockable_with_token: "unlock_view.ex"
  ]

  def gen_coherence_views(%{views: true, boilerplate: true, binding: binding} = config) do
    files = Enum.filter_map(@view_files, &(validate_option(config, elem(&1,0))), &(elem(&1, 1)))
    |> Enum.map(&({:eex, &1, "web/views/coherence/#{&1}"}))

    Mix.Phoenix.copy_from paths(), "priv/templates/coherence.install/views/coherence", "", binding, files
    config
  end
  def gen_coherence_views(config), do: config

  @template_files [
    email: {:use_email?, ~w(confirmation invitation password unlock)},
    invitation: {:invitable, ~w(edit new)},
    layout: {:all, ~w(app email)},
    password: {:recoverable, ~w(edit new)},
    registration: {:registerable, ~w(new)},
    session: {:authenticatable, ~w(new)},
    unlock: {:unlockable_with_token, ~w(new)}
  ]

  defp validate_option(_, :all), do: true
  defp validate_option(%{use_email?: true}, :use_email?), do: true
  defp validate_option(%{opts: opts}, opt) do
    if opt in opts, do: true, else: false
  end

  def gen_coherence_templates(%{templates: true, boilerplate: true, binding: binding} = config) do
    for {name, {opt, files}} <- @template_files do
      if validate_option(config, opt), do: copy_templates(binding, name, files)
    end
    config
  end
  def gen_coherence_templates(config), do: config

  defp copy_templates(binding, name, file_list) do
    files = for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, "web/templates/coherence/#{name}/#{fname}"}
    end

    Mix.Phoenix.copy_from paths(),
      "priv/templates/coherence.install/templates/coherence/#{name}", "", binding, files
  end

  defp gen_coherence_mailer(%{binding: binding, use_email?: true, boilerplate: true} = config) do
    Mix.Phoenix.copy_from paths(),
      "priv/templates/coherence.install/emails", "", binding, [
        {:eex, "coherence_mailer.ex", "web/emails/coherence_mailer.ex"},
        {:eex, "user_email.ex", "web/emails/user_email.ex"},
      ]
    config
  end
  defp gen_coherence_mailer(config), do: config

  defp schema_instructions(%{base: base}), do: """
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
  defp router_instructions(%{base: base}), do: """
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

  defp migrate_instructions(%{migrations: true, boilerplate: true}), do: """
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

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration
    def change do
  <%= @change %>
    end
  end
  """

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  defp do_default_config(config, opts) do
    list_to_atoms(@default_booleans)
    |> Enum.reduce( config, fn opt, acc ->
      Map.put acc, opt, Keyword.get(opts, opt, true)
    end)
  end

  defp list_to_atoms(list), do: Enum.map(list, &(String.to_atom(&1)))

  defp paths do
    [".", :coherence]
  end

  defp save_instructions(config, instructions) do
    update_in config, [:instructions], &(&1 <> instructions)
  end

  defp rm_dir!(dir) do
    if File.dir? dir do
      File.rm_rf dir
    end
  end

  defp rm!(file) do
    if File.exists? file do
      File.rm! file
    end
  end

  defp do_config(opts, []) do
    do_config(opts, list_to_atoms(@default_options))
  end
  defp do_config(opts, bin_opts) do
    binding = Mix.Project.config
    |> Keyword.fetch!(:app)
    |> Atom.to_string
    |> Mix.Phoenix.inflect

    # IO.puts "binding: #{inspect binding}"

    base = binding[:base]
    repo = (opts[:repo] || "#{base}.Repo")

    bin_opts
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})
    |> Map.put(:clean, opts[:clean] || false)
    |> Map.put(:instructions, "")
    |> Map.put(:base, base)
    |> Map.put(:use_email?, Enum.any?(bin_opts, &(&1 in @email_options)))
    |> Map.put(:user_schema, opts[:model] || "#{base}.User")
    |> Map.put(:repo, repo)
    |> Map.put(:opts, bin_opts)
    |> Map.put(:binding, binding)
    |> Map.put(:log_only, opts[:log_only])
    |> do_default_config(opts)
  end

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
      {name, false}, {acc_bin, acc} when name in @all_options_atoms ->
        {acc_bin -- [name], acc}
      opt, {acc_bin, acc} ->
        {acc_bin, [opt | acc]}
    end
    {Enum.uniq(opts_bin), opts}
  end

  # TODO: Remove this later if we never use it
  #
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

end
