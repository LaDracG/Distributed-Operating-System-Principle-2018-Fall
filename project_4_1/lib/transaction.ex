defmodule Transaction do
  defstruct sender: "", receiver: "", num_inputs: 0, inputs: [], num_outputs: 0, outputs: [], trans_fee: 0, signature: ""
end

defmodule Transaction.Input do
  defstruct prev_trans_hash: "", prev_output_index: nil
end

defmodule Transaction.Output do
  defstruct receiver: "", value: 0, is_spent: false
end
