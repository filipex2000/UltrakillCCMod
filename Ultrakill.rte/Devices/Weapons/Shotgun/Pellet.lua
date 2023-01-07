function Create(self)
	self.GlobalAccScalar = self.GlobalAccScalar * RangeRand(0.5, 1.0);
	self.AirResistance = self.AirResistance * RangeRand(0.9, 1.1);

	self.Lifetime = self.Lifetime * RangeRand(0.5, 1.0);
	self.Sharpness = self.Sharpness * RangeRand(0.95, 1.05) * 30;
	
	self.startingSharpness = self.Sharpness + 0
end

function Update(self)
	self.WoundDamageMultiplier = 0.5 + 1.5 * math.max((200 - self.Age) / 200, 0)
	self.Sharpness = self.startingSharpness * (1 + math.max((450 - self.Age) / 450, 0) * 4) * 0.2
	
	if self.Sharpness > 1 then
		local checkPos = self.Pos + Vector(self.Vel.X,self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame)
		local checkPix = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y)
		if checkPix > 0 then
			self.Sharpness = 0
		end
	end
end

function OnCollideWithTerrain(self, terrainID)
	self.Sharpness = 0
	
	if math.random(0, 100) < 50 then
		local bzzt = CreateMOPixel("Spark Yellow 2");
		bzzt.Pos = self.Pos + Vector(self.Vel.X, self.Vel.Y):SetMagnitude(-1)
		bzzt.Vel = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(-1):RadRotate(math.pi * RangeRand(-1, 1) * 0.35) * 15 * RangeRand(0.5, 1.1)
		bzzt.GlobalAccScalar = 1.0;
		bzzt.Lifetime = bzzt.Lifetime * RangeRand(0.2, 1.2) * 1.0;
		MovableMan:AddParticle(bzzt);
	end
	
	if math.random(0, 100) < 50 then
		local buh = CreateMOSParticle("Tiny Smoke Ball 1");
		buh.Pos = self.Pos + Vector(self.Vel.X, self.Vel.Y):SetMagnitude(-1)
		buh.Vel = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(-1):RadRotate(math.pi * RangeRand(-1, 1) * 0.35) * 5 * RangeRand(0.5, 1.1)
		buh.Lifetime = buh.Lifetime * RangeRand(0.6, 1.6) * 0.5;
		MovableMan:AddParticle(buh);
	end

	self.ToDelete = true
end