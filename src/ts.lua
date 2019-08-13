local Roact = require(script.Parent.Parent.roact.roact.src)
local createDragSource = require(script.createDragSource)(Roact)
local createDropTarget = require(script.createDropTarget)(Roact)

return {
    DragFrame = createDragSource("Frame"),
    DropFrame = createDropTarget("Frame")
}