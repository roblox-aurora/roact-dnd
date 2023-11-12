local function pointsIntersect(instPos: Vector2, instEndPos: Vector2, intersectPos: Vector2, intersectEndPos: Vector2)
	return (
		instEndPos.X > intersectPos.X
		and instEndPos.Y > intersectPos.Y
		and instPos.X < intersectEndPos.X
		and instPos.Y < intersectEndPos.Y
	)
end

local function deepEqual(t1: any, t2: any, ignore_mt: boolean?): boolean
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then
		return false
	end
	-- non-table types can be directly compared
	if ty1 ~= "table" and ty2 ~= "table" then
		return t1 == t2
	end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then
		return t1 == t2
	end
	for k1, v1 in pairs(t1) do
		local v2 = t2[k1]
		if type(k1) ~= "userdata" and (v2 == nil or not deepEqual(v1, v2)) then
			return false
		end
	end
	for k2, v2 in pairs(t2) do
		local v1 = t1[k2]
		if type(k2) ~= "userdata" and (v1 == nil or not deepEqual(v1, v2)) then
			return false
		end
	end
	return true
end

local function equal(t1: any, t2: any, ignore_mt: boolean?): boolean
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then
		return false
	end
	-- non-table types can be directly compared
	if ty1 ~= "table" and ty2 ~= "table" then
		return t1 == t2
	end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then
		return t1 == t2
	end
	for k1, v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or v1 ~= v2 then
			return false
		end
	end
	for k2, v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or v1 ~= v2 then
			return false
		end
	end
	return true
end

return {
	pointsIntersect = pointsIntersect,
	deepEqual = deepEqual,
	equal = equal,
}
