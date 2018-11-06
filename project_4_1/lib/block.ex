defmodule Block do
  defstruct header: nil, num_trans: 0, trans: []
end

defmodule Block.Header do
  defstruct prev_hash: "", merkle_root: "", timestamp: "", diff_target: nil, nonce: nil
end
