-- requires game executable update for auto unlock
if not RegisterGlobalEvent then
    return
end

RegisterGlobalEvent("PlayerCreatedEvent", function(arg)
    BuildingService:UnlockBuilding("buildings/defense/tower_player_weapon")
end)