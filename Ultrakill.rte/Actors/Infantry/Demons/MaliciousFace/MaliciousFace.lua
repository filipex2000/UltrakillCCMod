
function Create(self)
	
	self.soundDeath = CreateSoundContainer("Malicious Face Death", "Ultrakill.rte");
	self.soundDeathLand = CreateSoundContainer("Malicious Face Death Land", "Ultrakill.rte");
	self.playLandSound = true
	
	self.soundEnrageStart = CreateSoundContainer("Enrage Start", "Ultrakill.rte");
	self.soundEnrageLoop = CreateSoundContainer("Enrage Loop", "Ultrakill.rte");
	self.soundEnrageEnd = CreateSoundContainer("Enrage End", "Ultrakill.rte");
	
	self.soundLaserCharge = CreateSoundContainer("Malicious Face Laser Charge", "Ultrakill.rte");
	self.soundLaserCue = CreateSoundContainer("Malicious Face Laser Cue", "Ultrakill.rte");
	
	self.enraged = false
	
	self.AI = {}
	self.AI.debug = false
	
	self.AI.radar = AIRadar.Create({position = self.Pos, rotation = 0, arc = math.rad(280), distance = 600, steps = 3, stepDeg = 3, team = self.Team})
	
	self.AI.lookDirection = 0
	
	self.AI.targetIsVisible = false
	
	self.AI.target = nil
	self.AI.targetForgetTimer = Timer()
	self.AI.targetForgetDelay = 5000
	
	self.AI.alarmPos = nil
	self.AI.alarmTimer = nil
	self.AI.alarmDuration = 1000
	
	self.AI.calculateShapeTimer = Timer()
	self.AI.calculateShapeDelay = 300
	self.AI.targetShape = nil
	
	self.PreviousFlipFactor = self.FlipFactor
	
	self.attacking = false
	
	self.attackTypeLaserThereshold = 0
	self.attackTypeLaserTheresholdGainPerBurst = 0.15
	self.attackType = 0
	
	self.attackDelayTimer = Timer()
	self.attackDelayMin = 600
	self.attackDelayMax = 700
	self.attackDelay = math.random(self.attackDelayMin, self.attackDelayMax)
	
	self.attackLaser = 0
	self.attackLaserMax = 1
	self.attackLaserCue = true
	self.attackLaserChargeDuration = 2300
	self.attackLaserAngleLock = nil
	
	self.attackSpeed = 0.9
	self.attackSpeedEnrage = 1.3
	
	self.attackTimer = Timer()
	
	self.attackBurst = 0
	
	self.LastPos = Vector(self.Pos.X, self.Pos.Y)
end

