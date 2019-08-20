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
		end

		function Connection:willUnmount()
			if (self._rbx) then
				local context = self._context[storeKey]
				context:RemoveTarget(self._rbx)
			end
		end

		function Connection:render()
			if (elementKind(innerComponent) == "host") then
				local ref = self.props[Roact.Ref]
				local function refFn(rbx)
					self._rbx = rbx

					local context = self._context[storeKey]
					context:AddTarget(rbx, self.props)

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

	return createDropTarget
end
