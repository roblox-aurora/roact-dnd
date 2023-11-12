--!strict
local HttpService = game:GetService("HttpService")
local Types = require(script.Parent.types)

export type Target = {
	Binding: Types.RoactDnDBinding,
	Target: DropTarget,
	OnDrop: ((unknown, GuiObject?) -> ())?,
	Priority: number,
}

type BindingTarget = Types.RoactDnDBinding
type BindingSourceProps = Types.BindingSourceProps

export type DragDropImpl = {
	__index: DragDropImpl,

	new: () -> DragDropContext,

	GetSource: (self: DragDropContext, binding: Types.RoactDnDBinding) -> (DragSource, GuiObject?),
	GetTargetsByDropId: (self: DragDropContext, dropId: string) -> { Target },
	dispatch: (self: DragDropContext, action: Types.DragDropContextActions) -> (),

	-- roblox-ts thingy
	constructor: () -> (),

	Type: Types.RoactType,
	Default: DragDropContext,
}
export type DragDropProto = {
	dragSources: { [Types.RoactDnDBinding]: DragSource },
	dropTargets: { [Types.RoactDnDBinding]: DropTarget },
}
export type DragDropContext = typeof(setmetatable({} :: DragDropProto, {} :: DragDropImpl))

type DragSource = {
	dropId: string,
	data: unknown,
	dragBegin: (() -> ())?,
	target: unknown,
	Id: string,
	dragEnd: ((hasDropTarget: boolean) -> ())?,
}

type DropTarget = {
	dropIds: { string } | string,
	onDrop: ((unknown, GuiObject?) -> ())?,
	priority: number?,
	canDrop: ((targetData: unknown) -> boolean)?,
	Id: string,
}

local DragDropContext = {} :: DragDropImpl
DragDropContext.__index = DragDropContext

function DragDropContext.new()
	local self: DragDropProto = {
		dragSources = {},
		dropTargets = {},
	}
	return setmetatable(self, DragDropContext)
end

function DragDropContext.constructor()
	-- Prevent inheritance in roblox-ts
	error("Cannot inherit type of DragDropContext", 2)
end

local function _addSource(self: DragDropContext, binding: Types.RoactDnDBinding, props: Types.DragSourceProps)
	local Type = DragDropContext.Type :: Types.RoactType

	local dropId = props.DropId
	local data = props.TargetData
	local dragEnd = props.DragEnd
	local dragBegin = props.DragBegin

	assert(Type.of(binding) == Type.Binding, "Expected Binding")
	assert(type(dropId) == "string" or type(dropId) == "number")
	assert(data ~= nil)

	self.dragSources[binding] = {
		dropId = dropId,
		data = data,
		dragBegin = dragBegin,
		target = {},
		Id = HttpService:GenerateGUID(false),
		dragEnd = dragEnd,
	}
end

local function _addTarget(self: DragDropContext, binding: Types.RoactDnDBinding, props: Types.DropTargetProps)
	local Type = DragDropContext.Type :: Types.RoactType

	local dropIds, onDrop, priority = props.DropId, props.TargetDropped, props.TargetPriority or 1
	local canDrop = props.CanDrop
	assert(Type.of(binding) == Type.Binding, "Binding Expected")
	assert(type(dropIds) == "string" or type(dropIds) == "number" or type(dropIds) == "table")
	assert(type(onDrop) == "function", ("OnDrop is of type %s, expected function"):format(typeof(onDrop)))
	assert(type(priority) == "number")

	self.dropTargets[binding] = {
		dropIds = type(dropIds) == "table" and dropIds or { dropIds },
		onDrop = onDrop,
		priority = priority,
		canDrop = canDrop,
		Id = HttpService:GenerateGUID(false),
	}
end

local function _removeTarget(self: DragDropContext, binding: Types.RoactDnDBinding)
	local Type = DragDropContext.Type :: Types.RoactType

	assert(Type.of(binding) == Type.Binding)
	self.dropTargets[binding] = nil
end

local function _removeSource(self: DragDropContext, binding: Types.RoactDnDBinding)
	local Type = DragDropContext.Type :: Types.RoactType
	assert(Type.of(binding) == Type.Binding)
	self.dragSources[binding] = nil
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
	return self.dragSources[binding], binding:getValue()
end

function DragDropContext:GetTargetsByDropId(dropId)
	local targets: { Target } = {}

	for binding, target in self.dropTargets do
		if contains(target.dropIds, dropId) then
			table.insert(
				targets,
				{ Binding = binding, Target = target, OnDrop = target.onDrop, Priority = target.priority or 0 }
			)
		end
	end

	table.sort(targets, function(a, b)
		return a.Priority > b.Priority
	end)

	return targets
end

function DragDropContext:dispatch(action: Types.DragDropContextActions)
	print("DragDropContext::dispatch", action.type)
	local Type = DragDropContext.Type :: Types.RoactType

	if type(action) ~= "table" then
		error("Invalid dispatch params")
	end

	if type(action.type) ~= "string" then
		error("action.type must be a string!")
	end

	local dragSources = self.dragSources
	local dropTargets = self.dropTargets

	if action.type == "DROP/TARGET" then
		assert(type(action.dropId) == "string")
		assert(type(action.data) ~= "nil")
		assert(Type.of(action.source) == Type.Binding)
		assert(Type.of(action.target) == Type.Binding)

		local target = assert(dropTargets[action.target])

		local canDrop = true
		if type(target.canDrop) == "function" then
			canDrop = target.canDrop()
		end

		if canDrop then
			local gui = action.source:getValue()
			-- Run callback TargetDropped on the user side

			if target.onDrop and gui then
				target.onDrop(action.data, gui)
			end
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
