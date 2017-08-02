Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.Coherence.InstallTest do
  use ExUnit.Case
  import MixHelper

  @web_path "web"
  setup do
    Application.put_env :coherence, :opts, [
      :confirmable, :authenticatable, :recoverable, :lockable, :trackable,
      :unlockable_with_token, :invitable, :registerable, :rememberable]
    :ok
  end
  # opts: [:invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :registerable]

  @all_template_dirs ~w(layout session email invitation password registration unlock)
  @all_views ~w(coherence_view_helpers.ex coherence_view.ex confirmation_view.ex email_view.ex invitation_view.ex) ++
    ~w(layout_view.ex password_view.ex registration_view.ex session_view.ex unlock_view.ex)

  test "generates_files_for_authenticatable" do
    in_tmp "generates_views_for_authenticatable", fn ->
      mk_web_path()
      ~w(--repo=TestCoherence.Repo --log-only --no-migrations --module=TestCoherence)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex coherence_view_helpers.ex)
      |> assert_file_list(@all_views, web_path("views/coherence/"))

      ~w(layout session)
      |> assert_dirs(@all_template_dirs, web_path("templates/coherence/"))

      assert_file web_path("controllers/coherence/redirects.ex"), fn file ->
        assert file =~ "defmodule Coherence.Redirects do"
      end
    end
  end

  test "generates files for authenticatable recoverable" do
    in_tmp "generates_files_for_authenticatable_recoverable", fn ->
      mk_web_path()
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex email_view.ex coherence_view_helpers.ex)
      |> assert_file_list(@all_views, web_path("views/coherence/"))

      ~w(layout session password email)
      |> assert_dirs(@all_template_dirs, "templates/coherence/" |> web_path)
    end
  end

  test "generates files for authenticatable recoverable invitable" do
    in_tmp "generates_files_for_authenticatable_recoverable_invitable", fn ->
      mk_web_path()
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --invitable --log-only --no-migrations --module=TestCoherence)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex invitation_view.ex email_view.ex coherence_view_helpers.ex)
      |> assert_file_list(@all_views, "views/coherence" |> web_path)

      ~w(layout session password invitation email)
      |> assert_dirs(@all_template_dirs, "templates/coherence" |> web_path)
    end
  end

  test "generates files for authenticatable recoverable registerable confirmable" do
    in_tmp "generates_files_for_authenticatable_recoverable_registerable_confirmable", fn ->
      mk_web_path()
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --registerable --confirmable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex registration_view.ex email_view.ex confirmation_view.ex coherence_view_helpers.ex)
      |> assert_file_list(@all_views, "views/coherence/" |> web_path)

      ~w(layout session password registration email confirmation)
      |> assert_dirs(@all_template_dirs, "templates/coherence/" |> web_path)

      for file <- ~w(new edit form show) do
        assert_file "templates/coherence/registration/#{file}.html.eex" |> web_path
      end
    end
  end

  test "generates files for authenticatable recoverable unlockable_with_token" do
    in_tmp "generates_files_for_authenticatable_recoverable_registerable_unlockable_with_token", fn ->
      mk_web_path()
      ~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --registerable --lockable --unlockable-with-token --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex registration_view.ex unlock_view.ex email_view.ex coherence_view_helpers.ex)
      |> assert_file_list(@all_views, "views/coherence/" |> web_path)

      ~w(layout session password registration unlock email)
      |> assert_dirs(@all_template_dirs, "templates/coherence/" |> web_path)
    end
  end

  test "generates files for --full-invitable --no-registerable" do
    in_tmp "generates_files_for_fill_invitable_no_registerable", fn ->
      mk_web_path()
      ~w(--repo=TestCoherence.Repo  --full-invitable --no-registerable --log-only --no-migrations)
      |> Mix.Tasks.Coherence.Install.run

      ~w(session_view.ex coherence_view.ex layout_view.ex password_view.ex invitation_view.ex unlock_view.ex email_view.ex coherence_view_helpers.ex)
      |> assert_file_list(@all_views, "views/coherence/" |> web_path)

      ~w(layout session password invitation unlock email)
      |> assert_dirs(@all_template_dirs, "templates/coherence/" |> web_path)
    end
  end

  test "does not generate files for full" do
    in_tmp "does_not_generate_files_for_full", fn ->
      mk_web_path()
      ~w(--repo=TestCoherence.Repo  --full --log-only --no-migrations --no-boilerplate)
      |> Mix.Tasks.Coherence.Install.run

      ~w()
      |> assert_file_list(@all_views, "views/coherence/" |> web_path)

      ~w()
      |> assert_dirs(@all_template_dirs, "templates/coherence/" |> web_path)
    end
  end

  describe "generates migrations" do
    test "for_default_model" do
      in_tmp "for_default_model", fn ->
        mk_web_path()
        path = "migrations"
        (~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --log-only --no-views --no-templates --module=TestCoherence --migration-path=#{path}))
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_add_coherence_to_user.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.AddCoherenceToUser do"
          assert file =~ "alter table(:users) do"
          assert file =~ "add :password_hash, :string"
          assert file =~ "add :reset_password_token, :string"
          assert file =~ "add :reset_password_sent_at, :utc_datetime"
        end
      end
    end
    test "for_new_model" do
      in_tmp "for_new_model", fn ->
        mk_web_path()
        path = "migrations"
        (~w(--repo=TestCoherence.Repo  --authenticatable --recoverable --log-only --no-views --no-templates --module=TestCoherence --migration-path=#{path}) ++ ["--model=Client clients"])
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*create_coherence_client.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.CreateCoherenceClient do"
          assert file =~ "create table(:clients) do"
          assert file =~ "add :name, :string"
          assert file =~ "add :email, :string"
          assert file =~ "add :password_hash, :string"
          assert file =~ "add :reset_password_token, :string"
          assert file =~ "add :reset_password_sent_at, :utc_datetime"
          assert file =~ "create unique_index(:clients, [:email])"
          assert file =~ "timestamps()"
        end
      end
    end
    test "for_custom_model" do
      in_tmp "for_custom_model", fn ->
        mk_web_path()
        path = "migrations"
        (~w(--repo=TestCoherence.Repo  --full --log-only --no-views --no-templates --module=TestCoherence --migration-path=#{path}) ++ ["--model=Account accounts"])
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_add_coherence_to_account.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.AddCoherenceToAccount do"
          assert file =~ "alter table(:accounts) do"
          assert file =~ "add :password_hash, :string"
          assert file =~ "add :reset_password_token, :string"
          assert file =~ "add :reset_password_sent_at, :utc_datetime"
          assert file =~ "add :failed_attempts, :integer, default: 0"
          assert file =~ "add :unlock_token, :string"
          assert file =~ "add :locked_at, :utc_datetime"
          assert file =~ "add :sign_in_count, :integer, default: 0"
          assert file =~ "add :current_sign_in_at, :utc_datetime"
          assert file =~ "add :last_sign_in_at, :utc_datetime"
          assert file =~ "add :current_sign_in_ip, :string"
          assert file =~ "add :last_sign_in_ip, :string"
        end
      end
    end
    test "for_invitible" do
      in_tmp "for_invitible", fn ->
        mk_web_path()
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
    test "for_rememberable" do
      in_tmp "for_rememberable", fn ->
        mk_web_path()
        (~w(--repo=TestCoherence.Repo  --authenticatable --rememberable --log-only --no-views --no-templates --migration-path=migrations))
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_create_coherence_rememberable.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.CreateCoherenceRememberable do"

          assert file =~ "create table(:rememberables) do"
          assert file =~ "add :series_hash, :string"
          assert file =~ "add :token_hash, :string"
          assert file =~ "add :token_created_at, :utc_datetime"
          assert file =~ "add :user_id, references(:users, on_delete: :delete_all)"
          assert file =~ "timestamps"
          assert file =~ "create index(:rememberables, [:user_id])"
          assert file =~ "create index(:rememberables, [:series_hash])"
          assert file =~ "create index(:rememberables, [:token_hash])"
          assert file =~ "create unique_index(:rememberables, [:user_id, :series_hash, :token_hash])"
        end
      end
    end
    test "for_trackable_table" do
      in_tmp "for_trackable_table", fn ->
        mk_web_path()
        (~w(--repo=TestCoherence.Repo  --authenticatable --trackable-table --log-only --no-views --no-templates --migration-path=migrations))
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_create_coherence_trackable.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.CreateCoherenceTrackable do"
          assert file =~ "create table(:trackables) do"
          assert file =~ "add :action, :string"
          assert file =~ "add :sign_in_count, :integer, default: 0"
          assert file =~ "add :current_sign_in_at, :utc_datetime"
          assert file =~ "add :last_sign_in_at, :utc_datetime"
          assert file =~ "add :current_sign_in_ip, :string"
          assert file =~ "add :last_sign_in_ip, :string"
          assert file =~ "add :user_id, references(:users, on_delete: :delete_all)"
          assert file =~ "timestamps"
          assert file =~ "create index(:trackables, [:user_id])"
          assert file =~ "create index(:trackables, [:action])"
        end
      end
    end
    test "for_rememberable_with_accounts_schema" do
      in_tmp "for_rememberable", fn ->
        mk_web_path()
        (~w(--repo=TestCoherence.Repo  --authenticatable --rememberable --log-only --no-views --no-templates --migration-path=migrations)++ ["--model=Account accounts"])
        |> Mix.Tasks.Coherence.Install.run

        assert [migration] = Path.wildcard("migrations/*_create_coherence_rememberable.exs")

        assert_file migration, fn file ->
          assert file =~ "defmodule TestCoherence.Repo.Migrations.CreateCoherenceRememberable do"

          assert file =~ "create table(:rememberables) do"
          assert file =~ "add :series_hash, :string"
          assert file =~ "add :token_hash, :string"
          assert file =~ "add :token_created_at, :utc_datetime"
          assert file =~ "add :user_id, references(:accounts, on_delete: :delete_all)"
          assert file =~ "timestamps"
          assert file =~ "create index(:rememberables, [:user_id])"
          assert file =~ "create index(:rememberables, [:series_hash])"
          assert file =~ "create index(:rememberables, [:token_hash])"
          assert file =~ "create unique_index(:rememberables, [:user_id, :series_hash, :token_hash])"
        end
      end
    end
  end
  describe "model gen" do
    test "does not generate for existing model" do
      in_tmp "does_not_generate_for_existing_model", fn ->
        mk_web_path()
        (~w(--repo=TestCoherence.Repo  --authenticatable --log-only --no-views --no-templates --module=TestCoherence --no-migrations))
        |> Mix.Tasks.Coherence.Install.run

        refute_file "models/user.ex" |> web_path
      end
    end

    test "for default model" do
      in_tmp "for_default_model", fn ->
        mk_web_path()
        (~w(--repo=TestCoherence.Repo  --authenticatable --log-only --no-views --no-templates --no-migrations))
        |> Mix.Tasks.Coherence.Install.run

        assert_file "models/coherence/user.ex" |> web_path, fn file ->
          file =~ "defmodule Coherence.User do"
          file =~ "use Coherence.Web, :model"
          file =~ "use Coherence.Schema"
          file =~ ~s(schema "users" do)
          file =~ "field :name, :string"
          file =~ "field :email, :string"
          file =~ "coherence_schema"
          file =~ "timestamps"
          file =~ "cast(params, [:name, :email] ++ coherence_fields)"
          file =~ "validate_required([:name, :email])"
          file =~ "unique_constraint(:email)"
          file =~ "validate_coherence(params)"
        end
      end

    end

    test "for custom model" do
      in_tmp "for_custom_model", fn ->
        mk_web_path()
        (~w(--repo=TestCoherence.Repo  --authenticatable --log-only --no-views --no-templates --module=TestCoherence --no-migrations) ++ ["--model=Client clients"])
        |> Mix.Tasks.Coherence.Install.run

        assert_file "models/coherence/client.ex" |> web_path, fn file ->
          file =~ "defmodule TestCoherence.Client do"
          file =~ "use TestCoherence.Web, :model"
          file =~ "use Coherence.Schema"
          file =~ ~s(schema "clients" do)
          file =~ "field :name, :string"
          file =~ "field :email, :string"
          file =~ "coherence_schema"
          file =~ "timestamps"
          file =~ "cast(params, [:name, :email] ++ coherence_fields)"
          file =~ "validate_required([:name, :email])"
          file =~ "unique_constraint(:email)"
          file =~ "validate_coherence(params)"
        end
      end
    end

  end

  describe "installed options" do
    test "install options default" do
      in_tmp "install options default", fn ->
        mk_web_path()
        Application.put_env :coherence, :opts, [:authenticatable]
        ~w(--installed-options --repo=TestCoherence.Repo)
        |>  Mix.Tasks.Coherence.Install.run

        assert_received {:mix_shell, :info, [output]}
        assert output == "mix coherence.install --authenticatable"
      end
    end

    test "install options authenticatable recoverable" do
      in_tmp "install options authenticatable recoverable", fn ->
        mk_web_path()
        Application.put_env :coherence, :opts, [:authenticatable, :recoverable]
        ~w(--installed-options --repo=TestCoherence.Repo)
        |>  Mix.Tasks.Coherence.Install.run

        assert_received {:mix_shell, :info, [output]}
        assert output == "mix coherence.install --authenticatable --recoverable"
      end
    end
    test "install options many" do
      in_tmp "install options many", fn ->
        mk_web_path()
        Application.put_env :coherence, :opts, [:confirmable, :rememberable, :registerable, :invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token]
        ~w(--installed-options --repo=TestCoherence.Repo)
        |>  Mix.Tasks.Coherence.Install.run

        assert_received {:mix_shell, :info, [output]}
        assert output == "mix coherence.install --confirmable --rememberable --registerable --invitable --authenticatable --recoverable --lockable --trackable --unlockable-with-token"
      end
    end
  end

  def assert_dirs(dirs, full_dirs, path) do
    Enum.each dirs, fn dir ->
      assert File.dir? Path.join(path, dir)
    end
    Enum.each full_dirs -- dirs, fn dir ->
      refute File.dir? Path.join(path, dir)
    end
  end

  def assert_file_list(files, full_files, path) do
    Enum.each files, fn file ->
      assert_file Path.join(path, file)
    end
    Enum.each full_files -- files, fn file ->
      refute_file Path.join(path, file)
    end
  end

  def web_path(path \\ "") do
    Path.join @web_path, path
  end
  def mk_web_path(), do: File.mkdir_p(web_path())
end