function Update(self)
	
	if self.Status == Actor.DEAD or self.Status == Actor.DYING or self.Health < 0 then
		if self.enraged then
			self.soundEnrageEnd:Play(self.Pos)
			self.soundEnrageLoop:Stop(-1)
			self.enraged = false
			
			self.Frame = 0
		end
		
		self.PinStrength = 0
	elseif self.Health < self.MaxHealth * 0.45 then
		if not self.enraged then
			
			if UltrakillStyle then
				table.insert(UltrakillStyle.StyleToAdd, {200, "ENRAGED", false})
			end
			
			self.enraged = true
			self:FlashWhite(500)
			self.soundEnrageStart:Play(self.Pos)
			
			self.attackSpeed = self.attackSpeedEnrage
			self.attackLaserMax = self.attackLaserMax + 1
		end
		
		if self.enraged then
			for i = 1, 3 do
				local glow = CreateMOPixel("Enrage Glow", "Ultrakill.rte");
				glow.Vel = self.Vel
				glow.Pos = self.Pos + Vector(self.Radius * RangeRand(0, 0.5), 0):RadRotate(RangeRand(-2, 2) * math.pi)
				glow.Team = self.Team
				glow.IgnoresTeamHits = true;
				MovableMan:AddParticle(glow);
			end
			
			if self.soundEnrageLoop:IsBeingPlayed() then
				self.soundEnrageLoop.Pos = self.Pos
			else
				self.soundEnrageLoop:Play(self.Pos)
			end
			self.Frame = 1
		end
	elseif self.Health >= self.MaxHealth * 0.45 then -- somehow :O
		if self.enraged then
			self.soundEnrageEnd:Play(self.Pos)
			self.soundEnrageLoop:Stop(-1)
			self.enraged = false
			
			self.Frame = 0
		end
	end
	
	if self.Status == Actor.DEAD or self.Status == Actor.DYING then 
		if not self.dead then
			self.dead = true
			self.soundDeath:Play(self.Pos)
			
			self.Vel = Vector(0, -5)
			self.AngularVel = 0
		end
		self.AngularVel = self.AngularVel * 0.5
		self.GlobalAccScalar = 0.75
		
		self.enraged = false
		self.Frame = 0
		
		return
	end
	
	local ctrl = self:GetController()
	local player = false
	if self:IsPlayerControlled() then
		player = true
	end
	
	if math.random() < 0.3 and self.WoundCount > 0 then
		self:RemoveWounds(1)
	end
	
	--self.Pos = self.Pos + SceneMan:ShortestDistance(self.Pos, self.LastPos, SceneMan.SceneWrapsX) * 0.75
	self.Vel = Vector(0,0)
	self.LastPos = Vector(self.Pos.X, self.Pos.Y)
	
	-- Balance
	local balanceStrength = 0.6
	
	local min_value = -math.pi;
	local max_value = math.pi;
	local value = self.RotAngle - (self.HFlipped and (self.AI.lookDirection + math.pi) or self.AI.lookDirection)
	local result;
	local ret = 0
	
	local range = max_value - min_value;
	if range <= 0 then
		result = min_value;
	else
		ret = (value - min_value) % range;
		if ret < 0 then ret = ret + range end
		result = ret + min_value;
	end
	
	if self.PreviousFlipFactor ~= self.FlipFactor then
		self.RotAngle = self.RotAngle - result
		self.PreviousFlipFactor = self.FlipFactor
		
		self.AngularVel = 0
	else
		self.RotAngle = (self.RotAngle - result * TimerMan.DeltaTimeSecs * 1 * balanceStrength)
		self.AngularVel = (self.AngularVel - result * TimerMan.DeltaTimeSecs * 10 * balanceStrength)
		self.AngularVel = (self.AngularVel) / (1 + TimerMan.DeltaTimeSecs * 1.0 * balanceStrength)-- - self.Vel.X * TimerMan.DeltaTimeSecs * 6
	end
	
	if ctrl then
		
		-- Attack
		local atk = ctrl:IsState(Controller.WEAPON_FIRE);
		if atk and self.attackDelayTimer:IsPastSimMS(self.attackDelay) then
			if not self.attacking then
				self.attacking = true
				self.attackTimer:Reset()
				
				self.attackBurst = 0
				self.attackBurstCount = math.random(3,4)
				
				self.attackLaserCue = true
				self.attackLaserAngleLock = nil
				
				self.attackType = (self.attackLaser > 1 or (self.attackTypeLaserThereshold > 0.5 and math.random() < self.attackTypeLaserThereshold)) and 1 or 0
				if self.attackType == 0 then -- Burst
					self.attackTypeLaserThereshold = self.attackTypeLaserThereshold + self.attackTypeLaserTheresholdGainPerBurst * RangeRand(0.75,1.25)
					self.attackLaser = self.attackLaserMax 
				elseif self.attackType == 1 then -- Explosive laser
					self.attackTypeLaserThereshold = 0
				end
				
			end
		end
		
		if self.attacking then
			local mounthPos = self.Pos + Vector(10 * self.FlipFactor, 12):RadRotate(self.RotAngle)
			
			local projectileAngle = self.RotAngle + (self.HFlipped and (math.pi) or 0)
			if not player and self.AI.target then
				local target = MovableMan:FindObjectByUniqueID(self.AI.target)
				if target then
					local dif = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX)
					projectileAngle = dif.AbsRadAngle
				end
			end
			
			if self.attackType == 0 then -- Burst
				self.RotAngle = self.RotAngle - result
				if self.attackTimer:IsPastSimMS(130 / self.attackSpeed) then
					-- if not player and self.AI.target then
						-- local target = MovableMan:FindObjectByUniqueID(self.AI.target)
						-- if target then
							-- local dif = SceneMan:ShortestDistance(self.Pos, target.Pos + target.Vel * GetPPM() * -0.1, SceneMan.SceneWrapsX)
							-- self.RotAngle = dif.AbsRadAngle
							-- self.RotAngle = (self.HFlipped and (self.RotAngle + math.pi) or self.RotAngle)
						-- end
					-- end
					
					local factor = self.attackBurst / self.attackBurstCount
					
					local projectile = CreateAEmitter("Particle Hell Ball", "Ultrakill.rte");
					projectile.RotAngle = projectileAngle
					projectile.Vel = Vector((12 + 15 * factor) * self.attackSpeed, -3 * self.FlipFactor * (1 - factor)):RadRotate(projectile.RotAngle)
					projectile.Pos = mounthPos - Vector(3, 0):RadRotate(projectile.RotAngle)
					projectile.Team = self.Team
					projectile.IgnoresTeamHits = true;
					MovableMan:AddParticle(projectile);
					
					self.attackBurst = self.attackBurst + 1
					self.attackTimer:Reset()
				end
				
				if self.attackBurst >= self.attackBurstCount then
					self.attacking = false
					self.attackDelayTimer:Reset()
					self.attackDelay = math.random(self.attackDelayMin, self.attackDelayMax) / self.attackSpeed
				end
			elseif self.attackType == 1 then -- Explosive laser
				local factor = (self.attackTimer.ElapsedSimTimeMS / (self.attackLaserChargeDuration / self.attackSpeed))
				
				PrimitiveMan:DrawCircleFillPrimitive(mounthPos, (math.random(0, 2) + 5 * factor) * 1.2, math.random() < 0.5 and 122 or 86)
				
				if self.attackTimer:IsPastSimMS((self.attackLaserChargeDuration - 400) / self.attackSpeed) then
					if self.attackLaserCue then
						self.attackLaserCue = false
						
						self.soundLaserCue.Pitch = 1.5
						self.soundLaserCue:Play(self.Pos)
						self.soundLaserCharge:Stop(-1)
						
						self.attackLaserAngleLock = self.RotAngle
						if not player and self.AI.target then
							local target = MovableMan:FindObjectByUniqueID(self.AI.target)
							if target then
								local dif = SceneMan:ShortestDistance(self.Pos, target.Pos + target.Vel * GetPPM() * 0.3 * math.random(1,3), SceneMan.SceneWrapsX)
								self.attackLaserAngleLock = dif.AbsRadAngle
								self.attackLaserAngleLock = (self.HFlipped and (self.attackLaserAngleLock + math.pi) or self.attackLaserAngleLock)
							end
						end
						
					end
					
					self.AngularVel = 0
					self.RotAngle = self.attackLaserAngleLock
					mounthPos = self.Pos + Vector(10 * self.FlipFactor, 12):RadRotate(self.RotAngle)
					
					PrimitiveMan:DrawCircleFillPrimitive(mounthPos, math.random(8,10), 122)
				else
					if self.soundLaserCharge:IsBeingPlayed() then
						self.soundLaserCharge.Pos = self.Pos
						self.soundLaserCharge.Pitch = 0.5 + 1.5 * factor
					else
						self.soundLaserCharge.Pitch = 1
						self.soundLaserCharge:Play(self.Pos)
					end
				end
				
				if self.attackTimer:IsPastSimMS(self.attackLaserChargeDuration / self.attackSpeed) then
					local projectile = CreateMOSRotating("Malicious Face Laser", "Ultrakill.rte");
					--projectile.RotAngle = self.RotAngle
					--projectile.Vel = Vector(30 * self.FlipFactor, 0):RadRotate(projectile.RotAngle)
					--projectile.Pos = mounthPos
					--projectile.Team = self.Team
					--projectile.IgnoresTeamHits = true;
					--MovableMan:AddParticle(projectile);
					
					projectile.Pos = mounthPos
					projectile.RotAngle = self.RotAngle + math.pi * (-self.FlipFactor + 1) * 0.5
					projectile.Vel = Vector(130 * self.FlipFactor,0):RadRotate(self.RotAngle)
					projectile.Team = self.Team
					projectile.IgnoresTeamHits = true
					MovableMan:AddParticle(projectile);
					
					self.attackTypeLaserThereshold = 0
					
					self.attackLaser = self.attackLaser - 1
					
					self.attacking = false
					self.attackDelayTimer:Reset()
					if self.attackLaser > 0 then
						self.attackDelay = math.random(self.attackDelayMin, self.attackDelayMax) / self.attackSpeed
					else
						self.attackDelay = math.random(self.attackDelayMin, self.attackDelayMax) * 3 / self.attackSpeed
					end
				end
				
			end
		end
	end
