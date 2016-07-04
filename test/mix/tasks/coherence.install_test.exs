Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.Coherence.InstallTest do
  use ExUnit.Case
  alias Coherence.Config
  import MixHelper

  setup do
    # Mix.Task.clear
    :ok
  end
  # opts: [:invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :registerable]

  test "generates_files_for_authenticatable" do
    in_tmp "generates_views_for_authenticatable", fn ->
      ~w(--repo=TestCoherence.Repo --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run
      assert File.exists? "web/views/coherence/session_view.ex"
      assert File.exists? "web/views/coherence/coherence_view.ex"
      assert File.exists? "web/views/coherence/layout_view.ex"
      ~w(password_view.ex invitation_view.ex registration_view.ex unlock_view.ex)
      |> Enum.each(fn file ->
        refute File.exists? "web/views/coherence/#{file}"
      end)
    end
  end

  test "generates files for authenticatable recoverable" do
    in_tmp "generates_files_for_authenticatable_recoverable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run
      assert File.exists? "web/views/coherence/session_view.ex"
      assert File.exists? "web/views/coherence/coherence_view.ex"
      assert File.exists? "web/views/coherence/layout_view.ex"
      assert File.exists? "web/views/coherence/password_view.ex"
      ~w(invitation_view.ex registration_view.ex unlock_view.ex)
      |> Enum.each(fn file ->
        refute File.exists? "web/views/coherence/#{file}"
      end)
    end
  end

  test "generates files for authenticatable recoverable invitable" do
    in_tmp "generates_files_for_authenticatable_recoverable_invitable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --invitable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run
      assert File.exists? "web/views/coherence/session_view.ex"
      assert File.exists? "web/views/coherence/coherence_view.ex"
      assert File.exists? "web/views/coherence/layout_view.ex"
      assert File.exists? "web/views/coherence/password_view.ex"
      assert File.exists? "web/views/coherence/invitation_view.ex"
      ~w(registration_view.ex unlock_view.ex)
      |> Enum.each(fn file ->
        refute File.exists? "web/views/coherence/#{file}"
      end)
    end
  end

  test "generates files for authenticatable recoverable registerable" do
    in_tmp "generates_files_for_authenticatable_recoverable_registerable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --registerable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run
      assert File.exists? "web/views/coherence/session_view.ex"
      assert File.exists? "web/views/coherence/coherence_view.ex"
      assert File.exists? "web/views/coherence/layout_view.ex"
      assert File.exists? "web/views/coherence/password_view.ex"
      assert File.exists? "web/views/coherence/registration_view.ex"
      ~w(unlock_view.ex invitation_view.ex)
      |> Enum.each(fn file ->
        refute File.exists? "web/views/coherence/#{file}"
      end)
    end
  end

  test "generates files for authenticatable recoverable unlockable_with_token" do
    in_tmp "generates_files_for_authenticatable_recoverable_registerable_unlockable_with_token", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --registerable --lockable --unlockable-with-token --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run
      assert File.exists? "web/views/coherence/session_view.ex"
      assert File.exists? "web/views/coherence/coherence_view.ex"
      assert File.exists? "web/views/coherence/layout_view.ex"
      assert File.exists? "web/views/coherence/password_view.ex"
      assert File.exists? "web/views/coherence/registration_view.ex"
      assert File.exists? "web/views/coherence/unlock_view.ex"
      ~w(invitation_view.ex)
      |> Enum.each(fn file ->
        refute File.exists? "web/views/coherence/#{file}"
      end)
    end
  end
end
