local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Roact)
local e = Roact.createElement
local RoactDnD = require(ReplicatedStorage.RoactDnD)

local handle
local droppedOver = false

local function render()
	return e(
		"ScreenGui",
		{},
		{
			e(
				RoactDnD.DragDropProvider,
				{},
				{
					Roact.createFragment(
						{
							ExampleDrop = e(
								RoactDnD.DropFrame,
								{
									DropId = "Ex1",
									TargetDropped = function(data)
										print("target Dropped", data)
									end,
									Size = UDim2.new(0, 100, 0, 100),
									BackgroundTransparency = 0.5,
									BackgroundColor3 = droppedOver and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0)
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
									BackgroundColor3 = Color3.fromRGB(0, 0, 0)
								},
								{
									e("TextLabel", {Size = UDim2.new(1, 0, 1, 0), Text = "Drag Me!", BackgroundTransparency = 1})
								}
							)
						}
					)
				}
			)
		}
	)
end

Roact.mount(render(), game.Players.LocalPlayer.PlayerGui, "Example1")
