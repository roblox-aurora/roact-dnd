local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Roact)
local e = Roact.createElement
local RoactDnD = require(ReplicatedStorage.RoactDnD)

local TestDragDropComponent = Roact.PureComponent:extend("TestDragDropComponent")
function TestDragDropComponent:init()
	self:setState {
		dropped = false,
		position = UDim2.new(0, 300, 0, 300)
	}
end

function TestDragDropComponent:render()
	return Roact.createFragment(
		{
			ExampleDrop = e(
				RoactDnD.DropFrame,
				{
					[Roact.Ref] = function(rbx)
						self.dropFrame = rbx
					end,
					DropId = "Ex2",
					CanDrop = function()
						return true
					end,
					TargetDropped = function(data, gui)
						print("Dropped")
					end,
					Size = UDim2.new(0, 100, 0, 100),
					BackgroundTransparency = 0.5,
					BackgroundColor3 = self.state.dropped and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0)
				},
				{
					e(
						"TextLabel",
						{Size = UDim2.new(1, 0, 1, 0), Text = "Drop here to die", TextWrapped = true, BackgroundTransparency = 1}
					)
				}
			),
			ExampleDrag = e(
				RoactDnD.DragFrame,
				{
					DropId = "Ex2",
					TargetData = "Hello, World!",
					BackgroundTransparency = 0.5,
					Size = UDim2.new(0, 100, 0, 100),
					Position = self.state.position,
					BackgroundColor3 = self.state.dragging and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(0, 0, 0),
					DragConstraint = "Viewport",
					IsDragModal = true,
					DragBegin = function()
						self:setState({dragging = true})
					end,
					DragEnd = function()
						self:setState({dragging = false})
					end,
					-- DropResetsPosition = true,
				},
				{
					e(
						"TextLabel",
						{
							Size = UDim2.new(1, 0, 1, 0),
							Text = self.state.dragging and "Dragging..." or "Drag Me!",
							BackgroundTransparency = 1
						}
					)
				}
			)
		}
	)
end

return TestDragDropComponent
