defmodule Hello.Balance do
	use Ecto.Schema
	import Ecto.Changeset

	@primary_key {:pid, :string, []}
	@derive {Phoenix.Param, key: :pid}
	schema "balance" do
		field :amount, :float
		timestamps()
	end

  @doc false
  def changeset(hello, attrs) do
    hello
    |> cast(attrs, [:pid, :amount])
    |> validate_required([:pid, :amount])
    |> unique_constraint(:pid, pid: :balance_pkey)
  end
end