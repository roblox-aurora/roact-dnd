local Roact = require(script.Parent.Roact)
local createDragSource = require(script.createDragSource)(Roact)
local createDropTarget = require(script.createDropTarget)(Roact)

return {
    DragFrame = createDragSource("Frame"),
    DropFrame = createDropTarget("Frame")
}