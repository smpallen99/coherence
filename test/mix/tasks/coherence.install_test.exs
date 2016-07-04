Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.Coherence.InstallTest do
  use ExUnit.Case
  alias Coherence.Config
  import MixHelper

  setup do
    :ok
  end
  # opts: [:invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :registerable]

  @all_template_dirs ~w(layout session email invitation password registration unlock)
  @all_views ~w(coherence_view.ex confirmation_view.ex email_view.ex invitation_view.ex) ++
    ~w(layout_view.ex password_view.ex registration_view.ex session_view.ex unlock_view.ex)

  test "generates_files_for_authenticatable" do
    in_tmp "generates_views_for_authenticatable", fn ->
      ~w(--repo=TestCoherence.Repo --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")
    end
  end

  test "generates files for authenticatable recoverable" do
    in_tmp "generates_files_for_authenticatable_recoverable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password email)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")
    end
  end

  test "generates files for authenticatable recoverable invitable" do
    in_tmp "generates_files_for_authenticatable_recoverable_invitable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --invitable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex invitation_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password invitation email)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")
    end
  end

  test "generates files for authenticatable recoverable registerable" do
    in_tmp "generates_files_for_authenticatable_recoverable_registerable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --registerable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex registration_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password registration email)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")
    end
  end

  test "generates files for authenticatable recoverable unlockable_with_token" do
    in_tmp "generates_files_for_authenticatable_recoverable_registerable_unlockable_with_token", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --registerable --lockable --unlockable-with-token --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex registration_view.ex unlock_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password registration unlock email)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")
    end
  end

  test "does not generate files for full" do
    in_tmp "does_not_generate_files_for_full", fn ->
      ~w(--repo=TestCoherence.Repo  --full --log-only --no-migrations --no-boilerplate)
      |> Mix.Tasks.Coherence.Install.run

      ~w()
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w()
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")
    end
  end

  def assert_dirs(dirs, full_dirs, path) do
    Enum.each dirs, fn dir ->
      assert File.dir? path <> dir
    end
    Enum.each full_dirs -- dirs, fn dir ->
      refute File.dir? path <> dir
    end
  end

  def assert_file_list(files, full_files, path) do
    Enum.each files, fn file ->
      assert_file path <> file
    end
    Enum.each full_files -- files, fn file ->
      refute_file path <> file
    end
  end
end