end

function Destroy(self)
	self.soundEnrageLoop:Stop(-1)
	self.soundLaserCharge:Stop(-1)
end

function OnCollideWithTerrain(self, terrainID)
	if self.Status == Actor.DEAD or self.Status == Actor.DYING then 
		if self.playLandSound then
			self.playLandSound = false
			self.soundDeathLand:Play(self.Pos)
		end
		
		self.ToSettle = true
		return 
	end
	
	-- Custom move out of terrain script, EXPERIMENTAL
	--PrimitiveMan:DrawCirclePrimitive(self.Pos, self.IndividualRadius, 13);
	local maxi = 8
	for i = 1, maxi do
		local offset = Vector(self.IndividualRadius, 0):RadRotate(((math.pi * 2) / maxi) * i)
		local endPos = self.Pos + offset; -- This value is going to be overriden by function below, this is the end of the ray
		self.ray = SceneMan:CastObstacleRay(self.Pos + offset, offset * -1.0, Vector(0, 0), endPos, 0 , self.Team, 0, 1)
		if self.ray == 0 then
			--self.Pos = self.Pos - offset * 0.1;
			self.Pos = self.Pos - offset * 0.05;
			self.Vel = self.Vel * 0.5;
		end
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, self.Pos - offset, 46);
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, endPos, 116);
	end
	
