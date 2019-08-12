local Roact = require(script.Parent.Parent.roact.roact.src)
local createDragSource = require(script.createDragSource)

return {
    DragFrame = createDragSource("Frame")
}