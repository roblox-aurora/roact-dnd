local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Roact)
local e = Roact.createElement
local RoactDnD = require(ReplicatedStorage.RoactDnD)

local TestDragDropComponent = Roact.PureComponent:extend("TestDragDropComponent")
function TestDragDropComponent:init()
	self:setState {
		dropped = false
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
					DropId = "Ex1",
					CanDrop = function()
						return true
					end,
					TargetDropped = function(data, gui)
						print("Dropped on frame")
						if self.dropFrame then
							gui.Position = self.dropFrame.Position
						end
						self:setState({dropped = true})
					end,
					Size = UDim2.new(0, 100, 0, 100),
					BackgroundTransparency = 0.5,
					BackgroundColor3 = self.state.dropped and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0)
				},
				{
					e("TextLabel", {Size = UDim2.new(1, 0, 1, 0), Text = "Drop here!", BackgroundTransparency = 1})
				}
			),
			ExampleDrag = e(
				RoactDnD.DragFrame,
				{
					DropId = "Ex1",
					TargetData = "Hello, World!",
					BackgroundTransparency = 0.5,
					Size = UDim2.new(0, 100, 0, 100),
					Position = UDim2.new(0, 300, 0, 300),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					DragEnd = function(dropped)
						-- handle = Roact.update(handle, render())
						print("user stopped dragging")
						if not dropped then
							self:setState({dropped = false})
						end
					end,
					DragBegin = function()
						print("user began dragging")
					end
				},
				{
					e("TextLabel", {Size = UDim2.new(1, 0, 1, 0), Text = "Drag Me!", BackgroundTransparency = 1})
				}
			)
		}
	)
end

return TestDragDropComponent
