defmodule Mix.Tasks.Coh.Install do
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto
  import Coherence.Config, only: [use_binary_id?: 0]
  import Coherence.Mix.Utils

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
  * Generate a `web/coherence_messages.ex` file.
  * Generate a `web/models/user.ex` file if one does not already exist.

  ## Install Examples

      # Install with only the `authenticatable` option
      mix coh.install

      # Install all the options except `confirmable` and `invitable`
      mix coh.install --full

      # Install all the options except `invitable`
      mix coh.install --full-confirmable

      # Install all the options except `confirmable`
      mix coh.install --full-invitable

      # Install the `full` options except `lockable` and `trackable`
      mix coh.install --full --no-lockable --no-trackable

  ## Reinstall Examples

      # Reinstall with defaults (--silent --no-migrations --no-config --confirm-once)
      mix coh.install --reinstall

      # Confirm to overwrite files, show instructions, and generate migrations
      mix coh.install --reinstall --no-confirm-once --with-migrations

  ## Option list

  A Coherence configuration will be appended to your `config/config.exs` file unless
  the `--no-config` option is given.

  A `--model="SomeModule tablename"` option can be given to override the default User module.

  A `--repo=CustomRepo` option can be given to override the default Repo module

  A `--router=CustomRouter` option can be given to override the default Router module

  A `--web-path="lib/my_project/web"` option can be given to specify the web path

  A `--default` option will include only `authenticatable`

  A `--full` option will include options `authenticatable`, `recoverable`, `lockable`, `trackable`, `unlockable_with_token`, `registerable`

  A `--full-confirmable` option will include the `--full` options in addition to the `--confirmable` option

  A `--full-invitable` option will include the `--full` options in addition to the `--invitable` option

  An `--authenticatable` option provides authentication support to your User model.

  A `--recoverable` option provides the ability to request a password reset email.

  A `--lockable` option provides login locking after too many failed login attempts.

  An `--unlockable-with-token` option provides the ability to request an unlock email.

  A `--trackable` option provides login count, current login timestamp, current login ip, last login timestamp, last login ip in your User model.

  A `--trackable-table` option provides `trackable` fields in the `trackables` table.

  A `--confirmable` option provides support for confirmation email before the account can be logged in.

  An `--invitable` option provides support for invitation emails, allowing the new user to create their account including password creation.

  A `--registerable` option provide support for new users to register for an account`

  A `--rememberable` option provide a remember me? check box for persistent logins`

  A `--migration-path` option to set the migration path

  A `--controllers` option to generate controllers boilerplate (not default)

  A `--module` option to override the module

  A `--installed-options` option to list the previous install options

  A `--reinstall` option to reinstall the coherence boilerplate based on your existing configuration options

  A `--silent` option to disable printing instructions

  A `--confirm-once` option to only confirm overwriting existing files once

  A `--with-migrations` option to reinstall migrations. only valid for --reinstall option

  ## Disable Options

  * `--no-config` -- Don't append to your `config/config.exs` file.
  * `--no-web` -- Don't create the `coherence_web.ex` file.
  * `--no-messages` -- Don't create the `coherence_messages.ex` file.
  * `--no-views` -- Don't create the `web/views/coherence/` files.
  * `--no-migrations` -- Don't create the migration files.
  * `--no-templates` -- Don't create the `web/templates/coherence` files.
  * `--no-boilerplate` -- Don't create any of the boilerplate files.
  * `--no-models` -- Don't generate the model file.
  * `--no-confirm` -- Don't confirm overwriting files.

  """
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto
  import Coherence.Mix.Utils

  @shortdoc "Configure the Coherence Package"

  @all_options       ~w(authenticatable recoverable lockable trackable trackable_table rememberable) ++
                       ~w(unlockable_with_token confirmable invitable registerable)
  @all_options_atoms Enum.map(@all_options, &(String.to_atom(&1)))

  @default_options   ~w(authenticatable)
  @full_options      @all_options -- ~w(confirmable invitable rememberable trackable_table)
  @full_confirmable  @all_options -- ~w(invitable rememberable trackable_table)
  @full_invitable    @all_options -- ~w(confirmable rememberable trackable_table)

  # the options that default to true, and can be disabled with --no-option
  @default_booleans  ~w(config web messages views migrations templates models emails boilerplate confirm)

  # all boolean_options
  @boolean_options   @default_booleans ++ ~w(default full full_confirmable full_invitable) ++ @all_options

  # options that will set use_email? to true
  @email_options     Enum.map(~w(recoverable unlockable_with_token confirmable invitable), &(String.to_atom(&1)))

  @config_file "config/config.exs"

  @config_marker_start "%% Coherence Configuration %%"
  @config_marker_end   "%% End Coherence Configuration %%"

  @switches [
    user: :string, repo: :string, migration_path: :string, model: :string,
    log_only: :boolean, confirm_once: :boolean, controllers: :boolean,
    module: :string, installed_options: :boolean, reinstall: :boolean,
    silent: :boolean, with_migrations: :boolean, router: :string,
    web_path: :string
  ] ++ Enum.map(@boolean_options, &({String.to_atom(&1), :boolean}))

  @switch_names Enum.map(@switches, &(elem(&1, 0)))

  @new_user_migration_fields ["add :name, :string", "add :email, :string"]
  @new_user_constraints      ["create unique_index(:users, [:email])"]

  def run(args) do
    {opts, parsed, unknown} = OptionParser.parse(args, switches: @switches)

    verify_args!(parsed, unknown)

    {bin_opts, opts} = parse_options(opts)

    opts
    |> do_config(bin_opts)
    |> do_run
  end

  defp do_run(%{reinstall: true} = config) do
    ["--no-config"]
    |> check_confirm_once(config)
    |> check_silent(config)
    |> check_migrations(config)
    |> get_config_options()
    |> run
  end
  defp do_run(%{installed_options: true} = config) do
    print_installed_options config
  end
  defp do_run(%{confirm_once: true} = config) do
    if Mix.shell.yes? "Are you sure you want overwrite any existing files?" do
      config
      |> Map.put(:confirm, false)
      |> Map.delete(:confirm_once)
      |> do_run
    end
  end
  defp do_run(%{with_migrations: true}), do: Mix.raise("--with-migrations only valid with --reinstall")
  defp do_run(config) do
    config
    |> check_for_model
    |> gen_coherence_config
    |> gen_migration
    |> gen_model
    |> gen_invitable_migration
    |> gen_rememberable_migration
    |> gen_trackable_migration
    |> gen_coherence_web
    |> gen_coherence_messages
    |> gen_coherence_views
    |> gen_coherence_templates
    |> gen_coherence_mailer
    |> gen_redirects
    |> gen_coherence_controllers
    |> touch_config                # work around for config file not getting recompiled
    |> print_instructions
  end

  defp check_confirm(options, %{confirm: true}), do: options
  defp check_confirm(options, _), do: ["--no-confirm" | options]
  defp check_confirm_once(options, %{confirm_once: false} = config), do: check_confirm(options, config)
  defp check_confirm_once(options, _), do: ["--confirm-once" | options]
  defp check_silent(options, %{silent: false}), do: options
  defp check_silent(options, _), do: ["--silent" | options]
  defp check_migrations(options, %{with_migrations: true}), do: options
  defp check_migrations(options, _), do: ["--no-migrations" | options]

  defp gen_coherence_config(config) do
    from_email = if config[:use_email?] do
      ~s|  email_from_name: "Your Name",\n| <>
      ~s|  email_from_email: "yourname@example.com",\n|
    else
      ""
    end

    config_block = """
      # #{@config_marker_start}   Don't remove this line
      config :coherence,
        user_schema: #{config[:user_schema]},
        repo: #{config[:repo]},
        module: #{config[:base]},
        router: #{config[:router]},
        messages_backend: #{config[:base]}.Coherence.Messages,
        logged_out_url: "/",
      """
    (config_block <> from_email <> "  opts: #{inspect config[:opts]}\n")
    |> swoosh_config(config)
    |> add_end_marker
    |> write_config(config)
    |> log_config
  end

  defp swoosh_config(string, %{base: base, use_email?: true}) do
    string <> "\n" <>
      """
      config :coherence, #{base}.Coherence.Mailer,
        adapter: Swoosh.Adapters.Sendgrid,
        api_key: "your api key here"
      """
  end
  defp swoosh_config(string, _), do: string

  defp add_end_marker(string) do
    string <> "# #{@config_marker_end}\n"
  end

  defp write_config(string, %{config: true, confirm: confirm?} = config) do
    log_config? =
      if File.exists? @config_file do
        source = File.read!(@config_file)

        confirmed =
          if String.contains? source, @config_marker_start do
            confirm? && Mix.shell.yes?("Your config file already contains Coherence configuration. Are you sure you want to add another?")
          else
            true
          end

        if confirmed do
          File.write!(@config_file, source <> "\n" <> string)
          shell_info config, "Your config/config.exs file was updated."
          false
        else
          shell_info config, "Configuration was not added!"
          true
        end
      else
        shell_info config, "Could not find #{@config_file}. Configuration was not added!"
        true
      end
    Enum.into [config_string: string, log_config?: log_config?], config
  end
  defp write_config(string, config), do: Enum.into([log_config?: true, config_string: string], config)

  defp shell_info(%{silent: true} = config, _message), do: config
  defp shell_info(config, message) do
    Mix.shell.info message
    config
  end
  defp log_config(%{log_config?: false} = config) do
    save_instructions config, ""
  end
  defp log_config(%{config_string: string} = config) do
    verb = if config[:log_config] == :appended, do: "has been", else: "should be"
    instructions =
      """

      The following #{verb} added to your #{@config_file} file.

      """

    save_instructions config, instructions <> string
  end

  defp touch_config(config) do
    File.touch @config_file
    config
  end

  defp module_to_string(module) when is_atom(module) do
    module
    |> Module.split
    |> Enum.reverse
    |> hd
    |> to_string
  end

  defp module_to_string(module) when is_binary(module) do
    module
    |> String.split(".")
    |> Enum.reverse
    |> hd
  end

  ################
  # Models

  defp check_for_model(%{user_schema: user_schema, web_path: web_path} = config) do
    user_schema = Module.concat user_schema, nil
    Map.put(config, :model_found?, Code.ensure_compiled?(user_schema) or model_exists?(user_schema, Path.join(web_path, "coherence")))
  end

  defp check_for_model(config), do: config

  defp gen_model(%{user_schema: user_schema, boilerplate: true, models: true,
    model_found?: false, web_path: web_path} = config) do
    name =
      user_schema
      |> module_to_string
      |> String.downcase

    binding = Kernel.binding() ++ [base: config[:base], user_table_name: config[:user_table_name]]
    copy_from paths(),
      "priv/templates/coh.install/models/coherence", "", binding, [
        {:eex, "user.ex", Path.join(web_path, "coherence/#{name}.ex")}
      ], config
    config
  end

  defp gen_model(config), do: config

  ################
  # Migrations

  defp create_or_alter_model(config, name) do
    table_name = config[:user_table_name]
    # user_schema = Module.concat user_schema, nil
    if  config[:model_found?] do
      {:alter, "add_coherence_to_#{name}", [], []}
    else
      fields = Enum.map @new_user_migration_fields,
        &(String.replace(&1, ":users", ":#{table_name}"))

      constraints = Enum.map @new_user_constraints,
        &(String.replace(&1, ":users", ":#{table_name}"))

      {:create, "create_coherence_#{name}", fields, constraints}
    end
  end

  defp model_exists?(model, path) do
    with {:ok, files} <- File.ls(path),
         true <- any_files?(files, model, path) do
      true
    else
      _ -> false
    end
  end

  defp any_files?(files, model, path) do
    Enum.any? files, fn fname ->
      case File.read Path.join(path, fname) do
        {:ok, contents} ->
          contents =~ ~r/defmodule\s*#{inspect model}/
        {:error, _} -> false
      end
    end
  end

  defp add_timestamp(acc, %{model_found?: false}), do: acc ++ ["", "timestamps()"]
  defp add_timestamp(acc, _), do: acc

  defp get_field_list(initial_fields, config) do
    schema_fields = Coherence.Schema.schema_fields()
    Enum.reduce(config[:opts], initial_fields, fn opt, acc ->
      case schema_fields[opt] do
        nil -> acc
        list -> acc ++ list
      end
    end)
  end

  defp gen_migration(%{migrations: true, boilerplate: true} = config) do
    table_name = config[:user_table_name]
    name =
      config[:user_schema]
      |> module_to_string
      |> String.downcase

    {verb, migration_name, initial_fields, constraints} = create_or_alter_model(config, name)

    do_gen_migration config, migration_name, fn repo, _path, file, name ->
      field_list = get_field_list(initial_fields, config)

      adds =
        field_list
        |> add_timestamp(config)
        |> Enum.map(&("      " <> &1))
        |> Enum.join("\n")

      constraints =
        constraints
        |> Enum.map(&("    " <> &1))
        |> Enum.join("\n")

      statement = case verb do
                    :alter -> "#{verb} table(:#{table_name}) do"
                    :create -> gen_table_statement(table_name)
                  end

      change = """
          #{statement}
      #{adds}
          end
      #{constraints}
      """
      assigns = [mod: Module.concat([repo, Migrations, camelize(name)]),
                       change: change]
      create_file file, migration_template(assigns)
    end
  end

  defp gen_migration(config), do: config

  defp gen_invitable_migration(%{invitable: true, migrations: true, boilerplate: true} = config) do
    do_gen_migration config, "create_coherence_invitable", fn repo, _path, file, name ->
      change = """
          #{gen_table_statement(:invitations)}
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
    end
  end

  defp gen_invitable_migration(config), do: config

  defp gen_rememberable_migration(%{rememberable: true, migrations: true, boilerplate: true} = config) do
    table_name = config[:user_table_name]
    do_gen_migration config, "create_coherence_rememberable", fn repo, _path, file, name ->
      change = """
          #{gen_table_statement(:rememberables)}
            add :series_hash, :string
            add :token_hash, :string
            add :token_created_at, :utc_datetime
            add :user_id, #{gen_reference(table_name)}

            timestamps
          end
          create index(:rememberables, [:user_id])
          create index(:rememberables, [:series_hash])
          create index(:rememberables, [:token_hash])
          create unique_index(:rememberables, [:user_id, :series_hash, :token_hash])
      """
      assigns = [mod: Module.concat([repo, Migrations, camelize(name)]),
                       change: change]
      create_file file, migration_template(assigns)
    end
  end

  defp gen_rememberable_migration(config), do: config

  defp gen_trackable_migration(%{trackable_table: true, migrations: true, boilerplate: true} = config) do
    table_name = config[:user_table_name]
    do_gen_migration config, "create_coherence_trackable", fn repo, _path, file, name ->
      change = """
          #{gen_table_statement(:trackables)}
            add :action, :string
            add :sign_in_count, :integer, default: 0
            add :current_sign_in_at, :utc_datetime
            add :last_sign_in_at, :utc_datetime
            add :current_sign_in_ip, :string
            add :last_sign_in_ip, :string
            add :user_id, #{gen_reference(table_name)}

            timestamps
          end
          create index(:trackables, [:user_id])
          create index(:trackables, [:action])
      """
      assigns = [mod: Module.concat([repo, Migrations, camelize(name)]),
                       change: change]
      create_file file, migration_template(assigns)
    end
  end

  defp gen_trackable_migration(config), do: config

  defp do_gen_migration(%{timestamp: current_timestamp} = config, name, fun) do
    repo =
      config[:repo]
      |> String.split(".")
      |> Module.concat

    ensure_repo(repo, [])

    path =
      case config[:migration_path] do
        path when is_binary(path) -> path
        _ ->
          Path.relative_to(migrations_path(repo), Mix.Project.app_path)
      end
    file = Path.join(path, "#{current_timestamp}_#{underscore(name)}.exs")
    fun.(repo, path, file, name)
    Map.put(config, :timestamp, current_timestamp + 1)
  end

  defp gen_table_statement(table_name) do
    if use_binary_id?() do
      """
      create table(:#{table_name}, primary_key: false) do
            add :id, :binary_id, primary_key: true
      """
    else
      """
      create table(:#{table_name}) do
      """
    end
  end

  defp gen_reference(table_name) do
    type_hint = if use_binary_id?(), do: ", type: :binary_id", else: ""
    "references(:#{table_name}, on_delete: :delete_all#{type_hint})"
  end

  ################
  # Web

  defp gen_coherence_web(%{web: true, boilerplate: true, binding: binding, web_path: web_path} = config) do
    copy_from paths(),
      "priv/templates/coh.install", "", binding, [
        {:eex, "coherence_web.ex", Path.join(web_path, "coherence_web.ex")},
      ], config
    config
  end

  defp gen_coherence_web(config), do: config

  ################
  # Messages

  defp gen_coherence_messages(%{messages: true, boilerplate: true, binding: binding, web_path: web_path} = config) do
    copy_from paths(),
      "priv/templates/coh.install", "", binding, [
        {:eex, "coherence_messages.ex", Path.join(web_path, "coherence_messages.ex")},
      ], config
    config
  end

  defp gen_coherence_messages(config), do: config

  defp gen_redirects(%{boilerplate: true, binding: binding, web_path: web_path} = config) do
    copy_from paths(),
      "priv/templates/coh.install/controllers/coherence", "", binding, [
        {:eex, "redirects.ex", Path.join(web_path, "controllers/coherence/redirects.ex")},
      ], config
    config
  end

  defp gen_redirects(config), do: config

  ################
  # Views

  @view_files [
    all: "coherence_view.ex",
    confirmable: "confirmation_view.ex",
    use_email?: "email_view.ex",
    invitable: "invitation_view.ex",
    all: "layout_view.ex",
    all: "coherence_view_helpers.ex",
    recoverable: "password_view.ex",
    registerable: "registration_view.ex",
    authenticatable: "session_view.ex",
    unlockable_with_token: "unlock_view.ex"
  ]

  def view_files, do: @view_files

  def gen_coherence_views(%{views: true, boilerplate: true, binding: binding, web_path: web_path} = config) do
    files = Enum.filter_map(@view_files, &(validate_option(config, elem(&1,0))), &(elem(&1, 1)))
    |> Enum.map(&({:eex, &1, Path.join(web_path, "views/coherence/#{&1}")}))

    copy_from paths(), "priv/templates/coh.install/views/coherence", "", [{:otp_app, Mix.Phoenix.otp_app()} | binding], files, config
    config
  end

  def gen_coherence_views(config), do: config

  @template_files [
    email: {:use_email?, ~w(confirmation invitation password unlock)},
    invitation: {:invitable, ~w(edit new)},
    layout: {:all, ~w(app email)},
    password: {:recoverable, ~w(edit new)},
    registration: {:registerable, ~w(new edit form show)},
    session: {:authenticatable, ~w(new)},
    unlock: {:unlockable_with_token, ~w(new)},
    confirmation: {:confirmable, ~w(new)}
  ]

  def template_files, do: @template_files

  defp validate_option(_, :all), do: true
  defp validate_option(%{use_email?: true}, :use_email?), do: true
  defp validate_option(%{opts: opts}, opt) do
    if opt in opts, do: true, else: false
  end

  ################
  # Templates

  def gen_coherence_templates(%{templates: true, boilerplate: true, binding: binding} = config) do
    for {name, {opt, files}} <- @template_files do
      if validate_option(config, opt), do: copy_templates(binding, name, files, config)
    end
    config
  end

  def gen_coherence_templates(config), do: config

  defp copy_templates(binding, name, file_list, %{web_path: web_path} = config) do
    files = for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, Path.join(web_path, "templates/coherence/#{name}/#{fname}")}
    end

    copy_from paths(),
      "priv/templates/coh.install/templates/coherence/#{name}", "", binding, files, config
  end

  ################
  # Mailer

  defp gen_coherence_mailer(%{binding: binding, use_email?: true, boilerplate: true, web_path: web_path} = config) do
    copy_from paths(),
      "priv/templates/coh.install/emails/coherence", "", binding, [
        {:eex, "coherence_mailer.ex", Path.join(web_path, "emails/coherence/coherence_mailer.ex")},
        {:eex, "user_email.ex", Path.join(web_path, "emails/coherence/user_email.ex")},
      ], config
    config
  end

  defp gen_coherence_mailer(config), do: config

  ################
  # Controllers

  @controller_files [
    confirmable: "confirmation_controller.ex",
    invitable: "invitation_controller.ex",
    recoverable: "password_controller.ex",
    registerable: "registration_controller.ex",
    authenticatable: "session_controller.ex",
    unlockable_with_token: "unlock_controller.ex"
  ]

  def controller_files, do: @controller_files

  defp gen_coherence_controllers(%{controllers: true, boilerplate: true, binding: binding, web_path: web_path} = config) do
    files = Enum.filter_map(@controller_files, &(validate_option(config, elem(&1,0))), &(elem(&1, 1)))
    |> Enum.map(&({:eex, &1, Path.join(web_path, "controllers/coherence/#{&1}")}))

    copy_from paths(), "priv/templates/coh.install/controllers/coherence", "", binding, files, config
    config
  end

  defp gen_coherence_controllers(config), do: config

  ################
  # Instructions

  defp seeds_instructions(%{repo: repo, user_schema: user_schema, authenticatable: true} = config) do
    user_schema = to_string user_schema
    repo = to_string repo
    block =
      """
      You might want to add the following to your priv/repo/seeds.exs file.

      #{repo}.delete_all #{user_schema}

      #{user_schema}.changeset(%#{user_schema}{}, %{name: "Test User", email: "testuser@example.com", password: "secret", password_confirmation: "secret"})
      |> #{repo}.insert!
      """
      confirm = if config[:confirmable], do: "|> Coherence.ControllerHelpers.confirm!\n", else: ""
      block <> confirm
  end

  defp seeds_instructions(_config), do: ""

  defp schema_instructions(%{base: base, found_model?: false}), do: """
    Add the following items to your User model (Phoenix v1.2).

    defmodule #{base}.User do
      use Ecto.Schema
      use Coherence.Schema     # Add this

      schema "users" do
        field :name, :string
        field :email, :string
        coherence_schema()       # Add this

        timestamps
      end

      def changeset(model, params \\ %{}) do
        model
        |> cast(params, [:name, :email] ++ coherence_fields)
        |> validate_required([:name, :email])
        |> unique_constraint(:email)
        |> validate_coherence(params)             # Add this
      end

      def changeset(model, params, :password) do
        model
        |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
        |> validate_coherence_password_reset(params)
      end
    end
    """

  defp schema_instructions(_), do: ""

  defp mix_instructions(%{base: base}), do: """
    Add :coherence to your applications list in mix.exs.

    def application do
      [mod: {#{base}, []},
       extra_applications: [..., :coherence]]
    end
  """

  defp router_instructions(%{base: base, router: router, controllers: controllers}) do
    namespace = if controllers, do: ", #{base}", else: ""

    """
    Add the following to your router.ex file.

    defmodule #{router} do
      use #{base}.Web, :router
      use Coherence.Router         # Add this

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_flash
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug Coherence.Authentication.Session  # Add this
      end

      pipeline :protected do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_flash
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug Coherence.Authentication.Session, protected: true  # Add this
      end

      # Add this block
      scope "/"#{namespace} do
        pipe_through :browser
        coherence_routes()
      end

      # Add this block
      scope "/"#{namespace} do
        pipe_through :protected
        coherence_routes :protected
      end

      scope "/", #{base}.Web do
        pipe_through :browser
        get "/", PageController, :index
        # Add public routes below
      end

      scope "/", #{base}.Web do
        pipe_through :protected
        # Add protected routes below
      end
    end
    """
  end

  defp migrate_instructions(%{migrations: true, boilerplate: true}) do
    """
    Don't forget to run the new migrations and seeds with:
        $ mix ecto.setup
    """
  end

  defp migrate_instructions(_), do: ""

  defp print_instructions(%{silent: true} = config), do: config
  defp print_instructions(%{instructions: instructions} = config) do
    Mix.shell.info instructions
    Mix.shell.info mix_instructions(config)
    Mix.shell.info router_instructions(config)
    Mix.shell.info schema_instructions(config)
    Mix.shell.info seeds_instructions(config)
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

  ################
  # Utilities

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  defp do_default_config(config, opts) do
    @default_booleans
    |> list_to_atoms
    |> Enum.reduce(config, fn opt, acc ->
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

  ################
  # Installer Configuration

  defp do_config(opts, []) do
    do_config(opts, list_to_atoms(@default_options))
  end

  defp do_config(opts, bin_opts) do
    binding =
      Mix.Project.config
      |> Keyword.fetch!(:app)
      |> Atom.to_string
      |> Mix.Phoenix.inflect

    # IO.puts "binding: #{inspect binding}"

    base = opts[:module] || binding[:base]
    opts = Keyword.put(opts, :base, base)
    repo = (opts[:repo] || "#{base}.Repo")
    router = (opts[:router] || "#{base}.Web.Router")
    web_path = opts[:web_path] || web_path()

    unless File.exists?(web_path) do
      raise "Could not find web_path: #{web_path}"
    end

    binding =
      binding
      |> Keyword.put(:base, base)
      |> Keyword.put(:web_path, web_path)
      |> Keyword.put(:otp_app, Mix.Phoenix.otp_app())

    {user_schema, user_table_name} = parse_model(opts[:model], base, opts)

    opts_map = do_bin_opts(bin_opts)

    user_email = Enum.any?(bin_opts, &(&1 in @email_options))
    the_timestamp = String.to_integer timestamp()

    [
      instructions: "",
      base: base,
      use_email?: user_email,
      user_schema: user_schema,
      user_table_name: user_table_name,
      repo: repo,
      router: router,
      opts: bin_opts,
      binding: binding,
      log_only: opts[:log_only],
      controllers: opts[:controllers],
      migration_path: opts[:migration_path],
      module: opts[:module],
      timestamp: the_timestamp,
      installed_options: opts[:installed_options],
      confirm: opts[:confirm],
      confirm_once: opts[:confirm_once],
      reinstall: opts[:reinstall],
      silent: opts[:silent],
      with_migrations: opts[:with_migrations],
      web_path: web_path,
    ]
    |> Enum.into(opts_map)
    |> do_default_config(opts)
  end

  defp do_bin_opts(bin_opts) do
    bin_opts
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})
  end

  defp parse_model(model, _base, opts) when is_binary(model) do
    case String.split(model, " ", trim: true) do
      [model, table] ->
        {prefix_model(model, opts), String.to_atom(table)}
      [_] ->
        Mix.raise(
          """
          The mix coh.install --model option expects both singular and plural names. For example:

              mix coh.install --model="Account accounts"
          """)
    end
  end

  defp parse_model(_, base, _) do
    {"#{base}.User", :users}
  end

  defp prefix_model(model, opts) do
    module = opts[:module] || opts[:base]
    if String.starts_with? model, module do
      model
    else
      module <> "." <>  model
    end
  end

  defp option_reduce({:default, true}, {acc_bin, acc}),
    do: {list_to_atoms(@default_options) ++ acc_bin, acc}
  defp option_reduce({:full, true}, {acc_bin, acc}),
    do: {list_to_atoms(@full_options) ++ acc_bin, acc}
  defp option_reduce({:full_confirmable, true}, {acc_bin, acc}),
    do: {list_to_atoms(@full_confirmable) ++ acc_bin, acc}
  defp option_reduce({:full_invitable, true}, {acc_bin, acc}),
    do: {list_to_atoms(@full_invitable) ++ acc_bin, acc}
  defp option_reduce({:trackable_table, true}, {acc_bin, acc}),
    do: {[:trackable_table | acc_bin] -- [:trackable], acc}
  defp option_reduce({name, true}, {acc_bin, acc}) when name in @all_options_atoms,
    do: {[name | acc_bin], acc}
  defp option_reduce({name, false}, {acc_bin, acc}) when name in @all_options_atoms,
    do: {acc_bin -- [name], acc}
  defp option_reduce(opt, {acc_bin, acc}),
    do: {acc_bin, [opt | acc]}

  defp parse_options(opts) do
    {opts_bin, opts} = Enum.reduce opts, {[], []}, &(option_reduce(&1, &2))
        # {:default, true}, {acc_bin, acc} ->
        #   {list_to_atoms(@default_options) ++ acc_bin, acc}
        # {:full, true}, {acc_bin, acc} ->
        #   {list_to_atoms(@full_options) ++ acc_bin, acc}
        # {:full_confirmable, true}, {acc_bin, acc} ->
        #   {list_to_atoms(@full_confirmable) ++ acc_bin, acc}
        # {:full_invitable, true}, {acc_bin, acc} ->
        #   {list_to_atoms(@full_invitable) ++ acc_bin, acc}
        # {:trackable_table, true}, {acc_bin, acc} ->
        #   {[:trackable_table | acc_bin] -- [:trackable], acc}
        # {name, true}, {acc_bin, acc} when name in @all_options_atoms ->
        #   {[name | acc_bin], acc}
        # {name, false}, {acc_bin, acc} when name in @all_options_atoms ->
        #   {acc_bin -- [name], acc}
        # opt, {acc_bin, acc} ->
        #   {acc_bin, [opt | acc]}
      # end

    opts_bin = Enum.uniq(opts_bin)
    opts_names = Enum.map opts, &(elem(&1, 0))

    with  [] <- Enum.filter(opts_bin, &(not &1 in @switch_names)),
          [] <- Enum.filter(opts_names, &(not &1 in @switch_names)) do
      {opts_bin, opts}
    else
      list -> raise_option_errors(list)
    end
  end

  def all_options, do: @all_options_atoms

  def print_installed_options(_config) do
    ["mix coh.install"]
    |> list_config_options(Application.get_env(:coherence, :opts, []))
    |> Enum.reverse
    |> Enum.join(" ")
    |> Mix.shell.info
  end

  def list_config_options(acc, opts) do
    Enum.reduce(opts, acc, &config_option/2)
  end

  def get_config_options([]) do
    Mix.raise(
      """
      Could not find coherence configuration.
      """)
  end

  def get_config_options(opts) do
    :coherence
    |> Application.get_env(:opts, [])
    |> get_config_options(opts)
  end

  def get_config_options([], _opts) do
    Mix.raise(
      """
      Could not find coherence configuration for re-installation. Please remove the --reinstall option to do a fresh install.
      """)
  end

  def get_config_options(config_opts, opts) do
    Enum.reduce(config_opts, opts, &config_option/2)
  end

  defp config_option(opt, acc) when is_atom(opt) do
    str = opt |> Atom.to_string |> String.replace("_", "-")
    ["--" <> str | acc]
  end

  defp config_option(opt, acc) when is_tuple(opt) do
    str = opt |> elem(0) |> Atom.to_string |> String.replace("_", "-")
    ["--" <> str | acc]
  end

  @doc """
  Copies files from source dir to target dir
  according to the given map.
  Files are evaluated against EEx according to
  the given binding.
  """
  def copy_from(apps, source_dir, target_dir, binding, mapping, config) when is_list(mapping) do
    roots = Enum.map(apps, &to_app_source(&1, source_dir))

    create_opts = if config[:confirm], do: [], else: [force: true]

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
  end

  defp to_app_source(path, source_dir) when is_binary(path),
    do: Path.join(path, source_dir)
  defp to_app_source(app, source_dir) when is_atom(app),
    do: Application.app_dir(app, source_dir)

  # defp web_path(), do: Mix.Phoenix.web_path(Mix.Phoenix.otp_app())
  defp web_path() do
    path1 = Path.join ["lib", to_string(Mix.Phoenix.otp_app()), "web"]
    path2 = "web"
    cond do
      File.exists? path1 -> path1
      File.exists? path2 -> path2
      true ->
        raise "Could not find web path '#{path1}'. Please use --web-path option to specify"
    end
  end
end
