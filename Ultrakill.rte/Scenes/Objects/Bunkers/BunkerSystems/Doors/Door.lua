
function Create(self)
	ToActor(self:GetRootParent()).MissionCritical = true
	self.MissionCritical = true
	self.locked = false
	
	self.noPassSprite = CreateMOSRotating("No Pass Skull", "Ultrakill.rte")
	
	self.soundUnlock = CreateSoundContainer("Door Unlock", "Ultrakill.rte");
	self.soundUnlock.Volume = 3
	
	self.originalTeam = ToActor(self:GetRootParent()).Team
end

function Update(self)
	local parent = self:GetRootParent()
	if parent then
		--self:RemoveWounds(self.WoundCount)
		
		parent = ToActor(parent)
		if self:GetNumberValue("Closed") == 1 or parent:GetNumberValue("Closed") == 1 then
			ToADoor(parent):CloseDoor()
			self.locked = true
			self.Frame = 1
			
			MovableMan:ChangeActorTeam(ToActor(parent), 4)
			
			
			if self:GetNumberValue("Danger") == 1 or parent:GetNumberValue("Danger") == 1 then
				for i = 0, 3 do
					PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(i), self.Pos, self.noPassSprite, 0, 0);
				end
			end
		else
			if self:GetNumberValue("Open") == 1 or parent:GetNumberValue("Open") == 1 then
				ToADoor(parent):OpenDoor()
			end
			
			if self.locked then
				self.locked = false
				self.soundUnlock:Play(self.Pos)
				
				MovableMan:ChangeActorTeam(ToActor(parent), self.originalTeam)
				ToADoor(parent):FlashWhite(300)
			end
			self.Frame = 0
		end
	end
	
end