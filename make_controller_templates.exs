
defmodule MakeControllerTemplates do
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

  def run do
    controller_files
    |> Enum.each(fn fname ->
      contents = Path.join(@source_path, fname)
      |> File.read!
      |> String.replace("defmodule Coh", "defmodule <%= base %>.Coh")

      Path.join(@dest_path, fname)
      |> File.write!(contents)
    end)
  end
end

MakeControllerTemplates.run
