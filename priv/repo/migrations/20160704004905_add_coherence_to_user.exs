defmodule TestCoherence.Repo.Migrations.AddCoherenceToUser do
  use Ecto.Migration
  def change do
    alter table(:users) do
      # authenticatable
      add :encrypted_password, :string
    end

  end
end
