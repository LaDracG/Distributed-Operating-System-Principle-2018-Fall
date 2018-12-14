defmodule Hello.Repo.Migrations.CreateTransaction do
  use Ecto.Migration

  def change do
    create table(:transaction) do
      add :sender, :string
      add :receiver, :string
      add :amount, :float

      timestamps()
    end

  end
end
