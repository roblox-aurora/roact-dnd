local function elementKind(component)
    local _type = typeof(component)
    if _type == "string" then
        return "host"
    elseif _type == "function" then
        return "functional"
    elseif _type == "table" then
        return "stateful"
    end
end

return elementKind;