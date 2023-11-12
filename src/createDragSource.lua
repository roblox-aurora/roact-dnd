--!strict
local UserInputService = game:GetService("UserInputService")
local Types = require(script.Parent.types)
local DragDropContext = require(script.Parent.DragDropContext)

local importRoact = require(script.Parent.importRoact)
local Roact = importRoact() :: Types.Roact
local Snapdragon = require(script.Parent.Packages.Snapdragon)
local createDragController = Snapdragon.createDragController

local storeKey = require(script.Parent.storeKey)
local join = require(script.Parent.join)
local elementKind = require(script.Parent.elementKind)
local utility = require(script.Parent.utility)
local equal = utility.equal
local copy = require(script.Parent.copy)

type DragSourceComponent = {
	init: (self: DragSourceComponent, props: Types.DragSourceProps) -> (),
	didUpdate: (self: DragSourceComponent, prevProps: Types.DragSourceProps) -> (),
	didMount: (self: DragSourceComponent) -> (),
	willUnmount: (self: DragSourceComponent) -> (),
	_context: { [string]: unknown },
	render: (self: DragSourceComponent) -> Types.RoactElement?,

	props: Types.DragSourceProps,
	state: DragSourceState,
	setState: (self: DragSourceComponent, state: any) -> (),

	setDraggable: (self: DragSourceComponent, dragGui: GuiObject?) -> (),
	computeProps: (self: DragSourceComponent) -> Types.DragSourceProps,

	_binding: Types.RoactBinding<GuiObject>,
	_alive: boolean,
	_bindingUpdate: Types.RoactBindingFunction<GuiObject>,
	_inputBegan: RBXScriptConnection?,
	_inputChanged: RBXScriptConnection?,
	_globalInputChanged: RBXScriptConnection?,
	_dragEvent: RBXScriptConnection?,
	_modalRbx: GuiObject?,

	dragController: Types.SnapdragonController,

	setSnapdragonDraggable: (self: DragSourceComponent, dragGui: GuiObject?) -> (),
	setLegacyDraggable: (self: DragSourceComponent, dragGui: GuiObject?) -> (),

	defaultProps: {},

	__getContext: (self: DragSourceComponent, key: unknown) -> unknown,
}

type DragSourceState = {
	computedProps: Types.DragSourceProps,
	position: UDim2,
	startPos: UDim2,
	dragStart: Vector3,
	dragging: boolean,
	size: UDim2,
	dropTargets: { DragDropContext.Target },
}

