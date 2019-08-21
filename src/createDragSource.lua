local UserInputService = game:GetService("UserInputService")
return function(Roact)
	local storeKey = require(script.Parent.storeKey)
	local join = require(script.Parent.join)
	local elementKind = require(script.Parent.elementKind)

	local function createDragSource(innerComponent, defaults)
		local componentName = ("DragSource(%s)"):format(tostring(innerComponent))
		local Connection = Roact.Component:extend(componentName)

		function Connection:init(props)
			local dropContext = self._context[storeKey]
			if not dropContext then
				error("A top-level DragDropProvider was not provided in the heirachy.")
			end

			if props.DropId == nil then
				error(("%s requires a DropId prop to be set."):format(componentName))
			end

			if props.TargetData == nil then
				error(("%s requires a TargetData prop to be set."):format(componentName))
			end

			local computedProps = defaults or {}
			for key, value in next, props do
				if
					(key ~= "DropId" and key ~= "TargetData" and key ~= "DragConstraint" and key ~= "DropResetsPosition" and
						key ~= "CanDrag" and
						key ~= "DragBegin" and
						key ~= "DragEnd")
				 then
					computedProps[key] = value
				end
			end

			self.state = {
				computedProps = computedProps
			}
		end

		function Connection:didMount()
			local props = self.props
			local snapBehaviour = props.DragConstraint or "None"
			local canDrag = props.CanDrag or function()
					return true
				end
			local dropResetsPosition = props.DropResetsPosition
			local dropContext = self._context[storeKey]
			local dragBegin = props.DragBegin
			local dragEnd = props.DragEnd

			local gui = self._rbx
			if (gui) then
				local dragging
				local dragInput
				local dragStart
				local startPos
				local dropTargets

				local function update(input, targetGui)
					assert(targetGui and typeof(targetGui) == "Instance" and targetGui:IsA("GuiObject"))
					local ul, br = game:GetService("GuiService"):GetGuiInset()
					local view = workspace.CurrentCamera.ViewportSize
					local screen = snapBehaviour == "ViewportIgnoreInset" and view or view - ul + br

					local delta = input.Position - dragStart

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

						targetGui.Position = UDim2.new(startPos.X.Scale, resultingOffsetX, startPos.Y.Scale, resultingOffsetY)
					else
						targetGui.Position =
							UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
					end
				end

				self._inputBegan =
					gui.InputBegan:Connect(
					function(input)
						if
							(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and
								canDrag(self.props.TargetData)
						 then
							dragging = true
							dragStart = input.Position
							startPos = (dragGui or gui).Position
							dropTargets = dropContext:GetTargetsByDropId(self.props.DropId) -- Prefetch drop targets here

							if type(dragBegin) == "function" then
								dragBegin()
							end

							input.Changed:Connect(
								function()
									if input.UserInputState == Enum.UserInputState.End then
										-- On Drop
										dragging = false

										-- TODO: Fire 'TargetDropped' prop of any DropTargets underneath

										if type(dragEnd) == "function" then
											dragEnd()
										end

										if (dropResetsPosition) then
											gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset)
										end
									end
								end
							)
						end
					end
				)

				self._inputChanged =
					gui.InputChanged:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							dragInput = input
						end
					end
				)

				self._globalInputChanged =
					UserInputService.InputChanged:Connect(
					function(input)
						if input == dragInput and dragging then
							update(input, gui)
						end
					end
				)
			else
				warn("Ref not set for " + tostring(tostring(innerComponent)))
			end
		end

		function Connection:willUnmount()
			if (self._globalInputChanged) then
				self._globalInputChanged:Disconnect()
			end

			if (self._rbx) then
				local dropContext = self._context[storeKey]
				dropContext:RemoveSource(self._rbx)
			end
		end

		function Connection:render()
			if (elementKind(innerComponent) == "host") then
				-- Intercept ref (in case it's user-set)
				local ref = self.props[Roact.Ref]
				local function refFn(rbx)
					self._rbx = rbx

					local dropContext = self._context[storeKey]
					dropContext:AddSource(rbx, self.props.DropId, self.props.TargetData)

					if ref then
						if typeof(ref) == "function" then
							ref(rbx)
						else
							warn("Cannot use Roact.Ref with DragSource")
						end
					end
				end

				return Roact.createElement(
					innerComponent,
					join(
						self.state.computedProps,
						{
							[Roact.Ref] = refFn
						}
					)
				)
			else
				return nil
			end
		end

		return Connection
	end

	return createDragSource
end
