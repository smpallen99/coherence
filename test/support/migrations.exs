defmodule TestCoherence.Migrations do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :name, :string
      # authenticatable
      add :encrypted_password, :string
      # recoverable
      add :reset_password_token, :string
      add :reset_password_sent_at, :datetime
      # lockable
      add :failed_attempts, :integer, default: 0
      add :unlock_token, :string
      add :locked_at, :datetime
      # trackable
      add :sign_in_count, :integer, default: 0
      add :current_sign_in_at, :datetime
      add :last_sign_in_at, :datetime
      add :current_sign_in_ip, :string
      add :last_sign_in_ip, :string
      timestamps
    end
    create unique_index(:users, [:email])
  end
end
