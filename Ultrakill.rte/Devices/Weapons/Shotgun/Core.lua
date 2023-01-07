function Create(self)
	self.bounce = true
end

function Update(self)
	self.Frame = (self.Frame + 1) % 2
	
	if self.Frame == 1 or math.random(0, 100) < 40 then
		local flash = CreateMOPixel("Glow Core Charge Shotgun", "Ultrakill.rte");
		--flash.Vel = self.Vel
		flash.Pos = self.Pos
		flash.GlobalAccScalar = 0.0;
		MovableMan:AddParticle(flash);
	end
	local flash = CreateMOPixel("Glow Main Core Charge Shotgun", "Ultrakill.rte");
	flash.Vel = self.Vel
	flash.Pos = self.Pos
	flash.GlobalAccScalar = 0.0;
	MovableMan:AddParticle(flash);
	
	self.lastVel = Vector(self.Vel.X, self.Vel.Y)
end

function OnCollideWithMO(self, collidedMO, collidedRootMO)
	if collidedMO.PresetName == "Malicious Face" then
		if self.bounce then
			self.Pos = self.Pos - Vector(self.Vel.X, self.Vel.Y):SetMagnitude(2)
			self.Vel = self.Vel * 0.05 + Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * 1
			self.bounce = false
		end
		return
	end
	self:GibThis()
end

function OnCollideWithTerrain(self, terrainID)
	self:GibThis()
end