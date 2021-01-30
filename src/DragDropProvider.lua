local importRoact = require(script.Parent.importRoact)
local Roact = importRoact()

local storeKey = require(script.Parent.storeKey)
local DragDropContext = require(script.Parent.DragDropContext)

local DragDropProvider = Roact.Component:extend("DragDropProvider")
function DragDropProvider:init(props)
	local context = props.context or DragDropContext.Default

	self.context = context;
	self:__addContext(storeKey, self.context)
end

function DragDropProvider:render()
	return Roact.oneChild(self.props[Roact.Children])
end

return DragDropProvider