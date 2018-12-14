defmodule Hello.Transaction do
	use Ecto.Schema

	schema "transaction" do
		field :sender, :string
		field :receiver, :string
		field :amount, :float

		timestamps()
	end
end