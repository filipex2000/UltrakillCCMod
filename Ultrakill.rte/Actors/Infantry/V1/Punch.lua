
function Create(self)
	self.punched = false
	
	self.punchPos = nil
	self.punchRotAngle = nil
	
	self.deflectDistance = 20
	
	self.soundPunchHit = CreateSoundContainer("V1 Punch Hit", "Ultrakill.rte");
	self.soundPunchParry = CreateSoundContainer("V1 Punch Parry", "Ultrakill.rte");
end

function Update(self)
	if self.punchPos then
		self.Pos = self.punchPos
		self.Vel = Vector(0,0)
	end
	if self.punchRotAngle then
		self.RotAngle = self.punchRotAngle
	end
	
	if self.punched then
		self.HitsMOs = false
		self.GetsHitByMOs = false
	else
		local deflectRange = self.deflectDistance * (1.0 - 0.6 * self.Age / self.Lifetime)
		--PrimitiveMan:DrawCirclePrimitive(self.Pos, deflectRange, 13)
		
		local parried = false
		local explosiveParry = true
		local projectileBoost = false -- Parry your own projectile
		
		-- Check particles
		for mo in MovableMan.Particles do
			if mo and mo.UniqueID ~= self.UniqueID and mo.HitsMOs == true then-- and mo.Team ~= team then 
				local earlyParryRange = 40
				local earlyParryAge = 70
				if (mo.ClassName == "MOPixel" or mo.ClassName == "MOParticle") then
					local kilohurts = (mo.Mass * mo.Sharpness * math.pow(mo.Vel.Magnitude, 2)) * 0.001
					if mo.Lifetime > 250 and kilohurts > 3 then
						--PrimitiveMan:DrawCirclePrimitive(mo.Pos, 1 + (mo.Age <= earlyParryAge and earlyParryRange or 0), 5)
						
						local distance = SceneMan:ShortestDistance(self.Pos, mo.Pos + mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs * (mo.Age <= earlyParryAge and -1 or 1), SceneMan.SceneWrapsX).Magnitude - (mo.Age <= earlyParryAge and earlyParryRange or 0)
						if distance < (self.deflectDistance + math.random(-5,5)) then
							
							mo.Team = self.Team
							mo.IgnoresTeamHits = true
							mo.Vel = Vector(math.max(mo.Vel.Magnitude * 1.5, self.Vel.Magnitude), 0):RadRotate(self.Vel.AbsRadAngle)
							mo.Lifetime = mo.Lifetime * 1.5
							mo.WoundDamageMultiplier = mo.WoundDamageMultiplier * 1.5
							
							if explosiveParry then
								local boomboom = CreateMOSRotating("V1 Punch Parry Explosive Handler", "Ultrakill.rte")
								boomboom:SetNumberValue("Parry UID", mo.UniqueID)
								boomboom.Pos = self.Pos
								MovableMan:AddParticle(boomboom)
								explosiveParry = false
							end
							
							if mo.Team == self.Team then
								projectileBoost = true
							end
							
							parried = true
						end
					end
				elseif (string.find(mo.PresetName, "Grenade") or string.find(mo.PresetName, "Bomb") or string.find(mo.PresetName, "Projectile") or string.find(mo.PresetName, "Particle") or string.find(mo.PresetName, "Slugger") or string.find(mo.PresetName, "Bullet") or string.find(mo.PresetName, "Arrow") or string.find(mo.PresetName, "Rocket") or string.find(mo.PresetName, "Homing") or string.find(mo.PresetName, "Missle") or string.find(mo.PresetName, "Hell Ball") or string.find(mo.PresetName, "Core Charge")) then
					if mo.ClassName == "MOSRotating" then
						mo = ToMOSRotating(mo)
					end
					if mo.ClassName == "Actor" then
						mo = ToActor(mo)
					end
					if mo.ClassName == "AEmitter" then
						mo = ToAEmitter(mo)
					end
					
					earlyParryRange = earlyParryRange * (self.Team == mo.Team and 1 or 0.7) * 0.5
					
					--PrimitiveMan:DrawCirclePrimitive(mo.Pos, mo.Radius, 5)
					local distance = SceneMan:ShortestDistance(self.Pos, mo.Pos + mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs * (mo.Age <= earlyParryAge and -1 or 1), SceneMan.SceneWrapsX).Magnitude - mo.Radius - (mo.Age <= earlyParryAge and earlyParryRange or 0)
					if distance < (self.deflectDistance + math.random(-5,5)) then
						
						mo.Team = self.Team
						mo.IgnoresTeamHits = true
						mo.Vel = Vector(math.max(mo.Vel.Magnitude * 1.5, self.Vel.Magnitude), 0):RadRotate(self.Vel.AbsRadAngle)
						mo.Lifetime = mo.Lifetime * 1.5
						
						if explosiveParry then
							local boomboom = CreateMOSRotating("V1 Punch Parry Explosive Handler", "Ultrakill.rte")
							boomboom:SetNumberValue("Parry UID", mo.UniqueID)
							boomboom.Pos = self.Pos
							MovableMan:AddParticle(boomboom)
							explosiveParry = false
							
							if mo.Team == self.Team then
								projectileBoost = true
							end
						end
						
						if not parried and string.find(mo.PresetName, "Hell Ball") then -- Parry heal!
							if self:NumberValueExists("Parent") then
								local UID = self:GetNumberValue("Parent")
								local parent = MovableMan:FindObjectByUniqueID(UID)
								if parent and IsActor(parent) then
									parent = ToActor(parent)
									parent.Health = math.min(parent.Health + 25, parent.MaxHealth)
								end
							end
						end
						
						parried = true
					end
				end
			end
		end
		
		if parried then
			self.soundPunchParry:Play(self.Pos)
			self.punched = true
			
			if ToGameActivity(ActivityMan:GetActivity()).PresetName == "ULTRAKILL: INFINITE HYPERDEATH" then
				TimerMan.TimeScale = RangeRand(0.5, 0.6)
			end
			
			if UltrakillStyle then
				if projectileBoost then
					table.insert(UltrakillStyle.StyleToAdd, {120, "PROJECTILE BOOST", true})
				else
					table.insert(UltrakillStyle.StyleToAdd, {100, "PARRY", true})
				end
			end
			
			self.punchRotAngle = self.RotAngle
		end
	end
