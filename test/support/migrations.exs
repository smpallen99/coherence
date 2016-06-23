defmodule TestCoherence.Migrations do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :encrypted_password, :string
    end
    create unique_index(:users, [:email])
  end
end
