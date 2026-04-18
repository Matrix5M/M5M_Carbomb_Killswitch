MKAnimations = MKAnimations or {}

MKAnimations.Install = {
    dict = 'mini@repair',
    clip = 'fixing_a_ped'
}

MKAnimations.Scan = {
    dict = 'amb@world_human_vehicle_mechanic@male@base',
    clip = 'base'
}

MKAnimations.Remove = {
    dict = 'mini@repair',
    clip = 'fixing_a_player'
}

function MKAnimations.Play(data, duration)
    data = data or {}
    if not data.dict or not data.clip then return end
    RequestAnimDict(data.dict)
    while not HasAnimDictLoaded(data.dict) do Wait(0) end
    TaskPlayAnim(PlayerPedId(), data.dict, data.clip, 3.0, 3.0, duration or -1, 1, 0.0, false, false, false)
end

function MKAnimations.Stop()
    ClearPedTasks(PlayerPedId())
end
