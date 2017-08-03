Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.Coh.Gen.ControllersTest do
  use ExUnit.Case
  import MixHelper

  @lib_path Path.join("lib", "coherence")
  @web_path Path.join("lib", "coherence_web")

  setup do
    Application.put_env :coherence, :opts, [
      :confirmable, :authenticatable, :recoverable, :lockable, :trackable,
      :unlockable_with_token, :invitable, :registerable, :rememberable]
    :ok
  end
  # opts: [:invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :registerable]

  # @all_controllers ~w(session invitation password registration
  #   unlock) |> Enum.map(& Kernel.<>(&1, "_controller.ex"))

  def mk_web_path(path \\ @web_path) do
    File.mkdir_p!(path)
  end

  test "coh geneates controllers" do
    in_tmp "coh_geneates_controllers", fn ->
      mk_web_path()
      ~w()
      |> Mix.Tasks.Coh.Gen.Controllers.run

      assert_file "controllers/coherence/session_controller.ex" |> web_path, fn file ->
        assert file =~ "defmodule CoherenceWeb.Coherence.SessionController do"
      end
      assert_file "controllers/coherence/password_controller.ex" |> web_path, fn file ->
        assert file =~ "defmodule CoherenceWeb.Coherence.PasswordController do"
      end
      assert_file "controllers/coherence/invitation_controller.ex" |> web_path, fn file ->
        assert file =~ "defmodule CoherenceWeb.Coherence.InvitationController do"
      end
      assert_file "controllers/coherence/registration_controller.ex" |> web_path, fn file ->
        assert file =~ "defmodule CoherenceWeb.Coherence.RegistrationController do"
      end
      assert_file "controllers/coherence/unlock_controller.ex" |> web_path, fn file ->
        assert file =~ "defmodule CoherenceWeb.Coherence.UnlockController do"
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
  def lib_path(path \\ "") do
    Path.join @lib_path, path
  end
end
