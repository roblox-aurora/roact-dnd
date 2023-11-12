--!strict
local importRoact = require(script.Parent.importRoact)
local Types = require(script.Parent.types)
local Roact = importRoact() :: Types.Roact
local DragDropContext = require(script.Parent.DragDropContext)

local storeKey = require(script.Parent.storeKey)
local elementKind = require(script.Parent.elementKind)
local join = require(script.Parent.join)

type DragTargetProps = {
	DropId: string,
	TargetDropped: (targetData: unknown) -> (),
	CanDrop: ((targetData: unknown) -> boolean)?,
	TargetHover: ((targetData: unknown, component: Instance) -> boolean)?,
	TargetPriority: number?,
}

type DragTargetState = {
	computedProps: DragTargetProps,
}

type DropTargetComponent = {
	init: (self: DropTargetComponent, props: DragTargetProps) -> (),
	didUpdate: (self: DropTargetComponent, prevProps: DragTargetProps) -> (),
	didMount: (self: DropTargetComponent) -> (),
	willUnmount: (self: DropTargetComponent) -> (),
	_context: { [string]: unknown },
	render: (self: DropTargetComponent) -> Types.RoactElement?,

	props: DragTargetProps,
	state: DragTargetState,

	computeProps: (self: DropTargetComponent) -> DragTargetProps,

	_binding: Types.RoactBinding<GuiObject>,
	_alive: boolean,
	_bindingUpdate: Types.RoactBindingFunction<GuiObject>,

	__getContext: (self: DropTargetComponent, key: unknown) -> unknown,
}

type DragTargetComputedProps = DragTargetProps & { [string]: unknown }
local function createDropTarget(innerComponent: Types.RoactAnyComponent<unknown>, defaults: DragTargetComputedProps)
	local componentName = ("DropTarget(%s)"):format(tostring(innerComponent))
	local Connection = Roact.PureComponent:extend(componentName) :: DropTargetComponent

	function Connection:computeProps()
		local computedProps = table.clone(defaults)
		for key, value in pairs(self.props) do
			if
				key ~= "DropId"
				and key ~= "TargetDropped"
				and key ~= "TargetPriority"
				and key ~= "CanDrop"
				and key ~= "TargetHover"
			then
				computedProps[key] = value
			end
		end
		return computedProps
	end

	function Connection:init(props)
		local dropContext = self:__getContext(storeKey) :: DragDropContext.DragDropContext
		if not dropContext then
			error("A top-level DragDropProvider was not provided in the heirachy.")
		end

		if props.DropId == nil then
			error(("%s requires a DropId prop to be set."):format(componentName))
		end

		if type(props.TargetDropped) ~= "function" then
			error(("%s requires a TargetDropped callback prop to be set."):format(componentName))
		end

		self.state = {
			computedProps = self:computeProps(),
		}

		local binding, bindingUpdate = Roact.createBinding(nil :: GuiObject?)
		self._bindingUpdate = bindingUpdate
		self._binding = binding
	end

	function Connection:willUnmount()
		local context = self:__getContext(storeKey) :: DragDropContext.DragDropContext
		context:dispatch({ type = "REGISTRY/REMOVE_TARGET", target = self._binding })

		self._bindingUpdate(nil)
	end

	function Connection:didMount()
		local context = self:__getContext(storeKey) :: DragDropContext.DragDropContext
		context:dispatch({ type = "REGISTRY/ADD_TARGET", target = self._binding, props = self.props })
	end

	function Connection:render()
		if elementKind(innerComponent) == "host" then
			local ref = self.props[Roact.Ref]
			local function refFn(rbx)
				self._bindingUpdate(rbx)

				if ref then
					if type(ref) == "function" then
						ref(rbx)
					else
						warn("Cannot use Roact.Ref with DragSource")
					end
				end
			end

			return Roact.createElement(
				innerComponent,
				join(self.state.computedProps, {
					[Roact.Ref] = refFn,
					[Roact.Children] = self.props[Roact.Children],
				})
			)
		else
			return nil
		end
	end

	return Connection
end

return createDropTarget
