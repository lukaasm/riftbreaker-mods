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
	self.equipped_weapon_item = INVALID_ID

	self.missing_resources = {}
	self.attack_controller = self:CreateStateMachine()
	self.attack_controller:AddState("shoot", { enter = "OnShootEnter", execute = "OnShootExecute", exit = "OnShootExit"})

	self.icons_controller = self:CreateStateMachine()
	self.icons_controller:AddState("check_icons", { execute = "OnCheckIconsExecute", interval = 0.5 })
	self.icons_controller:ChangeState("check_icons")

	self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
	self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
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

function tower_player_weapon:OnCheckIconsExecute()
	if WeaponService:HasAmmoToShoot(self.equipped_weapon_item) then
		self:ClearMissingResources()
	end
end

function tower_player_weapon:OnResourceMissingEvent(evt)
	local iconEntity = self.missing_resources[ evt:GetResource() ]
	if iconEntity ~= nil then
		return
	end

	self.missing_resources[ evt:GetResource() ] = BuildingService:AttachMissingResourceIcon( self.entity, evt:GetResource(), true)
end

function tower_player_weapon:ClearMissingResources()
	for _,iconEntity in pairs(self.missing_resources) do
		EntityService:RemoveEntity(iconEntity)
	end

	self.missing_resources = {}
end

function tower_player_weapon:OnItemUnequippedEvent( evt )
	if self.equipped_weapon ~= evt:GetItem() then
		return
	end

	if self.equipped_weapon_item == INVALID_ID then
		return
	end

	self:ClearMissingResources()

	self:UnregisterHandler( self.equipped_weapon_item, "ResourceMissingEvent", "OnResourceMissingEvent" )

	self.equipped_weapon = INVALID_ID
	self.equipped_weapon_item = INVALID_ID
end

function tower_player_weapon:OnItemEquippedEvent( evt )
	self.equipped_weapon = evt:GetItem()

	if self.equipped_weapon ~= INVALID_ID then
		EffectService:AttachEffects(self.entity, "working")
	else
		EffectService:DestroyEffectsByGroup(self.entity, "working")
	end

	self.is_charge_weapon = false

	self.equipped_weapon_item = EntityService:GetChildByName(self.equipped_weapon, evt:GetSlot())
	if self.equipped_weapon_item ~= INVALID_ID then
		self.is_charge_weapon = EntityService:HasComponent(self.equipped_weapon_item,"ChargeWeaponComponent")

		self:RegisterHandler( self.equipped_weapon_item, "ResourceMissingEvent", "OnResourceMissingEvent" )
	end

	-- FIX ME: there is a bug that doesn't remove weapon from player mech so we need to do that here! 
	local player = PlayerService:GetPlayerControlledEnt(0)
	if player == INVALID_ID then
		return
	end

	for slot_name in Iter({ "LEFT_HAND", "RIGHT_HAND"}) do
		local index = GetSubSlotForItem(player, slot_name, self.equipped_weapon)
		if index ~= -1 then
			self:RegisterHandler( player, "ItemUnequippedEvent", "OnPlayerItemUnequippedEvent" )
			QueueEvent("EquipmentChangeRequest", player, slot_name, index, INVALID_ID )
		end
	end
end

function tower_player_weapon:OnPlayerItemUnequippedEvent(evt)
	self:UnregisterHandler( evt:GetEntity(), "ItemUnequippedEvent", "OnPlayerItemUnequippedEvent" )

	QueueEvent("EquipItemRequest", self.entity, self.equipped_weapon, "MOD_1")
end

function tower_player_weapon:OnShootEnter()
	--QueueEvent("ActivateEquipmentSlotRequest", self.entity, "MOD_1", "" )
end

function tower_player_weapon:OnShootExecute()
	if self.is_charge_weapon then
		QueueEvent("ActivateOnceEquipmentSlotRequest", self.entity, "MOD_1", "" )
	else
		QueueEvent("DeactivateEquipmentSlotRequest", self.entity, "MOD_1", true )
		QueueEvent("ActivateEquipmentSlotRequest", self.entity, "MOD_1", "" )
	end
end

function tower_player_weapon:OnShootExit()
	QueueEvent("DeactivateEquipmentSlotRequest", self.entity, "MOD_1", true )
end

return tower_player_weapon