end

function UpdateAI(self)
	local ctrl = self:GetController()
	
	-- Radar logic
	AIRadar.SetTransform(self.AI.radar, self.Pos, self.RotAngle, self.HFlipped)
	if self:NumberValueExists("Set Target") and self:GetNumberValue("Set Target") ~= -1 then
		self.AI.target = self:GetNumberValue("Set Target")
		self:RemoveNumberValue("Set Target")
	end
	
	if self.AI.target then
		
		local target = MovableMan:FindObjectByUniqueID(self.AI.target)
		if target then
			local dif = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX)
			
			-- Check if visible
			if not self.AI.targetShape or self.AI.calculateShapeTimer:IsPastSimMS(self.AI.calculateShapeDelay) then
				self.AI.targetShape = AIRadar.CalculateActorVisibilityShape(self.Pos, target)
				self.AI.calculateShapeTimer:Reset()
			end
	
			local shape = self.AI.targetShape
			local visible = false
			if shape then
				if math.random() < 0.5 then
					local angle = shape[1]
					local radius = shape[2]
					local center = target.Pos + shape[3]
					--PrimitiveMan:DrawCirclePrimitive(center, radius, 13)
					
					local rayOrigin = self.Pos
					local rayPos = center + Vector(0, radius * RangeRand(-1,1)):RadRotate(angle)
					local rayVec = SceneMan:ShortestDistance(rayOrigin, rayPos, SceneMan.SceneWrapsX)
					
					local terrCheck = SceneMan:CastStrengthRay(rayOrigin, rayVec, 30, Vector(), math.random(6,8), 0, SceneMan.SceneWrapsX);
					if terrCheck == false then
						self.AI.targetForgetTimer:Reset()
						
						visible = true
						self.AI.targetIsVisible = true
					end
					if self.AI.debug then
						PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVec, 122);
					end
					
					if not visible and math.random() < 0.3 then
						self.AI.targetIsVisible = false
					end
				end
			end
			--PrimitiveMan:DrawBoxPrimitive(target.Pos + cornerA, target.Pos + cornerB, 13)
			
			if self.AI.debug then
				local color = 13
				if self.AI.targetIsVisible then
					color = 149
				end
				PrimitiveMan:DrawCirclePrimitive(self.Pos, 5, color)
				PrimitiveMan:DrawCircleFillPrimitive(target.Pos, 2, color)
				
				PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + dif, color);
			end
			
			--
			self.HFlipped = dif.X < 0
			
			self.AI.lookDirection = dif.AbsRadAngle
			--if self.HFlipped then
			--	self.AI.lookDirection = -self.AI.lookDirection + math.pi
			--end
			
			if not self.attacking and self.AI.targetIsVisible then
				ctrl:SetState(Controller.WEAPON_FIRE, true)
			end
			
			if self.AI.targetForgetTimer:IsPastSimMS(self.AI.targetForgetDelay) then
				self.AI.target = nil
			end
		else
			self.AI.target = nil
		end
	else
		self.attacking = false
		self.attackDelayTimer:Reset()
		self.attackDelay = math.random(self.attackDelayMin, self.attackDelayMax)
		self.soundLaserCharge:Stop(-1)
		
		AIRadar.Update(self.AI.radar)
		
		if self.HFlipped then
			self.AI.lookDirection = math.pi
		else
			self.AI.lookDirection = 0
		end
		
		local targets = AIRadar.GetDetectedActorsThisFrame(self.AI.radar) -- Get actors
		if targets and #targets > 0 then
			local target = targets[math.random(1, #targets)] -- Pick random
			if target and target.ClassName ~= "ADoor" then
				self.AI.target = target.UniqueID
				self.AI.targetShape = nil
				self.AI.targetIsVisible = false
				
			end
			
			self.AI.targetForgetTimer:Reset()
		end
		
		-- Debug
		if self.AI.debug then
			AIRadar.DrawDebugVisualization(self.AI.radar)
		end
	end
	--
	
	-- Alarm logic
	-- local alarmPos = self:GetAlarmPoint()
	-- if not alarmPos:IsZero() then
		-- self.AI.alarmPos = Vector(alarmPos.X, alarmPos.Y)
		-- self.AI.alarmTimer = Timer()
	-- end
	
	-- if self.AI.alarmPos and self.AI.alarmTimer then
		-- local dif = SceneMan:ShortestDistance(self.Pos, self.AI.alarmPos, SceneMan.SceneWrapsX)
		
		-- self.HFlipped = dif.X < 0
		
		-- self.AI.lookDirection = dif.AbsRadAngle
		-- --if self.HFlipped then
		-- --	self.AI.lookDirection = -self.AI.lookDirection + math.pi
		-- --end
		
		-- if self.AI.debug then
			-- PrimitiveMan:DrawCirclePrimitive(self.Pos, 5, 86)
			-- PrimitiveMan:DrawCircleFillPrimitive(self.AI.alarmPos, 2, 86)
			
			-- PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + SceneMan:ShortestDistance(self.Pos, self.AI.alarmPos, SceneMan.SceneWrapsX), 86);
		-- end
		
		-- if self.AI.alarmTimer:IsPastSimMS(self.AI.alarmDuration) then
			-- self.AI.alarmPos = nil
			-- self.AI.alarmTimer = nil
		-- end
	-- end
	
end