end

function OnCollideWithMO(self, collidedMO, collidedRootMO)
	if not collidedMO then return end
	
	if not self.punched then
		self.punched = true
		
		if collidedRootMO and IsActor(collidedRootMO) then
			local actor = ToActor(collidedRootMO)
			actor:SetNumberValue("UltrakillPunched", actor.Age)
			actor.Health = actor.Health - (1200 * actor.DamageMultiplier) / (actor.Mass * 0.5 + actor.Material.StructuralIntegrity * 0.75)
			--
			if actor:NumberValueExists("Big") and UltrakillStyle then
				table.insert(UltrakillStyle.StyleToAdd, {15, "DISRESPECT", false})
			end
		end
		
		if IsMOSRotating(collidedMO) then
			local mo = ToMOSRotating(collidedMO)
			
			local woundName = mo:GetEntryWoundPresetName()
			if woundName then
				for i = 1, math.random(3,4) do
					local wound = CreateAEmitter(woundName)
					if wound then
						mo:AddWound(wound, Vector(0,0), true)
					else
						break
					end
				end
			end
		end
		
		-- if collidedRootMO.UniqueID == collidedMO.UniqueID and collidedMO.ClassName ~= "MOPixel" and collidedMO.ClassName ~= "MOSParticle" and (string.find(collidedMO.PresetName, "Projectile") or string.find(collidedMO.PresetName, "Bullet") or string.find(collidedMO.PresetName, "Arrow") or string.find(collidedMO.PresetName, "Rocket") or string.find(collidedMO.PresetName, "Homing") or string.find(collidedMO.PresetName, "Missle") or string.find(collidedMO.PresetName, "Hell Ball")) then
			-- self.soundPunchParry:Play(self.Pos)
			
			-- local mo = ToMOSRotating(collidedMO)
			-- --mo:SetNumberValue("Parried", 1)
			-- --mo.Team = self.Team
			-- --mo.Vel = Vector(mo.Vel.Magnitude, 0):RadRotate(self.Vel.AbsRadAngle)
			
			-- -- local parriedParticle = ToMOSRotating(mo:Clone())
			-- -- parriedParticle.Pos = mo.Pos
			-- -- parriedParticle.Vel = Vector(mo.Vel.Magnitude, 0):RadRotate(self.Vel.AbsRadAngle)
			-- -- parriedParticle.Team = self.Team
			-- -- parriedParticle.IgnoresTeamHits = true
			-- --MovableMan:AddParticle(ToMovableObject(parriedParticle))
			
			-- --mo.Pos = Vector(-100,-300) -- yes
			-- --mo.ToDelete = true
			
			-- if string.find(mo.PresetName, "Hell Ball") then -- Parry heal!
				-- if self:NumberValueExists("Parent") then
					-- local UID = self:GetNumberValue("Parent")
					-- local parent = MovableMan:FindObjectByUniqueID(UID)
					-- if parent and IsActor(parent) then
						-- parent = ToActor(parent)
						-- parent.Health = math.min(parent.Health + 25, parent.MaxHealth)
					-- end
				-- end
			-- end
		-- else
			-- self.soundPunchHit:Play(self.Pos)
		-- end
		
		self.soundPunchHit:Play(self.Pos)
		self.punchRotAngle = self.RotAngle
	end
end

function OnCollideWithTerrain(self, terrainID)
	if not self.punched then
		self.punched = true
		self.soundPunchHit:Play(self.Pos)
		
		self.punchPos = Vector(self.Pos.X, self.Pos.Y)
		self.punchRotAngle = self.RotAngle
	end
end