local UserInputService = game:GetService("UserInputService")
return function(Roact)
	local storeKey = require(script.Parent.storeKey)
	local join = require(script.Parent.join)
	local elementKind = require(script.Parent.elementKind)
	local utility = require(script.Parent.utility)
	local equal = utility.deepEqual

	local function createDragSource(innerComponent, defaults)
		local componentName = ("DragSource(%s)"):format(tostring(innerComponent))
		local Connection = Roact.Component:extend(componentName)

		function Connection:computeProps()
			local computedProps = defaults or {}
			for key, value in next, self.props do
				if
					(key ~= "DropId" and key ~= "TargetData" and key ~= "DragConstraint" and key ~= "DropResetsPosition" and
						key ~= "CanDrag" and
						key ~= "DragBegin" and
						key ~= "DragEnd" and
						key ~= "IsDragModal")
				 then
					computedProps[key] = value
				end
			end
			return computedProps
		end

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

			self.state = {
				computedProps = self:computeProps()
			}

			local binding, updateBinding = Roact.createBinding(nil)
			self._binding = binding
			self._bindingUpdate = updateBinding
		end

		function Connection:didUpdate(prevProps)
			if prevProps.Position ~= self.props.Position and self.state.position ~= nil then
				self:setState({position = self.props.position})
			end
			if not equal(prevProps, self.props) then
				self:setState({computedProps = self:computeProps()})
			end
		end

		function Connection:setDraggable(gui)
			local props = self.props
			local snapBehaviour = props.DragConstraint or "None"
			local canDrag = props.CanDrag or function()
					return true
				end

			local dropResetsPosition = props.DropResetsPosition
			if dropResetsPosition == nil then
				dropResetsPosition = true
			end

			local dropContext = self._context[storeKey]

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

			if (gui) then
				local dropTargets

				local function update(input, targetGui)
					assert(targetGui and typeof(targetGui) == "Instance" and targetGui:IsA("GuiObject"))
					local ul, br = game:GetService("GuiService"):GetGuiInset()
					local view = workspace.CurrentCamera.ViewportSize
					local startPos = self.state.startPos
					local screen = snapBehaviour == "ViewportIgnoreInset" and view or view - ul + br

					local delta = input.Position - self.state.dragStart

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
						self:setState(
							{
								position = UDim2.new(startPos.X.Scale, resultingOffsetX, startPos.Y.Scale, resultingOffsetY),
								absolutePosition = UDim2.new(
									0,
									(startPos.X.Scale * view.X) + resultingOffsetX,
									0,
									(startPos.Y.Scale * view.Y) + resultingOffsetY
								)
							}
						)
					else
						-- targetGui.Position =
						-- 	UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)

						self:setState(
							{
								position = UDim2.new(
									startPos.X.Scale,
									startPos.X.Offset + delta.X,
									startPos.Y.Scale,
									startPos.Y.Offset + delta.Y
								),
								absolutePosition = UDim2.new(
									0, --startPos.X.Scale,
									startPos.X.Offset + delta.X,
									0, --startPos.Y.Scale,
									startPos.Y.Offset + delta.Y
								)
							}
						)
					end
				end

				self._inputBegan =
					gui.InputBegan:Connect(
					function(input)
						if
							(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and
								canDrag(self.props.TargetData)
						 then
							local currentGui = self._binding:getValue()
							if currentGui then
								local absSize = currentGui.AbsoluteSize
								self:setState({size = UDim2.new(0, absSize.X, 0, absSize.Y)})
							end

							local gui = self._modalRbx or gui

							dropContext:dispatch({type = "DRAG/BEGIN", source = self._binding})

							self:setState(
								{
									dragging = true,
									dragStart = input.Position,
									position = self.props.IsDragModal and UDim2.new(0, gui.AbsolutePosition.X, 0, gui.AbsolutePosition.Y),
									startPos = self.props.IsDragModal and UDim2.new(0, gui.AbsolutePosition.X, 0, gui.AbsolutePosition.Y) or
										gui.Position,
									dropTargets = dropContext:GetTargetsByDropId(self.props.DropId)
								}
							)

							self._dragEvent =
								input.Changed:Connect(
								function()
									if
										input.UserInputState == Enum.UserInputState.End and
											(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
									 then
										gui = self._modalRbx or gui

										-- On Drop
										local dropped = false
										for _, target in next, self.state.dropTargets do
											local targetGui = target.Binding:getValue()
											if targetGui then
												local targetGuiPos = targetGui.AbsolutePosition
												local sourceGuiPos = gui.AbsolutePosition
												local targetGuiSize = targetGui.AbsoluteSize
												local sourceGuiSize = gui.AbsoluteSize

												if
													(utility.pointsIntersect(
														sourceGuiPos,
														sourceGuiPos + sourceGuiSize,
														targetGuiPos,
														targetGuiPos + targetGuiSize
													))
												 then
													-- target.OnDrop(self.props.TargetData, gui)
													dropContext:dispatch(
														{
															type = "DROP/TARGET",
															data = self.props.TargetData,
															dropId = self.props.DropId,
															source = self._binding,
															target = target.Binding
														}
													)
													dropped = true
													break
												end
											end
										end

										if (dropResetsPosition) then
											self:setState({position = Roact.None, dragging = false})
										else
											self:setState({dragging = false})
											local currentGui = self._binding:getValue()
											if currentGui then
												currentGui.Position = self.state.position
											end
										end

										dropContext:dispatch({type = "DRAG/END", source = self._binding, dropped = dropped})
										self._dragEvent:Disconnect()
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
							--dragInput = input
							self:setState({dragInput = input})
						end
					end
				)

				self._globalInputChanged =
					UserInputService.InputChanged:Connect(
					function(input)
						if input == self.state.dragInput and self.state.dragging then
							update(input, self._modalRbx or gui)
						end
					end
				)
			else
				warn("Ref not set for " .. tostring(innerComponent))
			end
		end

		function Connection:didMount()
			local dropContext = self._context[storeKey]

			local gui = self._binding:getValue()
			dropContext:dispatch({type = "REGISTRY/ADD_SOURCE", source = self._binding, props = self.props})
			self:setDraggable(gui)
		end

		function Connection:willUnmount()
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

			local context = self._context[storeKey]
			context:dispatch({type = "REGISTRY/REMOVE_SOURCE", source = self._binding})
			self._bindingUpdate(nil)
		end

		function Connection:render()
			if (elementKind(innerComponent) == "host") then
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
					return Roact.createFragment(
						{
							Modal = self.state.dragging and
								Roact.createElement(
									Roact.Portal,
									{
										target = game.Players.LocalPlayer.PlayerGui
									},
									{
										Roact.createElement(
											"ScreenGui",
											{DisplayOrder = 1000},
											{
												Roact.createElement(
													innerComponent,
													join(
														self.state.computedProps,
														{
															[Roact.Ref] = function(rbx)
																self._modalRbx = rbx
															end,
															Position = self.state.position,
															Size = self.state.size
														}
													)
												)
											}
										)
									}
								),
							TargetCom = Roact.createElement(
								innerComponent,
								join(
									self.state.computedProps,
									{
										[Roact.Ref] = refFn,
										Visible = not self.state.dragging
									}
								)
							)
						}
					)
				else
					return Roact.createElement(
						innerComponent,
						join(
							self.state.computedProps,
							{
								[Roact.Ref] = refFn,
								Position = self.state.position
							}
						)
					)
				end
			else
				return nil
			end
		end

		return Connection
	end

	return createDragSource
end
