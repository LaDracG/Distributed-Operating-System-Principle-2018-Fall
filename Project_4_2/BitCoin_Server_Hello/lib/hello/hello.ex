defmodule Hello.Hello do
  use Ecto.Schema
  import Ecto.Changeset


  schema "balance" do
    field :amount, :float
    field :pid, :string

    timestamps()
  end

  @doc false
  def changeset(hello, attrs) do
    hello
    |> cast(attrs, [:pid, :amount])
    |> validate_required([:pid, :amount])
  end
end
