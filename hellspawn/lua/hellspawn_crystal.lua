class 'hellspawn_crystal' ( LuaEntityObject )

function hellspawn_crystal:__init()
	LuaEntityObject.__init(self,self)
end

function hellspawn_crystal:init()
    self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState("teleport", { enter = "OnTeleportEnter", exit = "OnTeleportExit"})

    EntityService:SetGraphicsUniform( self.entity, "cDissolveColor", 10.0, 0.0, 0.0, 1.0 )
end

function hellspawn_crystal:OnTeleportEnter(state)
    QueueEvent("FadeEntityOutRequest", self.entity, 4.0 )
    state:SetDurationLimit(4.0)
end

function hellspawn_crystal:OnTeleportExit()
    local mission_name = "hellspawn_" .. tostring(self.entity)
    CampaignService:UnlockMission(mission_name, "custom/hellspawn")
    CampaignService:ChangeCurrentMission(mission_name)

    EntityService:RemoveEntity(self.entity)
end

function hellspawn_crystal:OnInteractWithEntityRequest( evt )
    QueueEvent("FadeEntityOutRequest", evt:GetOwner(), 5.0 )
    GuiService:FadeOut( 4.0 )

    self.fsm:ChangeState("teleport")
end

return hellspawn_crystal