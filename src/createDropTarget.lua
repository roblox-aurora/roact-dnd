return function(Roact)
	local storeKey = require(script.Parent.storeKey)
	local elementKind = require(script.Parent.elementKind)
	local join = require(script.Parent.join)

	local function createDropTarget(innerComponent, defaults)
		local componentName = ("DropTarget(%s)"):format(tostring(innerComponent))
		local Connection = Roact.Component:extend(componentName)

		function Connection:init(props)
			local dropContext = self._context[storeKey]
			if not dropContext then
				error("A top-level DragDropProvider was not provided in the heirachy.")
			end

			if props.DropId == nil then
				error(("%s requires a DropId prop to be set."):format(componentName))
			end

			if type(props.TargetDropped) ~= "function" then
				error(("%s requires a TargetDropped callback prop to be set."):format(componentName))
			end

			local computedProps = defaults or {}
			for key, value in next, props do
				if
					key ~= "DropId" and key ~= "TargetDropped" and key ~= "TargetPriority" and key ~= "CanDrop" and
						key ~= "TargetHover"
				 then
					computedProps[key] = value
				end
			end

			self.state = {
				computedProps = computedProps
			}

			local binding, bindingUpdate = Roact.createBinding(nil)
			self._bindingUpdate = bindingUpdate
			self._binding = binding
		end

		function Connection:willUnmount()
			if (self._rbx) then
				local context = self._context[storeKey]
				context:RemoveTarget(self._binding)

				self._bindingUpdate(nil)
				self._binding = nil
				self._bindinUpdate = nil
			end
		end

		function Connection:didMount()
			local context = self._context[storeKey]
			context:AddTarget(self._binding, self.props)
		end

		function Connection:render()
			if (elementKind(innerComponent) == "host") then
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

	return createDropTarget
end
