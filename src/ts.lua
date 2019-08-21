local RoactPath = script.Parent:FindFirstAncestor("node_modules"):WaitForChild("roact").roact.src;
local Roact = require(RoactPath)
local parent = script.Parent
local createDragSource = require(parent.createDragSource)(Roact)
local createDropTarget = require(parent.createDropTarget)(Roact)
local DragDropProvider = require(parent.DragDropProvider)(Roact)
local DragDropContext = require(parent.DragDropContext)
DragDropContext.Type = require(RoactPath.Type)

return {
	DragFrame = createDragSource("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0)}),
	DropFrame = createDropTarget("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0)}),
	DragDropProvider = DragDropProvider,
	DragDropContext = DragDropContext
}
