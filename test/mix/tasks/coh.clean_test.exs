Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.Coh.CleanTest do
  use ExUnit.Case
  import MixHelper

  alias Mix.Tasks.Coh.Install, as: CohInstall
  alias Mix.Tasks.Coh.Gen.Controllers, as: CohControllers
  alias Mix.Tasks.Coherence.Install
  alias Mix.Tasks.Coherence.Gen.Controllers
  alias Mix.Tasks.Coh.Clean

  @default_args ~w(--repo=TestCoherence.Repo --module="TestCoherence" --log-only)

  describe "coh" do
    test "cleans all" do
      in_tmp "coh_cleans_all", fn ->
        mk_web_path()
        mk_config_exs()

        CohInstall.run install_args(~w(--full))
        Clean.run ~w(--no-confirm --all)
        Enum.each coherence_web_items(), fn path ->
          refute File.exists?(path)
        end

        assert_coherence_config()
      end
    end

    test "cleans all with controllers" do
      in_tmp "coh_cleans_all_with_controllers", fn ->
        mk_web_path()
        mk_config_exs()

        CohInstall.run install_args(~w(--full))
        CohControllers.run ~w(--no-confirm)
        assert_file web_path(:coh, "controllers/coherence/session_controller.ex")

        Clean.run ~w(--no-confirm --all)
        Enum.each coherence_web_items(), fn path ->
          refute File.exists?(path)
        end
      end
    end
  end

  describe "coherence" do
    test "coherence cleans all" do
      in_tmp "coherence_cleans_all", fn ->
        mk_web_path(:coherence)
        mk_config_exs()

        Install.run install_args(~w(--full))
        Clean.run ~w(--no-confirm --all)
        Enum.each coherence_web_items(:coherence), fn path ->
          refute File.exists?(path)
        end

        assert_coherence_config()
      end
    end

    test "coherence cleans all with controllers" do
      in_tmp "coherence_cleans_all_with_controllers", fn ->
        mk_web_path(:coherence)
        mk_config_exs()

        Install.run install_args(~w(--full))
        Controllers.run ~w(--no-confirm)
        assert_file web_path(:coherence, "controllers/coherence/session_controller.ex")

        Clean.run ~w(--no-confirm --all)
        Enum.each coherence_web_items(:coherence), fn path ->
          refute File.exists?(path)
        end
      end
    end
  end

  defp assert_coherence_config do
    assert_file "config/config.exs", fn file ->
      refute file =~ "%% Coherence Configuration %%"
      refute file =~ "config :coherence,"
      refute file =~ "%% End Coherence Configuration %%"
    end
  end

  defp coherence_web_folders(which),
    do: ~w(controllers emails templates views) |>
      Enum.map(& web_path(which, [&1, "coherence"]))

  defp coherence_web_files(which),
    do: ~w(coherence_messages.ex coherence_web.ex) |>
      Enum.map(& web_path(which, &1))

  defp coherence_web_items(which \\ :coh),
    do: coherence_web_files(which) ++ coherence_web_folders(which)

  @web_path [coh: "lib/coherence_web", coherence: "web"]

  defp web_path(which, paths) when is_list(paths), do: Path.join([@web_path[which] | paths])
  defp web_path(which, path), do: Path.join(@web_path[which], path)
  # defp web_path(which), do: @web_path[which]

  defp mk_web_path, do: mk_web_path(@web_path[:coh])
  defp mk_web_path(:coherence), do: mk_web_path(@web_path[:coherence])
  defp mk_web_path(path), do: File.mkdir_p!(path)

  defp mk_config_exs do
    File.mkdir! "config"
    File.touch! "config/config.exs"
  end

  defp install_args(args) do
    args ++ @default_args
  end
end
