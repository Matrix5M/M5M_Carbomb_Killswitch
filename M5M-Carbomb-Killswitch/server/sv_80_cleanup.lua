AddEventHandler('playerDropped', function()
    local src = source
    MKRuntime.DetectionBySource[src] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    MKRuntime.ByPlate = {}
    MKRuntime.Cooldowns = { action = {}, tracker = {}, emp = {} }
    MKRuntime.DetectionBySource = {}
end)