type DragSourceComputedProps = Types.DragSourceProps & { [string]: unknown }
local function createDragSource(innerComponent: Types.RoactAnyComponent<unknown>, defaults: DragSourceComputedProps)
	local componentName = ("DragSource(%s)"):format(tostring(innerComponent))
	local Connection = Roact.Component:extend(componentName) :: DragSourceComponent

	Connection.defaultProps = {
		DragController = "Legacy",
		IsDragModal = true,
	}

	function Connection:computeProps()
		local computedProps = table.clone(defaults)
		for key, value in pairs(self.props) do
			if
				key ~= "DropId"
				and key ~= "TargetData"
				and key ~= "DragConstraint"
				and key ~= "DropResetsPosition"
				and key ~= "CanDrag"
				and key ~= "DragBegin"
				and key ~= "DragEnd"
				and key ~= "IsDragModal"
				and key ~= "DragController"
			then
				computedProps[key] = value
			end
		end
		return computedProps
	end

	function Connection:init(props)
		local dropContext = self:__getContext(storeKey)
		if not dropContext then
			error("A top-level DragDropProvider was not provided in the heirachy.")
		end

		if props.DropId == nil then
			error(("%s requires a DropId prop to be set."):format(componentName))
		end

		if props.TargetData == nil then
			error(("%s requires a TargetData prop to be set."):format(componentName))
		end

		self.state = {
			computedProps = self:computeProps(),
			startPos = UDim2.new(),
			dragStart = Vector3.new(),
			dropTargets = {},
			dragging = false,
			size = UDim2.new(),
			position = UDim2.new()
		}

		local binding, updateBinding = Roact.createBinding(nil :: GuiObject?)
		self._binding = binding
		self._alive = true
		self._bindingUpdate = updateBinding
	end

	function Connection:didUpdate(prevProps)
		if prevProps.Position ~= self.props.Position then
			self:setState({ position = self.props.Position })
		end
		if not equal(prevProps, self.props) then
			self:setState({ computedProps = self:computeProps() })
		end
	end

	function Connection:setSnapdragonDraggable(dragGui)
		local gui = self._modalRbx or dragGui

		local props = self.props
		local snapBehaviour = props.DragConstraint or "None"
		local canDrag: (unknown) -> boolean = props.CanDrag or function()
			return true
		end

		local dropResetsPosition = props.DropResetsPosition
		if dropResetsPosition == nil then
			dropResetsPosition = true
		end

		local dropContext = self:__getContext(storeKey) :: DragDropContext.DragDropContext

		if self.dragController then
			warn("[roact-dnd] Overwriting existing drag controller")
			self.dragController:Destroy()
		end

		local dragController = createDragController(dragGui, {
			DragGui = gui,
			CanDrag = function()
				return canDrag(self.props.TargetData)
			end,
			Debugging = true,
			-- DragPositionMode = "Offset",
			DragEndedResetsPosition = dropResetsPosition,
			DragRelativeTo = "LayerCollector",
			SnapEnabled = snapBehaviour ~= "None",
			DragThreshold = 5,
		})

		self.dragController = dragController

		local offsetPosition
		dragController.DragBegan:Connect(function(began)
			local state = {
				dragging = true,
				dragStart = began.InputPosition,
				startPos = began.GuiPosition,
				dropTargets = dropContext:GetTargetsByDropId(self.props.DropId),
			}

			if self.props.IsDragModal then
				local absolute = began.AbsolutePosition :: Vector2
				offsetPosition = UDim2.new(0, absolute.X, 0, absolute.Y)
				state.position = offsetPosition

				-- Offset the margin, since we're using a modal
				-- respresentation of the object here, which is portaled rather than a descendant of
				-- the drag source's parent
				dragController:SetSnapMargin({
					Vertical = Vector2.new(-absolute.X, absolute.X),
					Horizontal = Vector2.new(-absolute.Y, absolute.Y),
				})
			end

			self:setState(state)
			dropContext:dispatch({ type = "DRAG/BEGIN", source = self._binding })
		end)

		dragController.DragChanged:Connect(function(changed)
			self:setState({
				position = offsetPosition and (changed.GuiPosition :: UDim2) + offsetPosition or changed.GuiPosition,
			})
		end)

		dragController.DragEnded:Connect(function(ended)
			gui = self._modalRbx or gui

			local dropped = false
			for _, target in self.state.dropTargets do
				local targetGui = target.Binding:getValue()
				if targetGui and gui then
					local targetGuiPos = targetGui.AbsolutePosition
					local sourceGuiPos = gui.AbsolutePosition
					local targetGuiSize = targetGui.AbsoluteSize
					local sourceGuiSize = gui.AbsoluteSize

					if
						utility.pointsIntersect(
							sourceGuiPos,
							sourceGuiPos + sourceGuiSize,
							targetGuiPos,
							targetGuiPos + targetGuiSize
						)
					then
						dropContext:dispatch({
							type = "DROP/TARGET",
							data = self.props.TargetData,
							dropId = self.props.DropId,
							source = self._binding,
							target = target.Binding,
						})
						dropped = true
						break
					end
				end
			end

			if self._alive then
				dropContext:dispatch({ type = "DRAG/END", source = self._binding, dropped = dropped })

				if dropResetsPosition then
					self:setState({ position = Roact.None, dragging = false })
				else
					self:setState({ dragging = false })
					local bindingGui = self._binding:getValue()
					if bindingGui then
						bindingGui.Position = self.state.position
					end
				end
			end
		end)

		dragController:Connect()
	end

	function Connection:setLegacyDraggable(dragGui)
		warn("[roact-dnd] Using the legacy drag controller")

		local props = self.props
		local snapBehaviour = props.DragConstraint or "None"
		local canDrag: (unknown) -> boolean = props.CanDrag or function()
			return true
		end

		local dropResetsPosition = props.DropResetsPosition
		if dropResetsPosition == nil then
			dropResetsPosition = true
		end

		local dropContext = self:__getContext(storeKey) :: DragDropContext.DragDropContext

		if self._inputBegan then
			self._inputBegan:Disconnect()
			self._inputBegan = nil
		end

		if self._inputChanged then
			self._inputChanged:Disconnect()
			self._inputChanged = nil
		end

		if self._globalInputChanged then
			self._globalInputChanged:Disconnect()
			self._globalInputChanged = nil
		end

		local mouseDown = false
		local reachedDraggingThreshold = false

		if dragGui then
			local dragInput

			local function update(input: InputObject, targetGui: GuiObject)
				assert(targetGui and typeof(targetGui) == "Instance" and targetGui:IsA("GuiObject"))
				local ul, br = game:GetService("GuiService"):GetGuiInset()
				local view = workspace.CurrentCamera.ViewportSize
				local startPos = self.state.startPos
					- UDim2.fromOffset(
						targetGui.AbsoluteSize.X * targetGui.AnchorPoint.X,
						targetGui.AbsoluteSize.Y * targetGui.AnchorPoint.Y
					)

				local screen = snapBehaviour == "ViewportIgnoreInset" and view or view - ul + br

				local delta = input.Position - self.state.dragStart

				if mouseDown and delta.Magnitude >= 5 and not self.state.dragging then
					self:setState({ dragging = true })
					dropContext:dispatch({ type = "DRAG/BEGIN", source = self._binding })
					reachedDraggingThreshold = true
				end

				if snapBehaviour ~= "None" then
					local scaleOffsetX = screen.X * startPos.X.Scale
					local scaleOffsetY = screen.Y * startPos.Y.Scale
					local resultingOffsetX = startPos.X.Offset + delta.X
					local resultingOffsetY = startPos.Y.Offset + delta.Y

					if (resultingOffsetX + scaleOffsetX) > screen.X - targetGui.AbsoluteSize.X then
						resultingOffsetX = screen.X - targetGui.AbsoluteSize.X - scaleOffsetX
					elseif (resultingOffsetX + scaleOffsetX) < 0 then
						resultingOffsetX = -scaleOffsetX
					end

					if (resultingOffsetY + scaleOffsetY) > screen.Y - targetGui.AbsoluteSize.Y then
						resultingOffsetY = screen.Y - targetGui.AbsoluteSize.Y - scaleOffsetY
					elseif (resultingOffsetY + scaleOffsetY) < 0 then
						resultingOffsetY = -scaleOffsetY
					end

					-- targetGui.Position =
					self:setState({
						position = UDim2.new(
							startPos.X.Scale,
							resultingOffsetX + targetGui.AbsoluteSize.X * targetGui.AnchorPoint.X,
							startPos.Y.Scale,
							resultingOffsetY + targetGui.AbsoluteSize.Y * targetGui.AnchorPoint.Y
						),
					})
				else
					-- targetGui.Position =
					-- 	UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)

					self:setState({
						position = UDim2.new(
							startPos.X.Scale,
							startPos.X.Offset + delta.X + targetGui.AbsoluteSize.X * targetGui.AnchorPoint.X,
							startPos.Y.Scale,
							startPos.Y.Offset + delta.Y + targetGui.AbsoluteSize.Y * targetGui.AnchorPoint.Y
						),
					})
				end
			end

			self._inputBegan = dragGui.InputBegan:Connect(function(input)
				if
					(
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
					) and canDrag(self.props.TargetData)
				then
					local currentGui = self._binding:getValue()
					if currentGui then
						local absSize = currentGui.AbsoluteSize
						self:setState({ size = UDim2.new(0, absSize.X, 0, absSize.Y) })
					end

					local gui = self._modalRbx or dragGui

					mouseDown = true
					self:setState({
						-- dragging = true,
						dragStart = input.Position,
						position = self.props.IsDragModal
							and UDim2.new(0, gui.AbsolutePosition.X, 0, gui.AbsolutePosition.Y),
						startPos = self.props.IsDragModal
								and UDim2.new(0, gui.AbsolutePosition.X, 0, gui.AbsolutePosition.Y)
							or gui.Position,
						dropTargets = dropContext:GetTargetsByDropId(self.props.DropId),
					})

					self._dragEvent = input.Changed:Connect(function()
						if
							input.UserInputState == Enum.UserInputState.End
							and (
								input.UserInputType == Enum.UserInputType.MouseButton1
								or input.UserInputType == Enum.UserInputType.Touch
							)
						then
							gui = self._modalRbx or gui

							if reachedDraggingThreshold then
								-- On Drop
								local dropped = false
								for _, target in self.state.dropTargets do
									local targetGui = target.Binding:getValue()
									if targetGui then
										local targetGuiPos = targetGui.AbsolutePosition
										local sourceGuiPos = gui.AbsolutePosition
										local targetGuiSize = targetGui.AbsoluteSize
										local sourceGuiSize = gui.AbsoluteSize

										if
											utility.pointsIntersect(
												sourceGuiPos,
												sourceGuiPos + sourceGuiSize,
												targetGuiPos,
												targetGuiPos + targetGuiSize
											)
										then
											-- target.OnDrop(self.props.TargetData, gui)
											dropContext:dispatch({
												type = "DROP/TARGET",
												data = self.props.TargetData,
												dropId = self.props.DropId,
												source = self._binding,
												target = target.Binding,
											})
											dropped = true
											break
										end
									end
								end

								if self._alive then
									if dropResetsPosition then
										self:setState({ position = Roact.None, dragging = false })
										mouseDown = false
									else
										self:setState({ dragging = false })
										local bindingGui = self._binding:getValue()
										if bindingGui then
											bindingGui.Position = self.state.position
										end
										mouseDown = false
									end

									dropContext:dispatch({
										type = "DRAG/END",
										source = self._binding,
										dropped = dropped,
									})

									if self._dragEvent then
										self._dragEvent:Disconnect()
									end
								end
								reachedDraggingThreshold = false
							else
								mouseDown = false
							end
						end
					end)
				end
			end)

			self._inputChanged = dragGui.InputChanged:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragInput = input
				end
			end)

			self._globalInputChanged = UserInputService.InputChanged:Connect(function(input: InputObject)
				if input == dragInput and mouseDown then
					update(input, self._modalRbx or dragGui)
				end
			end)
		else
			warn("Ref not set for " .. tostring(innerComponent))
		end
	end

	function Connection:didMount()
		local dropContext = self:__getContext(storeKey) :: DragDropContext.DragDropContext

		local gui = self._binding:getValue()
		dropContext:dispatch({ type = "REGISTRY/ADD_SOURCE", source = self._binding, props = self.props })

		if self.props.DragController == "Snapdragon" then
			self:setSnapdragonDraggable(gui)
		else
			self:setLegacyDraggable(gui)
		end
	end

	function Connection:willUnmount()
		self._alive = false

		if self.dragController then
			self.dragController:Destroy()
		end

		if self._inputBegan then
			self._inputBegan:Disconnect()
			self._inputBegan = nil
		end

		if self._inputChanged then
			self._inputChanged:Disconnect()
			self._inputChanged = nil
		end

		if self._globalInputChanged then
			self._globalInputChanged:Disconnect()
			self._globalInputChanged = nil
		end

		if self._dragEvent then
			self._dragEvent:Disconnect()
			self._dragEvent = nil
		end

		local context = self:__getContext(storeKey) :: DragDropContext.DragDropContext
		context:dispatch({ type = "REGISTRY/REMOVE_SOURCE", source = self._binding })
		self._bindingUpdate(nil)
	end

	function Connection:render()
		if elementKind(innerComponent) == "host" then
			-- Intercept ref (in case it's user-set)
			local ref = self.props[Roact.Ref]
			local function refFn(rbx)
				self._bindingUpdate(rbx)

				if ref then
					if typeof(ref) == "function" then
						ref(rbx)
					else
						warn("Cannot use Roact.Ref with DragSource")
					end
				end
			end

			if self.props.IsDragModal then
				return Roact.createFragment({
					ModalRender = self.state.dragging and Roact.createElement(Roact.Portal, {
						target = game.Players.LocalPlayer.PlayerGui,
					}, {
						Roact.createElement("ScreenGui", { DisplayOrder = 1000 }, {
							Roact.createElement(
								innerComponent,
								join(self.state.computedProps, {
									[Roact.Ref] = function(rbx)
										self._modalRbx = rbx
									end,
									Position = self.state.position,
									Size = self.state.size,
								})
							),
						}),
					}),
					Model = Roact.createElement(
						innerComponent,
						join(self.state.computedProps, {
							[Roact.Ref] = refFn,
							Visible = not self.state.dragging,
						})
					),
				})
			else
				return Roact.createElement(
					innerComponent,
					join(self.state.computedProps, {
						[Roact.Ref] = refFn,
						Position = self.state.position,
					})
				)
			end
		else
			return nil
		end
	end

	return Connection
end

return createDragSource
