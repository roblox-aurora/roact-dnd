local Roact = require(script.Parent:FindFirstAncestor("node_modules"):WaitForChild("roact").roact.src)
local parent = script.Parent
local createDragSource = require(parent.createDragSource)(Roact)
local createDropTarget = require(parent.createDropTarget)(Roact)
local DragDropProvider = require(parent.DragDropProvider)(Roact)
local DragDropContext = require(parent.DragDropContext)

return {
	DragFrame = createDragSource("Frame"),
	DropFrame = createDropTarget("Frame"),
	DragDropProvider = DragDropProvider,
	DragDropContext = DragDropContext
}
