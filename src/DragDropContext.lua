local DragDropContext = {}
DragDropContext.__index = DragDropContext

function DragDropContext.new()
	local self = {
		_dragSources = {},
		_dropTargets = {}
	}
	return setmetatable(self, DragDropContext)
end

function DragDropContext:AddSource(src, dropId, data)
	assert(typeof(src) == "Instance" and src:IsA("GuiObject"))
	assert(typeof(dropId) == "string" or typeof(dropId) == "number")
	assert(data ~= nil)

	self._dragSources[src] = {dropId = dropId, data = data}
end

function DragDropContext:AddTarget(src, dropIds, onDrop)
	assert(typeof(src) == "Instance" and src:IsA("GuiObject"))
	assert(typeof(dropId) == "string" or typeof(dropId) == "number")
	assert(typeof(onDrop) == "function", ("OnDrop is of type %s, expected function"):format(typeof(onDrop)))

	if type(dropId) == "table" then
		self._dropTargets[src] = {dropIds = dropIds, onDrop = onDrop}
	else
		self._dropTargets[src] = {dropIds = {dropIds}, onDrop = onDrop}
	end
end

function DragDropContext:RemoveTarget(src)
	assert(typeof(src) == "Instance")
	self._dropTargets[src] = nil
end

function DragDropContext:RemoveSource(src)
	assert(typeof(src) == "Instance")
	self._dragSources[src] = nil
end

local function contains(tbl, value)
	for _, val in next, tbl do
		if val == value then
			return true
		end
	end

	return false
end

function DragDropContext:GetTargetsByDropId(dropId)
	local targets = {}
	for instance, target in next, self._dropTargets do
		if contains(target.dropId, dropId) then
			table.insert(targets, {Instance = instance, Target = target})
		end
	end
	return targets
end

DragDropContext.Default = DragDropContext.new()

return DragDropContext
