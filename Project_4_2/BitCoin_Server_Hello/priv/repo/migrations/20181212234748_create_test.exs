defmodule Hello.Repo.Migrations.CreateTest do
  use Ecto.Migration

  def change do
    create table(:test) do
      add :pid, :string
      add :amount, :float

      timestamps()
    end

  end
end
