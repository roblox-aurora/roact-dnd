--[[
    A shim to import roact depending on whether or not the user is using roblox-ts or plain Luau.
]]

local TS = _G[script.Parent]; -- If we're using TS, this _should_ work.

local function importRoact(...)
    local path
    if TS then
        -- TypeScript's imports are a bit different here.
        path = TS.getModule(script, "roact").roact.src
    else
        local relative = script.Parent.Parent:FindFirstChild("Roact")
        if relative then
            path = relative
        else
            error("Could not import Roact", 2);
        end
    end

    local relative = {...}
    for _, fragment in ipairs(relative) do
        path = assert(path:FindFirstChild(fragment), "Could not find " .. fragment .. " in " .. path:GetFullName())
    end

    return require(path)
end

return importRoact