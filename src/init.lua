local importRoact = require(script.importRoact)
local parent = script
local createDragSource = require(parent.createDragSource)
local createDropTarget = require(parent.createDropTarget)
local DragDropProvider = require(parent.DragDropProvider)
local DragDropContext = require(parent.DragDropContext)
DragDropContext.Type = importRoact("Type")

return {
	DragFrame = createDragSource("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0)}),
	DropFrame = createDropTarget("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0)}),
	DragImageButton = createDragSource("ImageButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0)}),
	DragDropProvider = DragDropProvider,
	DragDropContext = DragDropContext
}