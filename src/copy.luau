local copy
do
	function copy(t)
		if type(t) ~= "table" then
			return t
		end

		local copied = {}

		for k, v in pairs(t) do
			copied[k] = copy(v)
		end

		return copied
	end
end

return copy
