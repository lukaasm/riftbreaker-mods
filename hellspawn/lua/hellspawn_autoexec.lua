local state = CampaignService:GetCampaignData()

    -- TODO: extend and move it to utils
local function CreateObjective( display_name )
    local params = CampaignService:GetCampaignData()
    params:SetString("display_name", display_name)

    local objective = ObjectiveService:CreateObjective("", params, true, CampaignService:GetCurrentMissionId())
    params:RemoveKey("display_name")

    return objective
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    -- TODO: proper mission detection
    if not MissionService:IsMainMission() then
        return
    end

    if state:HasInt("hs_objective") then
        return
    end

    local spawns = FindService:FindPlayerSpawnPoints()
    if not Assert(#spawns >= 1, "ERROR: failed to acquire spawn point!") then
        return
    end

    local entity = EntityService:SpawnEntity("hellspawn/teleport_crystal", spawns[1], "enemy" );

    local objective = CreateObjective("Investigate crystal")
    state:SetInt("hs_objective", objective);
end)

-- TODO: proper mission detection
if not MissionService:IsMainMission() then
    SoundService:EnableAdaptiveMusic( false )
    for _,type in ipairs({ "loading", "fighting", "exploration", "fear", "adventure"}) do
        SoundService:SetPlaylistOverride("music/" .. type, "hellspawn_music/playlist")
    end
end