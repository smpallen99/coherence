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
  @all_controllers Enum.map(@all_template_dirs -- ~w(layout email), &("#{&1}_controller.ex"))

  test "generates_files_for_authenticatable" do
    in_tmp "generates_views_for_authenticatable", fn ->
      ~w(--repo=TestCoherence.Repo --log-only --no-migrations --controllers --module=TestCoherence)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")

      ~w(session_controller.ex)
      |> assert_file_list(@all_controllers, "web/controllers/coherence/")

      assert_file "web/controllers/coherence/session_controller.ex", fn file ->
        assert file =~ "defmodule TestCoherence.Coherence.SessionController do"
      end
    end
  end

  test "generates files for authenticatable recoverable" do
    in_tmp "generates_files_for_authenticatable_recoverable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --log-only --no-migrations --controllers)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password email)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")

      ~w(session_controller.ex password_controller.ex)
      |> assert_file_list(@all_controllers, "web/controllers/coherence/")
    end
  end

  test "generates files for authenticatable recoverable invitable" do
    in_tmp "generates_files_for_authenticatable_recoverable_invitable", fn ->
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --invitable --log-only --no-migrations --controllers --module=TestCoherence)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex invitation_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password invitation email)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")

      ~w(session_controller.ex password_controller.ex invitation_controller.ex)
      |> assert_file_list(@all_controllers, "web/controllers/coherence/")

      assert_file "web/controllers/coherence/session_controller.ex", fn file ->
        assert file =~ "defmodule TestCoherence.Coherence.SessionController do"
      end
      assert_file "web/controllers/coherence/password_controller.ex", fn file ->
        assert file =~ "defmodule TestCoherence.Coherence.PasswordController do"
      end
      assert_file "web/controllers/coherence/invitation_controller.ex", fn file ->
        assert file =~ "defmodule TestCoherence.Coherence.InvitationController do"
      end
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
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --registerable --lockable --unlockable-with-token --log-only --no-migrations --controllers)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex registration_view.ex unlock_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password registration unlock email)
      |> assert_dirs(@all_template_dirs, "web/templates/coherence/")

      ~w(session_controller.ex password_controller.ex registration_controller.ex unlock_controller.ex)
      |> assert_file_list(@all_controllers, "web/controllers/coherence/")
    end
  end

  test "generates files for --full-invitable --no-registerable" do
    in_tmp "generates_files_for_fill_invitable_no_registerable", fn ->
      ~w(--repo=TestCoherence.Repo  --full-invitable --no-registerable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex invitation_view.ex unlock_view.ex email_view.ex)
      |> assert_file_list(@all_views, "web/views/coherence/")

      ~w(layout session password invitation unlock email)
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

      ~w()
      |> assert_file_list(@all_controllers, "web/controllers/coherence/")
    end
  end

  describe "generates migrations" do
    test "for_default_model" do
      in_tmp "for_default_model", fn ->
        path = "migrations"
        (~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --log-only --no-views --no-templates --migration-path=#{path}))
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_add_coherence_to_user.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.AddCoherenceToUser do"
          assert file =~ "alter table(:users) do"
          assert file =~ "add :encrypted_password, :string"
          assert file =~ "add :reset_password_token, :string"
          assert file =~ "add :reset_password_sent_at, :datetime"
        end
      end
    end
    test "for_custom_model" do
      in_tmp "for_custom_model", fn ->
        path = "migrations"
        (~w(--repo=TestCoherence.Repo  --full --log-only --no-views --no-templates --migration-path=#{path}) ++ ["--model=Account accounts"])
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_add_coherence_to_account.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.AddCoherenceToAccount do"
          assert file =~ "alter table(:accounts) do"
          assert file =~ "add :encrypted_password, :string"
          assert file =~ "add :reset_password_token, :string"
          assert file =~ "add :reset_password_sent_at, :datetime"
          assert file =~ "add :failed_attempts, :integer, default: 0"
          assert file =~ "add :unlock_token, :string"
          assert file =~ "add :locked_at, :datetime"
          assert file =~ "add :sign_in_count, :integer, default: 0"
          assert file =~ "add :current_sign_in_at, :datetime"
          assert file =~ "add :last_sign_in_at, :datetime"
          assert file =~ "add :current_sign_in_ip, :string"
          assert file =~ "add :last_sign_in_ip, :string"
        end
      end
    end
    test "for_invitible" do
      in_tmp "for_invitible", fn ->
        (~w(--repo=TestCoherence.Repo  --authenticatable --invitable --log-only --no-views --no-templates --migration-path=migrations))
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_create_coherence_invitable.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.CreateCoherenceInvitable do"

          assert file =~ "create table(:invitations) do"
          assert file =~ "add :name, :string"
          assert file =~ "add :email, :string"
          assert file =~ "add :token, :string"
          assert file =~ "timestamps"
          assert file =~ "create unique_index(:invitations, [:email])"
          assert file =~ "create index(:invitations, [:token])"
        end
      end
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
