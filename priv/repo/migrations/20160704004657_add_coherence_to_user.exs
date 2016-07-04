defmodule TestCoherence.Repo.Migrations.AddCoherenceToUser do
  use Ecto.Migration
  def change do
    alter table(:users) do
      # recoverable
      add :reset_password_token, :string
      add :reset_password_sent_at, :datetime
      # authenticatable
      add :encrypted_password, :string
    end

  end
end
