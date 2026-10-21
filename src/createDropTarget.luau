--!strict
local importRoact = require(script.Parent.importRoact)
local Types = require(script.Parent.types)
local Roact = importRoact() :: Types.Roact
local Type = importRoact("Type") :: Types.RoactType
local DragDropContext = require(script.Parent.DragDropContext)

local storeKey = require(script.Parent.storeKey)
local elementKind = require(script.Parent.elementKind)
local utility = require(script.Parent.utility)
local equal = utility.equal
local join = require(script.Parent.join)

-- type DragTargetProps = {
-- 	DropIds: { string },
-- 	TargetDropped: (targetData: unknown) -> (),
-- 	CanDrop: ((targetData: unknown) -> boolean)?,
-- 	TargetHover: ((targetData: unknown, component: Instance) -> boolean)?,
-- 	TargetPriority: number?,
-- }

type DropTargetProps = Types.DropTargetProps

type DropTargetState = {
	computedProps: DropTargetProps,
}

type DropTargetComponent = {
	init: (self: DropTargetComponent, props: DropTargetProps) -> (),
	didUpdate: (self: DropTargetComponent, prevProps: DropTargetProps) -> (),
	didMount: (self: DropTargetComponent) -> (),
	willUnmount: (self: DropTargetComponent) -> (),
	render: (self: DropTargetComponent) -> Types.RoactElement?,

	props: DropTargetProps,
	state: DropTargetState,
	setState: (self: DropTargetComponent, state: any) -> (),

	computeProps: (self: DropTargetComponent) -> DropTargetProps,

	_binding: Types.RoactBinding<GuiObject>,
	_alive: boolean,
	_bindingUpdate: Types.RoactBindingFunction<GuiObject>,

	__getContext: (self: DropTargetComponent, key: unknown) -> unknown,
}

type DragTargetComputedProps = DropTargetProps & { [string]: unknown }
local function createDropTarget(innerComponent: Types.RoactAnyComponent<unknown>, defaults: DragTargetComputedProps)
	local componentName = ("DropTarget(%s)"):format(tostring(innerComponent))
	local Connection = Roact.Component:extend(componentName) :: DropTargetComponent

	local keys = { "DropIds", "TargetDropped", "TargetPriority", "CanDrop", "TargetHover" }

	function Connection:computeProps()
		local computedProps = table.clone(defaults)
		for key: string | Types.Symbol, value in pairs(self.props) do
			if not table.find(keys, key :: string) then

				if Type.of(key) == Type.HostEvent then
					computedProps[key] = value
				elseif Type.of(key) == Type.HostChangeEvent then
					computedProps[key] = value
				elseif key == Roact.Ref then
					computedProps[key] = value
				elseif key == Roact.Children then
					computedProps[key] = value
				else
					computedProps[key] = value
				end
			end
		end

		if self.props.ForwardProps then
			for key, value in self.props.ForwardProps do
				computedProps[key] = value
			end
		end

		return computedProps
	end

	function Connection:didUpdate(prevProps)
		if not equal(prevProps, self.props) then
			self:setState({ computedProps = self:computeProps() })
		end
	end

	function Connection:init(props)
		local dropContext = self:__getContext(storeKey) :: DragDropContext.DragDropContext
		if not dropContext then
			error("A top-level DragDropProvider was not provided in the heirachy.")
		end

		if props.DropIds == nil then
			error(("%s requires a DropIds prop to be set."):format(componentName))
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
