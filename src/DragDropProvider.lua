return function(Roact)
    local storeKey = require(script.Parent.storeKey)
    local DragDropContext = require(script.Parent.DragDropContext)

    local DragDropProvider = Roact.Component:extend("DragDropProvider")
    function DragDropProvider:init(props)
        local context = props.context or DragDropContext.Default

        self._context[storeKey] = context
    end

    function DragDropProvider:render()
        return Roact.oneChild(self.props[Roact.Children])
    end
end
