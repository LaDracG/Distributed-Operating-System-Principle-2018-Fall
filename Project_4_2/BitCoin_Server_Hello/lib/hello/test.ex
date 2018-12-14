defmodule Hello.Test do
	use Ecto.Schema
	import Ecto.Changeset

	schema "test" do
		field :pid, :string
		field :amount, :float

		timestamps()
	end

  @doc false
  def changeset(hello, attrs) do
    hello
    |> cast(attrs, [:pid, :amount])
    |> validate_required([:pid, :amount])
  end
end