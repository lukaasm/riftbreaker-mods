local tower = require("lua/buildings/defense/tower.lua")

class 'tower_player_weapon' ( tower )

TurretStatus = {
	TS_UNKNOWN = 0,
	TS_ON_WEAPON_AIM = 4
}

function tower_player_weapon:__init()
	tower.__init(self,self)
end

function tower_player_weapon:OnInit()
	tower.OnInit(self)

	self.equipped_weapon = INVALID_ID

	self.attack_controller = self:CreateStateMachine()
	self.attack_controller:AddState("shoot", { enter = "OnShootEnter", execute = "OnShootExecute", exit = "OnShootExit",})

	self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
end

function tower_player_weapon:OnTurretEvent( evt )
	if self.equipped_weapon == INVALID_ID then
		return 
	end

	local status = evt:GetTurretStatus()
	if status == TurretStatus.TS_ON_WEAPON_AIM then
		self.attack_controller:ChangeState("shoot")
	else
		self.attack_controller:Deactivate();
	end
end

local function GetSubSlotForItem( owner, slot_name, item )
    local equipment = reflection_helper( EntityService:GetComponent(owner, "EquipmentComponent") ).equipment[1]
	if equipment.id then
		equipment = reflection_helper( EntityService:GetComponent(equipment.id, "EquipmentComponent") ).equipment[1]
	end

    local slots = equipment.slots
    for i=1,slots.count do
        local slot = slots[i]
        if slot.name == slot_name then
			for i=1,slot.subslots.count do
				local entities = slot.subslots[i]
				local entity = entities[1]
				if entities[1] and entities[1].id == item then
					return i - 1
				end
			end
        end
    end

    return -1
end

function tower_player_weapon:OnItemEquippedEvent( evt )
	self.equipped_weapon = evt:GetItem()

	-- FIX ME: there is a bug that doesn't remove weapon from player mech so we need to do that here! 
	local player = PlayerService:GetPlayerControlledEnt(0)
	if player == INVALID_ID then
		return
	end

	for slot_name in Iter({ "LEFT_HAND", "RIGHT_HAND"}) do
		local index = GetSubSlotForItem(player, slot_name, self.equipped_weapon)
		if index ~= -1 then
			QueueEvent("EquipmentChangeRequest", player, slot_name, index, INVALID_ID )
			QueueEvent("EquipItemRequest", self.entity, self.equipped_weapon, "MOD_1")
		end
	end
end

function tower_player_weapon:OnShootEnter()
end

function tower_player_weapon:OnShootExecute()
	local item_component = reflection_helper(EntityService:GetComponent(self.equipped_weapon, "InventoryItemComponent"))
	if item_component.continuous then
		QueueEvent( "ActivateItemRequest", self.equipped_weapon, item_component.continuous )
	else
		QueueEvent( "ActivateOnceItemRequest", self.equipped_weapon, item_component.continuous )
	end
end

function tower_player_weapon:OnShootExit()
	QueueEvent( "DeactivateItemRequest", self.equipped_weapon, false )
end

return tower_player_weapon
