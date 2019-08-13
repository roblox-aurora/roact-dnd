return function(Roact)
    local storeKey = require(script.Parent.storeKey)
    local join = require(script.Parent.join)
    local elementKind = require(script.Parent.elementKind)

    local function createDragSource(innerComponent)
        local componentName = ("DragSource(%s)"):format(tostring(innerComponent))
        local Connection = Roact.Component:extend(componentName)

        function Connection:init(props)
            local dropContext = self._context[storeKey]
            if not dropContext then
                error("A top-level DragDropProvider was not provided in the heirachy.")
            end

            local computedProps = {}
            for key, value in next, props do
                if (key ~= "DropId" and key ~= "TargetData" and key ~= "DragConstraint" and key ~= "DropResetsPosition") then
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
            local dropResetsPosition = props.DropResetsPosition

            local gui = self._rbx
            if (gui) then
                local dragging
                local dragInput
                local dragStart
                local startPos

                local function update(input)
                    local ul, br = game:GetService("GuiService"):GetGuiInset()
                    local view = workspace.CurrentCamera.ViewportSize
                    local screen = snapBehaviour == "ViewportIgnoreInset" and view or view - ul + br

                    local delta = input.Position - dragStart

                    if snapBehaviour ~= "None" then
                        local scaleOffsetX = screen.X * startPos.X.Scale
                        local scaleOffsetY = screen.Y * startPos.Y.Scale
                        local resultingOffsetX = startPos.X.Offset + delta.X
                        local resultingOffsetY = startPos.Y.Offset + delta.Y

                        if (resultingOffsetX + scaleOffsetX) > screen.X - gui.AbsoluteSize.X then
                            resultingOffsetX = screen.X - gui.AbsoluteSize.X - scaleOffsetX
                        elseif (resultingOffsetX + scaleOffsetX) < 0 then
                            resultingOffsetX = -scaleOffsetX
                        end

                        if (resultingOffsetY + scaleOffsetY) > screen.Y - gui.AbsoluteSize.Y then
                            resultingOffsetY = screen.Y - gui.AbsoluteSize.Y - scaleOffsetY
                        elseif (resultingOffsetY + scaleOffsetY) < 0 then
                            resultingOffsetY = -scaleOffsetY
                        end

                        gui.Position = UDim2.new(startPos.X.Scale, resultingOffsetX, startPos.Y.Scale, resultingOffsetY)
                    else
                        gui.Position =
                            UDim2.new(
                            startPos.X.Scale,
                            startPos.X.Offset + delta.X,
                            startPos.Y.Scale,
                            startPos.Y.Offset + delta.Y
                        )
                    end
                end

                self._inputBegan =
                    gui.InputBegan:Connect(
                    function(input)
                        if
                            input.UserInputType == Enum.UserInputType.MouseButton1 or
                                input.UserInputType == Enum.UserInputType.Touch
                         then
                            dragging = true
                            dragStart = input.Position
                            startPos = (dragGui or gui).Position

                            input.Changed:Connect(
                                function()
                                    if input.UserInputState == Enum.UserInputState.End then
                                        -- On Drop
                                        dragging = false

                                        -- TODO: Fire 'TargetDropped' prop of any DropTargets underneath

                                        if (dropResetsPosition) then
                                            gui.Position =
                                                UDim2.new(
                                                startPos.X.Scale,
                                                startPos.X.Offset,
                                                startPos.Y.Scale,
                                                startPos.Y.Offset
                                            )
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
                        if
                            input.UserInputType == Enum.UserInputType.MouseMovement or
                                input.UserInputType == Enum.UserInputType.Touch
                         then
                            dragInput = input
                        end
                    end
                )

                self._globalInputChanged =
                    UserInputService.InputChanged:Connect(
                    function(input)
                        if input == dragInput and dragging then
                            update(input)
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
                    dropContext.context:AddSource(rbx, self.props.DropId, self.props.TargetData)

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
    end

    return createDragSource
end
