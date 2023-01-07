function Create(self)
	self.Hurt = true
end

function Update(self)
	self.RotAngle = 0
	self.Frame = math.random(0,1)
	
	--self.Scale = 0.5 + math.random() * 0.75
end

function OnCollideWithTerrain(self, terrainID) -- Go kabloow
	self:GibThis()
end

function OnCollideWithMO(self, collidedMO, collidedRootMO)
	-- if self:NumberValueExists("Parried") then
		-- self:RemoveNumberValue("Parried")
		-- self.Hurt = true
		-- return
	-- end
	
	-- if not self:NumberValueExists("Parried") and string.find(collidedMO.PresetName , "V1 Punch") then
		-- mo = ToMOSRotating(collidedMO)
		
		-- self:SetNumberValue("Parried", 1)
		-- self.Team = mo.Team
		-- self.Vel = Vector(self.Vel.Magnitude, 0):RadRotate(mo.Vel.AbsRadAngle)
		-- self.ToDelete = false
		-- return
	-- end
	
	if not self.Hurt then return end
	
	if collidedRootMO and IsActor(collidedRootMO) then
		local actor = ToActor(collidedRootMO)
		if not actor:NumberValueExists("HellBallLastAge") or math.abs(actor:GetNumberValue("HellBallLastAge") - actor.Age) > 500 then
			actor.Health = actor.Health - 25
			
			actor:SetNumberValue("HellBallLastAge", actor.Age)
		end
	end
	self.Hurt = false
	self:GibThis()
end