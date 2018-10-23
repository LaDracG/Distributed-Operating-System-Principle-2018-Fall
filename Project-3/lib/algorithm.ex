defmodule Algorithm do
	"""
	def getSuccesor(ids) do
		pid = Enum.at(ids, 1)
		Enum.at(GenServer.call(pid, :getSucc), 0)
	end
	"""

	def logicLarger(id_a, id_b, cid, num_nodes) do
		l_id_a = if id_a < cid do
					id_a + num_nodes
				else
					id_a
				end
		l_id_b = if id_b < cid do
					id_b + num_nodes
				else
					id_b
				end
		if l_id_a >= l_id_b do
			True
		else
			False
		end
	end

	#tid: target id; cid: current node's id
	def routingRequests(tid, cid, cid_succ_withPid, finger_table) do
		num_nodes = :math.pow(2, length(finger_table))
		
		"""
		############
		for i <- 0..length(finger_table) - 1 do
			tmp_id = Enum.at(Enum.at(finger_table, i), 0)
			if tmp_id == getSuccesor(ids) do
				{:found, Enum.at(finger_table, i)}
			else
				if logicLarger(tmp_id, tid, cid, num_nodes) do
					{:not_found, Enum.at(finger_table, i - 1)}
				else
					if i == length(finger_table) - 1 do
						{:not_found, Enum.at(finger_table, i)}
					end
				end
			end
		end
		############
		"""

		cid_succ = Enum.at(cid_succ_withPid, 0)
		if logicLarger(cid_succ, tid, cid, num_nodes) and logicLarger(tid, cid, cid, num_nodes) do
			{:found, cid_succ_withPid}
		else
			for i <- (length(finger_table) - 1)..0 do
				tmp_id = Enum.at(Enum.at(finger_table, i), 0)
				if logicLarger(tid, tmp_id, cid, num_nodes) do
					{:not_found, Enum.at(finger_table, i)}
				end
			end
		end
	end

	def join(ids) do
		pid = Enum.at(ids, 1)
		pred = GenServer.call(pid, :getPred)
		pred_pid = Enum.at(pred, 1)
		GenServer.cast(pred_pid, {:updateSucc, ids})
		succ = GenServer.call(pid, :getSucc)
		succ_pid = Enum.at(succ, 1)
		GenServer.cast(succ_pid, {:updatePred, ids})
	end
end