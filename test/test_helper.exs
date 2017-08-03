ExUnit.start()
Application.ensure_all_started(:coherence)

Code.require_file "./support/gettext.exs", __DIR__
Code.require_file "./support/messages.exs", __DIR__
Code.require_file "./support/view_helpers.exs", __DIR__
Code.require_file "./support/web.exs", __DIR__
Code.require_file "./support/dummy_controller.exs", __DIR__
Code.require_file "./support/schema.exs", __DIR__
Code.require_file "./support/repo.exs", __DIR__
Code.require_file "./support/migrations.exs", __DIR__
Code.require_file "./support/router.exs", __DIR__
Code.require_file "./support/endpoint.exs", __DIR__
Code.require_file "./support/model_case.exs", __DIR__
Code.require_file "./support/conn_case.exs", __DIR__
Code.require_file "./support/views.exs", __DIR__
Code.require_file "./support/email.exs", __DIR__
Code.require_file "./support/test_helpers.exs", __DIR__
Code.require_file "./support/redirect.exs", __DIR__
Code.require_file "./support/schemas.exs", __DIR__

defmodule Coherence.RepoSetup do
  use ExUnit.CaseTemplate
end

TestCoherence.Repo.__adapter__.storage_down TestCoherence.Repo.config
TestCoherence.Repo.__adapter__.storage_up TestCoherence.Repo.config

{:ok, _pid } = TestCoherenceWeb.Endpoint.start_link
{:ok, _pid} = TestCoherence.Repo.start_link
_ = Ecto.Migrator.up(TestCoherence.Repo, 0, TestCoherence.Migrations, log: false)
Process.flag(:trap_exit, true)
Ecto.Adapters.SQL.Sandbox.mode(TestCoherence.Repo, :manual)
