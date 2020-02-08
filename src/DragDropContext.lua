local HttpService = game:GetService("HttpService")
local Symbol = require(script.Parent.Symbol)

local DragSources = Symbol.named("SOURCE")
local DropTargets = Symbol.named("TARGET")

local DragDropContext = {}
DragDropContext.__index = DragDropContext

function DragDropContext.new()
	local self = {
		[DragSources] = {},
		[DropTargets] = {}
	}
	return setmetatable(self, DragDropContext)
end

function DragDropContext.constructor()
	-- Prevent inheritance in roblox-ts
	error("Cannot inherit type of DragDropContext", 2);
end

local function _addSource(self, binding, props)
	local Type = DragDropContext.Type

	local dropId = props.DropId
	local data = props.TargetData
	local dragEnd = props.DragEnd
	local dragBegin = props.DragBegin

	assert(Type.of(binding) == Type.Binding, "Expected Binding")
	assert(type(dropId) == "string" or type(dropId) == "number")
	assert(data ~= nil)

	self[DragSources][binding] = {
		dropId = dropId,
		data = data,
		dragBegin = dragBegin,
		target = {},
		Id = HttpService:GenerateGUID(false),
		dragEnd = dragEnd
	}
end

local function _addTarget(self, binding, props)
	local Type = DragDropContext.Type

	local dropIds, onDrop, priority = props.DropId, props.TargetDropped, props.TargetPriority or 1
	local canDrop = props.CanDrop
	assert(Type.of(binding) == Type.Binding, "Binding Expected")
	assert(type(dropIds) == "string" or type(dropIds) == "number" or type(dropIds) == "table")
	assert(type(onDrop) == "function", ("OnDrop is of type %s, expected function"):format(typeof(onDrop)))
	assert(type(priority) == "number")

	self[DropTargets][binding] = {
		dropIds = type(dropIds) == "table" and dropIds or {dropIds},
		onDrop = onDrop,
		priority = priority,
		canDrop = canDrop,
		Id = HttpService:GenerateGUID(false)
	}
end

local function _removeTarget(self, binding)
	local Type = DragDropContext.Type

	assert(Type.of(binding) == Type.Binding)
	self[DropTargets][binding] = nil
end

local function _removeSource(self, binding)
	local Type = DragDropContext.Type
	assert(Type.of(binding) == Type.Binding)
	self[DragSources][binding] = nil
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
	return self[DragSources][binding], binding:getValue()
end

function DragDropContext:GetTargetsByDropId(dropId)
	local targets = {}

	for binding, target in next, self[DropTargets] do
		if contains(target.dropIds, dropId) then
			table.insert(targets, {Binding = binding, Target = target, OnDrop = target.onDrop, Priority = target.priority})
		end
	end

	table.sort(
		targets,
		function(a, b)
			return a.Priority > b.Priority
		end
	)

	return targets
end

function DragDropContext:dispatch(action)
	print("DragDropContext::dispatch", action.type)
	local Type = DragDropContext.Type

	-- Thunk-like dispatch
	if type(action) == "function" then
		coroutine.wrap(action)(
			function(...)
				self:dispatch(...)
			end
		)
	end

	if type(action) ~= "table" then
		error("Invalid dispatch params")
	end

	if type(action.type) ~= "string" then
		error("action.type must be a string!")
	end

	local dragSources = self[DragSources]
	local dropTargets = self[DropTargets]

	if action.type == "DROP/TARGET" then
		assert(type(action.dropId) == "string")
		assert(type(action.data) ~= "nil")
		assert(Type.of(action.source) == Type.Binding)
		assert(Type.of(action.target) == Type.Binding)
		-- local source = assert(dragSources[action.source])
		local target = assert(dropTargets[action.target])

		local canDrop = true
		if type(target.canDrop) == "function" then
			canDrop = target.canDrop()
		end

		if canDrop then
			local gui = action.source:getValue()
			-- Run callback TargetDropped on the user side
			target.onDrop(action.data, gui)
		end
	elseif action.type == "DRAG/BEGIN" then
		assert(Type.of(action.source) == Type.Binding)
		local source = assert(dragSources[action.source])

		if type(source.dragBegin) == "function" then
			source.dragBegin()
		end
	elseif action.type == "DRAG/END" then
		assert(Type.of(action.source) == Type.Binding)
		assert(type(action.dropped) == "boolean")
		local dropped = action.dropped
		local source = assert(dragSources[action.source])

		if type(source.dragEnd) == "function" then
			source.dragEnd(dropped)
		end
	elseif action.type == "REGISTRY/ADD_SOURCE" then
		assert(Type.of(action.source) == Type.Binding)
		assert(type(action.props) == "table")

		_addSource(self, action.source, action.props)
	elseif action.type == "REGISTRY/ADD_TARGET" then
		assert(Type.of(action.target) == Type.Binding)
		assert(type(action.props) == "table")

		_addTarget(self, action.target, action.props)
	elseif action.type == "REGISTRY/REMOVE_TARGET" then
		assert(Type.of(action.target) == Type.Binding)
		_removeTarget(self, action.target)
	elseif action.type == "REGISTRY/REMOVE_SOURCE" then
		assert(Type.of(action.source) == Type.Binding)
		_removeSource(self, action.source)
	else
		warn("Unknown action " .. tostring(action.type))
	end
end

DragDropContext.Default = DragDropContext.new()

return DragDropContext
