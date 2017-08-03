defmodule Mix.Tasks.Coh.Clean do
  @moduledoc """
  This task will clean most of the files installed by the `mix coh.install` task.

  Projects created with both `coh.install` and `coherence.install` can be
  cleaned with this task. It will auto detect the project structure and remove
  the appropriate files.

  ## Examples

      # Clean all the installed files
      mix coh.clean --all

      # Clean only the installed view and template files
      mix coh.clean --views --templates

      # Clean all but the models
      mix coh.clean --all --no-models

      # Prompt once to confirm the removal
      mix coh.clean --all --confirm-once

      # Clean installed options
      mix coh.clean --options rememberable
      mix coh.clean --options "registerable invitable trackable"

  The following options are supported:

  * `--all` -- clean all files
  * `--views` -- clean view files
  * `--templates` -- clean template files
  * `--models` -- clean models files
  * `--controllers` -- clean controller files
  * `--email` -- clean email files
  * `--web` -- clean the web/coherence_web.ex file
  * `--messages` -- clean the web/coherence_messages.ex file
  * `--migrations` -- clean the migration files
  * `--options` -- Clean one or more specific options
  * `--dry-run` -- Show what will be removed, but don't actually remove any files
  * `--confirm-once` -- confirm once before removing all selected files

  Disable options:

  * `--no-confirm` - don't confirm before removing files
  """
  use Mix.Task

  import Coherence.Mix.Utils
  import Mix.Ecto

  alias Mix.Tasks.Coh.Install

  @shortdoc "Clean files created by the coherence installer."

  @dialyzer [
    {:nowarn_function, raise_options_error!: 2},
  ]

  @config_file "config/config.exs"
  @remove_opts ~w(views templates models controllers emails web messages migrations config)a
  @default_opts ~w(confirm)a
  @clean_opts [{:options, :string}]
  @switches Enum.map([:all, :confirm_once | @remove_opts] ++ @default_opts, &({&1, :boolean})) ++ @clean_opts ++ [dry_run: :boolean]

  @spec run([String.t] | []) :: any
  def run(args) do
    args
    |> OptionParser.parse(switches: @switches)
    |> do_config
    |> do_clean
    |> do_clean_options
  end

  defp do_clean(config) do
    confirm_once(config, fn config ->
      Enum.reduce @remove_opts, config, &(remove! &2, &1)
    end)
  end

  defp do_clean_options(config) do
    confirm_once(config, fn config ->
      remove! config, :options
    end)
  end

  defp confirm_once(%{confirm_once: true} = config, fun) do
    config = Map.put config, :confirm, false
    if Mix.shell.yes? "Are you sure you want to delete coherence files?" do
      fun.(config)
    end
    config
  end

  defp confirm_once(config, fun) do
    fun.(config)
  end

  defp valid_option?(all_options, option) do
    Enum.any? all_options, &(&1 == option)
  end

  defp validate_options!(options, all_options) do
    case Enum.filter(options, &(not valid_option?(all_options, &1))) do
      [] -> :ok
      list -> raise_options_error!(list, all_options)
    end
  end

  defp option_string(options) do
    options
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(", ")
  end

  defp raise_options_error!(list, all_options) do
    Mix.raise """
    Invalid Option(s): '#{option_string(list)}' are not valid option(s)

    Please choose from list:
    '#{option_string(all_options)}'
    """
  end

  defp get_current_options(options) do
    :coherence
    |> Application.get_env(:opts)
    |> log_invalid_options(options)
  end

  defp log_invalid_options(current_options, options) do
    case Enum.filter(options, &(not valid_option?(current_options, &1))) do
      [] ->
        options
      invalid_list ->
        Mix.shell.info "Option(s) #{option_string(invalid_list)} where not found in your configuration. They will not be removed."
        options -- invalid_list
    end
  end

  defp remove_view_file!(option, config) do
    view_files = Install.view_files
    case view_files[option] do
      nil ->
        :ok
      file_name ->
        path = web_path ["views", "coherence", file_name]
        confirm config, path, fn -> rm!(path) end
    end
    option
  end

  defp remove_template_files!(option, config) do
    files = Install.template_files
    files
    |> Enum.find(fn {_, {opt, _}} -> opt == option end)
    |> case do
      nil ->
        :ok
      {path, _} ->
        path = web_path ["templates", "coherence", "#{path}"]
        confirm config, path, fn -> rm_dir!(path) end
    end
    option
  end

  defp remove_controller_files!(option, config) do
    case controller_files()[option] do
      nil ->
        :ok
      file_name ->
        path = web_path ["controllers", "coherence", file_name]
        confirm config, path, fn -> rm!(path) end
    end
    option
  end

  defp remove_config_options!(options, config) do
    with contents when is_binary(contents) <- File.read!(@config_file),
        [_, opts_string] when is_binary(opts_string) <- Regex.run(~r/opts:\s*(\[.*?\])/, contents) do
      remove_config_options!(config, contents, options, opts_string)
    else
      error ->
        Mix.raise """
        Problem updating config, error: #{inspect error}
        """
    end
  end

  defp remove_config_options!(config, contents, options, opts_string) do
    new_opts_string =
      Enum.reduce options, opts_string, fn option, acc ->
        String.replace acc, ~r/(,\s*:#{option})|(:#{option}\s*,?\s*)/, ""
      end
    message = ~s'"opts: #{stringify opts_string}" with "opts: #{stringify new_opts_string}"'
    confirm_config config, message, fn ->
      File.write!(@config_file, String.replace(contents, opts_string, new_opts_string))
    end
    config
  end

  defp stringify(item) do
    item
    |> inspect
    |> String.replace("\"", "")
  end

  defp remove_option!(config, option) do
    option
    |> remove_view_file!(config)
    |> remove_template_files!(config)
    |> remove_controller_files!(config)
  end

  defp remove!(%{options: options} = config, :options) do
    all_options = Install.all_options
    options =
      options
      |> String.split(" ", trim: true)
      |> Enum.map(&(String.replace &1, "-", "_"))
      |> Enum.map(&String.to_atom/1)

    validate_options!(options, all_options)

    options
    |> get_current_options
    |> Enum.map(&(remove_option!(config, &1)))
    |> remove_config_options!(config)

    config
  end

  defp remove!(%{templates: true} = config, :templates) do
    path = web_path "templates/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end

  defp remove!(%{views: true} = config, :views) do
    path = web_path "views/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end

  defp remove!(%{controllers: true} = config, :controllers) do
    path = web_path "controllers/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end

  defp remove!(%{models: true} = config, :models) do
    path = lib_path "coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end

  defp remove!(%{web: true} = config, :web) do
    path = web_path "coherence_web.ex"
    confirm config, path, fn -> rm!(path) end
  end

  defp remove!(%{messages: true} = config, :messages) do
    path = web_path "coherence_messages.ex"
    confirm config, path, fn -> rm!(path) end
  end

  defp remove!(%{emails: true} = config, :emails) do
    path = web_path ~w(emails coherence)
    confirm config, path, fn -> rm_dir!(path) end
  end

  defp remove!(%{migrations: true} = config, :migrations) do
    case Application.get_env :coherence, :repo do
      nil ->
        Mix.shell.error "Config.repo not configured. Skipping migration removal!"
      repo ->
        do_remove!(config, repo)
    end
  end

  defp remove!(%{config: true} = config, :config) do
    confirm config, "coherence config", fn ->
      regex = ~r/# %% Coherence Configuration %%.+?# %% End Coherence Configuration %%/s
      conf = File.read! @config_file
      File.write! @config_file, String.replace(conf, regex, "")
    end
  end

  defp remove!(config, _), do: config

  defp do_remove!(config, repo) do
    ensure_repo(repo, [])
    path = Path.relative_to(migrations_path(repo), Mix.Project.app_path)
    case Path.wildcard(path <> "/*coherence*") do
      [] ->
        config
      files ->
        confirmed? =
          if config[:confirm] do
            Mix.shell.info "Found migrations: " <> Enum.join(files, ", ")
            Mix.shell.yes? "Delete them?"
          else
            true
          end
        if confirmed? do
          Enum.each files, &(rm! &1)
        end
        config
    end
  end

  defp confirm_config(%{dry_run: true} = config, message, _fun) do
    Mix.shell.info "Update config " <> message
    config
  end

  defp confirm_config(%{confirm: true} = config, message, fun) do
    if Mix.shell.yes? "Update config " <> message <> "?" do
      Mix.shell.info "Updating config " <> message
      fun.()
    end
    config
  end

  defp confirm_config(config, message, fun) do
    Mix.shell.info "Updating config " <> message
    fun.()
    config
  end

  defp confirm(%{dry_run: true} = config, path, _fun) do
    Mix.shell.info "Delete #{path}"
    config
  end

  defp confirm(%{confirm: true} = config, path, fun) do
    if File.exists? path do
      if Mix.shell.yes? "Delete #{path}?" do
        fun.()
      end
    else
      Mix.shell.error "Problem removing #{path}"
    end
    config
  end
  defp confirm(config, _path, fun) do
    fun.()
    config
  end

  ###############
  # configuration

  defp do_config({opts, parsed, unknown}) do
    opts
    |> verify_opts(parsed, unknown)
    |> Enum.into(%{})
    |> do_all_config
    |> do_default_config
  end

  defp do_all_config(%{all: true} = config) do
    Enum.reduce @remove_opts, config, &(Map.put_new(&2, &1, true))
  end
  defp do_all_config(config), do: config

  defp do_default_config(config) do
    Enum.reduce @default_opts, config, fn opt, config ->
      Map.put config, opt, Map.get(config, opt, true)
    end
  end

  defp verify_opts(opts, parsed, unknown) do

    verify_args!(parsed, unknown)

    switch_keys = Keyword.keys @switches

    case opts |> Keyword.keys |> Enum.filter(&(not &1 in switch_keys)) do
      [] -> opts
      list -> raise_option_errors(list)
    end
  end

  defp coh? do
    not File.exists?("web")
  end

  defp web_path(path) when is_binary(path), do: Path.join(web_path(), path)
  defp web_path(paths), do: Path.join([web_path() | paths])
  defp web_path do
    if coh?(), do: Path.join("lib", otp_app() <> "_web"), else: "web"
  end

  defp lib_path, do: Path.join("lib", otp_app())
  defp lib_path(path) when is_binary(path), do: Path.join(lib_path(), path)
  defp lib_path(paths), do: Path.join([lib_path() | paths])

  defp otp_app do
    Mix.Project.config[:app] |> to_string
  end
end
