RegisterGlobalEventHandler("PlayerInitializedEvent", function(arg)
    BuildingService:UnlockBuilding("buildings/defense/tower_player_weapon")
end)