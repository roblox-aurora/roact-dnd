local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Roact)
local e = Roact.createElement
local RoactDnD = require(ReplicatedStorage.RoactDnD)
local TestDragComponent = require(script.TestDragDropComponent)

local handle
local droppedOver = false
local dropFrame

local function render()
	return e(
		"ScreenGui",
		{},
		{
			e(
				RoactDnD.DragDropProvider,
				{},
				{
					e(TestDragComponent)
				}
			)
		}
	)
end

handle = Roact.mount(render(), game.Players.LocalPlayer.PlayerGui, "Example1")
