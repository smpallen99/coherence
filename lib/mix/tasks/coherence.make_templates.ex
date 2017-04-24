defmodule Mix.Tasks.Coherence.MakeTemplates do
  use Mix.Task

  @shortdoc "Prepares the controller templates"

  @moduledoc """
  This will copy the controller templates from the
  `web/controllers/` directory to the
  `priv/templates/coherence.install/controllers` directory.
  """

  @controller_files [
    confirmable: "confirmation_controller.ex",
    invitable: "invitation_controller.ex",
    recoverable: "password_controller.ex",
    registerable: "registration_controller.ex",
    authenticatable: "session_controller.ex",
    unlockable_with_token: "unlock_controller.ex"
  ]
  def controller_files, do: Enum.map(@controller_files, &(elem(&1, 1)))

  @source_path Path.join(~w(. web controllers))
  @dest_path_coherence Path.join(~w(. priv templates coherence.install controllers coherence))
  @dest_path_coh Path.join(~w(. priv templates coh.install controllers coherence))

  def run(_) do
    copy_templates @dest_path_coherence, :coherence
    copy_templates @dest_path_coh
    Mix.shell.info "All controller templates copied"
  end

  defp copy_templates(dest_path, which \\ :coh) do
    suffix = if which == :coherence, do: "Coh", else: "Web.Coh"
    controller_files()
    |> Enum.each(fn fname ->
      contents =
        @source_path
        |> Path.join(fname)
        |> File.read!
        |> String.replace("defmodule Coh", "defmodule <%= base %>.#{suffix}")
        # |> handle_which(which)

      dest_path
      |> Path.join(fname)
      |> File.write!(contents)
    end)
  end

  # defp handle_which(content, :coherence) do
  #   String.replace(content, "Web.Router.Helpers", "Router.Helpers")
  # end
  # defp handle_which(content, _) do
  #   content
  # end
end
