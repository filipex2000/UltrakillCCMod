
function Create(self)
	self.projectileUID = self:GetNumberValue("Parry UID")
	
	self.smokeTrailLifeTime = self:NumberValueExists("SmokeTrailLifeTime") and self:GetNumberValue("SmokeTrailLifeTime") or 150;
	self.smokeTrailIndividualRadius = self:NumberValueExists("SmokeTrailIndividualRadius") and self:GetNumberValue("SmokeTrailIndividualRadius") or ToMOSprite(self):GetSpriteHeight() * 0.5;
	self.smokeTrailTwirl = self:NumberValueExists("SmokeTrailTwirl") and self:GetNumberValue("SmokeTrailTwirl") or 5;
	self.smokeTwirlCounter = math.random() < 0.5 and math.pi or 0;
end

function Update(self)
	
	local explode = false
	if self.projectileUID then
		local projectile = MovableMan:FindObjectByUniqueID(self.projectileUID)
		if projectile then
			self.Pos = projectile.Pos
			
			if projectile.Vel.Magnitude > 3 then
				local effect;
				local offset = projectile.Vel * rte.PxTravelledPerFrame;	--The effect will be created the next frame so move it one frame backwards towards the barrel
				
				local trailLength = math.floor(offset.Magnitude * 0.5 - 1);
				for i = 1, trailLength do
					local effect = CreateMOSParticle("Flame Smoke 1 Micro", "Base.rte");
					if effect then
						effect.Pos = projectile.Pos - (offset * i/trailLength) + Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * self.smokeTrailIndividualRadius;
						effect.Vel = projectile.Vel * RangeRand(0.75, 1);
						effect.Lifetime = self.smokeTrailLifeTime * RangeRand(0.5, 1);
					
						if self.smokeTrailTwirl > 0 then
							effect.AirResistance = effect.AirResistance * RangeRand(0.9, 1);
							effect.GlobalAccScalar = effect.GlobalAccScalar * math.random();

							effect.Pos = projectile.Pos - offset + (offset * i/trailLength);
							effect.Vel = projectile.Vel + Vector(0, math.sin(self.smokeTwirlCounter) * self.smokeTrailTwirl + RangeRand(-0.1, 0.1)):RadRotate(projectile.Vel.AbsRadAngle);
							
							self.smokeTwirlCounter = self.smokeTwirlCounter + RangeRand(-0.2, 0.4);
						end
						MovableMan:AddParticle(effect);
					end
				end
			end
			
			if projectile.HitWhatMOID ~= 255 or projectile.HitWhatTerrMaterial ~= 0 then
				explode = true
			end
		else
			explode = true
		end
	else
		self.ToDelete = true
	end
	
	if explode then
		local boom = CreateMOSRotating("V1 Punch Parry Explosion", "Ultrakill.rte")
		boom.Pos = self.Pos
		MovableMan:AddParticle(boom)
		boom:GibThis()
		
		self.ToDelete = true
	end
end