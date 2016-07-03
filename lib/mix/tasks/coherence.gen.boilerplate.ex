defmodule Mix.Tasks.Coherence.Gen.Boilerplate do
  use Mix.Task

  @shortdoc "Generates Coherence boilerplate"

  @moduledoc """
  """


  def run(args) do
    binding = Mix.Project.config
    |> Keyword.fetch!(:app)
    |> Atom.to_string
    |> Mix.Phoenix.inflect
    IO.puts "binding: #{inspect binding}"
    copy_coherence_boilerplate(binding)
  end

  @template_files [
    email: ~w(confirmation invitation password unlock),
    invitation: ~w(edit new),
    layout: ~w(app email),
    password: ~w(edit new),
    registration: ~w(new),
    session: ~w(new),
    unlock: ~w(new)
  ]
  def copy_coherence_boilerplate(binding) do

    for {name, list} <- @template_files do
      copy_boilerplate(binding, name, list)
    end
    # Mix.Phoenix.copy_from coherence_paths(), "priv/templates/coherence.gen.boilerplate/coherence/email", "", binding, [
    #   {:eex, "confirmation.html.eex", "web/templates/coherence/email/confirmation.html.eex"},
    #   {:eex, "invitation.html.eex", "web/templates/coherence/email/invitation.html.eex"},
    #   {:eex, "password.html.eex", "web/templates/coherence/email/password.html.eex"},
    #   {:eex, "unlock.html.eex", "web/templates/coherence/email/unlock.html.eex"},
    # ]
  end

  def copy_boilerplate(binding, name, file_list) do
    list = for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, "web/templates/coherence/#{name}/#{fname}"}
    end

    Mix.Phoenix.copy_from coherence_paths(),
      "priv/templates/coherence.gen.boilerplate/coherence/#{name}", "", binding, list
  end

  defp coherence_paths do
    [".", :coherence]
  end
end
