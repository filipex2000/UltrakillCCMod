
function Create(self)
	--self.parent = ToActor(self:GetRootParent())
	--self.parent.MissionCritical = true
	self.MissionCritical = true
	MovableMan:ChangeActorTeam(self.parent, 4)
	
end

function Update(self)
	self.Frame = 1
	--self.parent = ToActor(self:GetRootParent())
	--if self.parent then
	--	ToADoor(self.parent):CloseDoor()
	--end
	if self.WoundCount > 0 then
	--	if self.parent then
	--		self.parent.MissionCritical = false
			self.Pos = self.Pos + Vector(0, 2)
 			self:EraseFromTerrain()
			self.MissionCritical = false
	--		self.parent:GibThis()
			self:GibThis()
	--	end
	end
end

function Destroy(self)
	--self.parent = ToActor(self:GetRootParent())
	--if self.parent then
	--	self.parent.MissionCritical = false
	--	self.parent.ToDelete = true
	--end
end