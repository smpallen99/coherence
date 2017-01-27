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
  @dest_path Path.join(~w(. priv templates coherence.install controllers coherence))

  def run(_) do
    controller_files()
    |> Enum.each(fn fname ->
      contents =
        @source_path
        |> Path.join(fname)
        |> File.read!
        |> String.replace("defmodule Coh", "defmodule <%= base %>.Coh")

      @dest_path
      |> Path.join(fname)
      |> File.write!(contents)
    end)
    Mix.shell.info "All controller templates copied"
  end
end
