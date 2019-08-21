local DragDropContext = {}
DragDropContext.__index = DragDropContext

function DragDropContext.new()
	local self = {
		_dragSources = {},
		_dropTargets = {}
	}
	return setmetatable(self, DragDropContext)
end

function DragDropContext:AddSource(binding, dropId, data)
	local Type = DragDropContext.Type

	assert(Type.of(binding) == Type.Binding, "Expected Binding")
	assert(type(dropId) == "string" or type(dropId) == "number")
	assert(data ~= nil)

	self._dragSources[binding] = {dropId = dropId, data = data, target = {}}
end

function DragDropContext:AddTarget(binding, props)
	local Type = DragDropContext.Type

	local dropIds, onDrop, priority = props.DropId, props.TargetDropped, props.TargetPriority or 1
	local canDrop = props.CanDrop
	assert(Type.of(binding) == Type.Binding, "Binding Expected")
	assert(type(dropIds) == "string" or type(dropIds) == "number")
	assert(type(onDrop) == "function", ("OnDrop is of type %s, expected function"):format(typeof(onDrop)))
	assert(type(priority) == "number")

	if type(dropIds) == "table" then
		self._dropTargets[binding] = {dropIds = dropIds, onDrop = onDrop, priority = priority, canDrop = canDrop}
	else
		self._dropTargets[binding] = {dropIds = {dropIds}, onDrop = onDrop, priority = priority, canDrop = canDrop}
	end
end

function DragDropContext:RemoveTarget(binding)
	local Type = DragDropContext.Type

	assert(Type.of(binding) == Type.Binding)
	self._dropTargets[binding] = nil
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

function DragDropContext:GetSource(binding)
	return self._dragSources[binding], binding:getValue()
end

function DragDropContext:GetTargetsByDropId(dropId)
	local targets = {}

	-- table.sort(
	-- 	self._dropTargets,
	-- 	function(a, b)
	-- 		return a.priority > b.priority
	-- 	end
	-- )

	for binding, target in next, self._dropTargets do
		if contains(target.dropIds, dropId) then
			table.insert(targets, {Binding = binding, Target = target, OnDrop = target.onDrop})
		end
	end
	return targets
end

DragDropContext.Default = DragDropContext.new()

return DragDropContext
