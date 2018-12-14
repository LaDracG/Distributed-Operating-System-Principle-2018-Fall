defmodule Hello.Repo.Migrations.CreateBalance do
  use Ecto.Migration

  def change do
    create table(:balance) do
      add :pid, :string, primary_key: true
      add :amount, :float

      timestamps()
    end

  end
end
