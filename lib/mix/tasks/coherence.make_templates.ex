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

  @source_path Path.join(~w(. lib coherence controllers))
  @dest_path_coh Path.join(~w(. priv templates coh.gen.controllers controllers coherence))

  def run(_) do
    if function_exported?(Mix.Phoenix, :otp_app, 0) &&
      apply(Mix.Phoenix, :otp_app, []) != :coherence do

      raise "Task only supported for Coherence Dev"
    end

    copy_templates @dest_path_coh
    Mix.shell.info "All controller templates copied"
  end

  defp copy_templates(dest_path) do
    controller_files()
    |> Enum.each(fn fname ->
      contents =
        @source_path
        |> Path.join(fname)
        |> File.read!
        |> String.replace("defmodule ", "defmodule <%= web_base %>.")
        |> String.replace("use Coherence.Web,", "use <%= web_module %>,")
        |> String.replace("alias Coherence.Schemas", "alias <%= base %>.Coherence.Schemas")

      dest_path
      |> Path.join(fname)
      |> File.write!(contents)
    end)
  end

end
