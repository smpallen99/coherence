defmodule Mix.Tasks.Coherence.Clean do
  use Mix.Task

  import Coherence.Mix.Utils
  import Mix.Ecto

  @shortdoc "Clean files created by the coherence installer."

  @moduledoc """
  This task will clean most of the files installed by the `mix coherence.install` task.

  ## Examples

      # Clean all the installed files
      mix coherence.clean --all

      # Clean only the installed view and template files
      mix coherence.clean --views --templates

      # Clean all but the models
      mix coherence.clean --all --no-models

      # Prompt once to confirm the removal
      mix coherence.clean --all --confirm-once

  The following options are supported:

  * `--all` -- clean all files
  * `--views` -- clean view files
  * `--templates` -- clean template files
  * `--models` -- clean models files
  * `--controllers` -- clean controller files
  * `--email` -- clean email files
  * `--web` -- clean the web/coherence_web.ex file
  * `--migrations` -- clean the migration files
  * `--confirm-once` -- confirm once before removing all selected files

  Disable options:

  * `--no-confirm` - don't confirm before removing files
  """

  @config_file "config/config.exs"
  @remove_opts ~w(views templates models controllers emails web migrations config)a
  @default_opts ~w(confirm)a
  @switches Enum.map([:all, :confirm_once | @remove_opts] ++ @default_opts, &({&1, :boolean}))

  def run(args) do
    OptionParser.parse(args, switches: @switches)
    |> do_config
    |> do_clean
  end

  defp do_clean(config) do
    confirm_once config, fn config ->
      Enum.reduce @remove_opts, config, &(remove! &2, &1)
    end
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

  defp remove!(%{templates: true} = config, :templates) do
    path = "web/templates/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end
  defp remove!(%{views: true} = config, :views) do
    path = "web/views/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end
  defp remove!(%{controllers: true} = config, :controllers) do
    path = "web/controllers/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end
  defp remove!(%{models: true} = config, :models) do
    path = "web/models/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end
  defp remove!(%{web: true} = config, :web) do
    path = "web/coherence_web.ex"
    confirm config, path, fn -> rm!(path) end
  end
  defp remove!(%{emails: true} = config, :emails) do
    path = "web/emails/coherence"
    confirm config, path, fn -> rm_dir!(path) end
  end
  defp remove!(%{migrations: true} = config, :migrations) do
    case Application.get_env :coherence, :repo do
      nil ->
        Mix.shell.error "Config.repo not configured. Skipping migration removal!"
      repo ->
        ensure_repo(repo, [])
        path = Path.relative_to(migrations_path(repo), Mix.Project.app_path)
        case Path.wildcard(path <> "/*coherence*") do
          [] -> config
          files ->
            if config[:confirm] do
              Mix.shell.info "Found migrations: " <> Enum.join(files, ", ")
              Mix.shell.yes? "Delete them?"
            else
              true
            end
            |> if do
              Enum.each files, &(rm! &1)
            end
            config
        end
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

  defp confirm(%{confirm: true} = config, path, fun) do
    if File.exists? path do
      if Mix.shell.yes? "Delete #{path}?" do
        fun.()
      end
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
    case Keyword.keys(opts) |> Enum.filter(&(not &1 in switch_keys)) do
      [] -> opts
      list -> raise_option_errors(list)
    end
  end


end
