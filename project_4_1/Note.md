1. Check if an output is spent:

   ​	When generating the outputs of transactions, we will maintain a map for each input's previous transaction hash and output_index. When we check an output, just check if this output satisfies any record in that map. If no, this output has not been spent.