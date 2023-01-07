--require("AI/NativeHumanAI")   -- or NativeCrabAI or NativeTurretAI

function shutUp(self)
	for i = 1, #self.vo do
		local sound = self.vo[i]
		sound:Stop(-1)
	end
end

function attackDamage(self)
	if not self.attackCanDamage or not self.Head then return end
	self.attackCanDamage = false
	
	local maxi = self.attackDamage
	for i = 1, maxi do
		local factor = ((i / maxi) - 0.5) * 2.0
		local pixel = CreateMOPixel("Particle Filth Teeth", "Ultrakill.rte");
		pixel.Vel = Vector(90 * self.FlipFactor, 0):RadRotate(self.Head.RotAngle + math.pi * 0.3 * factor);
		pixel.Pos = self.Head.Pos;
		pixel.Team = self.Team -- It doesn't work, somehow
		pixel.IgnoresTeamHits = true;
		MovableMan:AddParticle(pixel);
	end
	
	self.Status = Actor.STABLE
	self.Vel = Vector(-self.Vel.X * 0.6, -2)
	
	self.Health = math.min(self.Health + math.random(5, 10), self.MaxHealth)
end

function checkTerrain(self, direction)
	local rayOrigin = self.Pos + Vector(2 * direction, 2)
	local rayVector = Vector(22 * direction, 24)
	
	if self.AI.debug then
		PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVector, 162);
	end
	
	return SceneMan:CastStrengthRay(rayOrigin, rayVector, 30, Vector(), 4, 0, SceneMan.SceneWrapsX);
end

function Create(self)
	
	self.soundAttack = CreateSoundContainer("Filth Attack", "Ultrakill.rte");
	self.soundHurt = CreateSoundContainer("Filth Hurt", "Ultrakill.rte");
	self.soundDeath = CreateSoundContainer("Filth Death", "Ultrakill.rte");
	
	self.vo = {self.soundAttack, self.soundHurt, self.soundDeath}
	
	self.lastHealth = self.Health
	
	self.headAnimTimer = Timer()
	self.headAnimDurationMin = 900
	self.headAnimDurationMax = 1200
	self.headAnimDuration = math.random(self.headAnimDurationMin, self.headAnimDurationMax)
	
	self.Head.GibWoundLimit = self.Head.GibWoundLimit + math.random(1,5)
	
	self.dead = false
	
	self.limbWounds = {}
	
	self.AI = {}
	self.AI.debug = false
	-- States:
	-- -1 = Attacking
	-- 0 = Idle
	-- 1 = Walking Around
	self.AI.state = 0
	
	self.AI.wanderTimer = Timer()
	self.AI.wanderDelayMin = 1000
	self.AI.wanderDelayMax = 3000
	self.AI.wanderDelay = math.random(self.AI.wanderDelayMin, self.AI.wanderDelayMax)
	
	self.AI.radar = AIRadar.Create({position = self.Pos, rotation = 0, arc = math.rad(120), distance = 600, steps = 1, stepDeg = 10, team = self.Team})
	
	self.AI.target = nil
	self.AI.targetForgetTimer = Timer()
	self.AI.targetForgetDelay = 5000
	
	self.AI.alarmPos = nil
	self.AI.alarmTimer = nil
	self.AI.alarmDuration = 1000
	
	self.AI.calculateShapeTimer = Timer()
	self.AI.calculateShapeDelay = 300
	self.AI.targetShape = nil
	
	self.AI.lookDirection = 0
	
	
	self.attacking = false
	self.attackTimer = Timer()
	self.attackDuration = 500
	self.attackWindupDuration = 150
	self.attackDamageDuration = (self.attackDuration - self.attackWindupDuration) * 0.5
	self.attackCanDamage = false
	self.attackDamage = 8
	
	self.attackDelayTimer = Timer()
	self.attackDelay = 650
	
	self.Frame = math.random(0, self.FrameCount)
	
	self.Head.Scale = 0.9
end

function Update(self)
	
	local limbs = {self.Head, self.FGLeg, self.BGLeg}
	for i, limb in ipairs(limbs) do
		if limb then
			if self.limbWounds[i] and self.Health < 0 and limb and limb.WoundCount > self.limbWounds[i] then
				if i == 1 then
					self:SetNumberValue("UltrakillHeadshot", 1)
					self:SetNumberValue("UltrakillLimb", 0)
				else
					
					self:SetNumberValue("UltrakillLimb", 1)
				end
			end
			self.limbWounds[i] = limb and limb.WoundCount or nil
		end
	end
	
	if self.Status == Actor.DEAD or self.Status == Actor.DYING then 
		if not self.dead then
			self.dead = true
			shutUp(self)
			self.soundDeath.Pitch = 1
			self.soundDeath:Play(self.Pos)
			
			if self.Vel.Magnitude < 9 then
				self.Vel = self.Vel + Vector(RangeRand(-1, 1) * 2, RangeRand(-0.5, -1) * 7)
			else
				if self.Head then 
					self:RemoveAttachable(self.Head, true, true)
				end
				self.GibImpulseLimit = 80
			end
		end
		
		if self.Head then
			self.Head.Frame = 8
			
			
			if self.Head.WoundCount >= self.Head.GibWoundLimit - 2 then
				self:SetNumberValue("UltrakillHeadshot", 1)
				self:SetNumberValue("UltrakillLimb", 0)
				if math.random(0, 1) < 1 then
				local head = self.Head
				self:RemoveAttachable(self.Head, true, true)
				head.Vel = self.Vel + Vector(RangeRand(-1, 1) * 2, RangeRand(-0.5, -1) * 7)
				
				head.GibImpulseLimit = 300
				end
			end
		end
		
		return
	end
	
	local ctrl = self:GetController()
	local player = false
	if self:IsPlayerControlled() then
		player = true
	end
	
	local aimAngle = self:GetAimAngle(false);
	
	-- Epic hurt effects
	if self.lastHealth > self.Health then
		local dif = math.abs(self.lastHealth - self.Health)
		
		shutUp(self)
		--if dif > 2 and not self.soundHurt:IsBeingPlayed() then
		if dif > 2 then
			self.soundHurt.Pitch = 1
			self.soundHurt:Play(self.Pos)
			
			-- Stagger
			if self.Status < Actor.UNSTABLE then
				local factor = math.min(dif, 50) * 1.0
				self.AngularVel = self.AngularVel + RangeRand(-1, 1) * factor * self.FlipFactor + (self.AngularVel * factor * 0.03)
			end
		end
		
		self.lastHealth = self.Health
	end
	
	-- Drunk
	--if self.Status < Actor.UNSTABLE then
	--	self.AngularVel = self.AngularVel - (0.3 * math.random() - (aimAngle) * 0.1) * self.FlipFactor * TimerMan.DeltaTimeSecs * 5;
	--end
	
	
	-- Epic head effects
	if self.Head then
		if self.headAnimTimer:IsPastSimMS(self.headAnimDuration) then
			self.headAnimTimer:Reset()
			self.headAnimDuration = math.random(self.headAnimDurationMin, self.headAnimDurationMax)
		end
		
		local factor = self.AI.lookDirection + math.sin(self.Age * 0.01 + self.UniqueID) * 0.05 + math.sin(self.Age * 0.002 + 2) * 0.1 + math.sin(self.Age * 0.015 - 3 - self.UniqueID) * 0.05 + math.sin(self.Age * 0.005 + 6) * 0.075 * 0.05 + math.sin(self.Age * 0.001 + 15 + self.UniqueID) * 0.3
		--self.Head.InheritedRotAngleOffset = math.pi * 0.5
		self:SetAimAngle(math.pi * 0.5 * factor)
		
		local factor = self.headAnimTimer.ElapsedSimTimeMS / self.headAnimDuration
		self.Head.Frame = math.floor(6 * factor)
	end
	
	if not self.FGLeg or not self.BGLeg then
		self.Health = self.Health - 5
		if self:GetNumberValue("UltrakillHeadshot") ~= 1 then
			self:SetNumberValue("UltrakillLimb", 1)
		else
			self:SetNumberValue("UltrakillLimb", 0)
		end
	end
	
	-- Controller and AI
	if ctrl then
		--if player then -- Player
			
		--else -- AI
		--	ctrl:SetState(Controller.BODY_CROUCH, false)
		--end
		
		-- Attack
		if self.Head then
			local atk = ctrl:IsState(Controller.WEAPON_FIRE);
			if atk and self.Status < Actor.UNSTABLE and self.attackDelayTimer:IsPastSimMS(self.attackDelay) then
				if not self.attacking then
					self.attacking = true
					self.attackCanDamage = true
					self.attackTimer:Reset()
					
					self.soundAttack:Play(self.Pos)
				end
			end
			
			if self.attacking then
				ctrl:SetState(Controller.MOVE_LEFT, false)
				ctrl:SetState(Controller.MOVE_RIGHT, false)
				
				local biting = true
				if not self.attackTimer:IsPastSimMS(self.attackWindupDuration) then
					local factor = (self.attackTimer.ElapsedSimTimeMS / self.attackWindupDuration)
					
					self.Vel = Vector(self.Vel.X, self.Vel.Y) * 0.99
					
					self.Status = Actor.STABLE
					
					self.Head.Frame = math.floor(7 + 2 * factor + 0.5)
					biting = false
				elseif not self.attackTimer:IsPastSimMS(self.attackWindupDuration + self.attackDamageDuration) then
					local factor = ((self.attackTimer.ElapsedSimTimeMS - self.attackWindupDuration) / self.attackDamageDuration)
					
					self.Status = Actor.UNSTABLE
					
					self.Head.Frame = math.floor(9 + 4 * factor + 0.5)
					
					local factorVel = math.sin(factor * math.pi * 0.5)
					local factorUpward = -(math.sin(factor * math.pi) - 0.25)
					self.Vel = Vector(self.FlipFactor * 10 * factorVel, 2 * factorUpward)
					self.Pos = self.Pos + Vector(self.Vel.X, self.Vel.Y) * GetPPM() * TimerMan.DeltaTimeSecs
					
					self.RotAngle = math.pi * -0.4 * math.sqrt(math.sin(factor * math.pi)) * self.FlipFactor
					self.Head.RotAngle = 0
				else
					local factor = ((self.attackTimer.ElapsedSimTimeMS - self.attackWindupDuration - self.attackDamageDuration) / (self.attackDuration - self.attackWindupDuration - self.attackDamageDuration))
					
					self.Vel = Vector(self.Vel.X, self.Vel.Y) * 0.97
					
					self.Status = Actor.STABLE
					
					self.Head.Frame = math.floor(13 + 3 * factor + 0.5)
				end
				
				if biting then
					if self.attackCanDamage then
												
						local rayOrigin = self.Head.Pos
						local rayVec = Vector(self.Vel.X,self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame + self.Head.IndividualRadius) * 2.0;
						local moCheck = SceneMan:CastMORay(rayOrigin, rayVec, self.Head.ID, self.Team, 0, false, 1); -- Raycast
						if moCheck ~= 255 then
							attackDamage(self)
						end
					end
				end
				
				if self.attackTimer:IsPastSimMS(self.attackDuration) then
					self.attacking = false
					self.attackDelayTimer:Reset()
				end
			end
		end
		
	end
	
end

function UpdateAI(self)
	local ctrl = self:GetController()
	
	if not self.Head then
		return
	end
	
	-- Misc
	local movementInput = 0
	
	ctrl:SetState(Controller.BODY_CROUCH, false)
	
	-- Radar logic
	AIRadar.SetTransform(self.AI.radar, self.Head.Pos, self.Head.RotAngle, self.HFlipped)
	if self:NumberValueExists("Set Target") and self:GetNumberValue("Set Target") ~= -1 then
		self.AI.target = self:GetNumberValue("Set Target")
		self:RemoveNumberValue("Set Target")
	end
	
	if self.AI.target then
		self:SetNumberValue("Husk Target Found", -1)
		self.AI.state = -1
		
		local target = MovableMan:FindObjectByUniqueID(self.AI.target)
		if target then
			local dif = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX)
			
			-- Check if visible
			if not self.AI.targetShape or self.AI.calculateShapeTimer:IsPastSimMS(self.AI.calculateShapeDelay) then
				self.AI.targetShape = AIRadar.CalculateActorVisibilityShape(self.Head.Pos, target)
				self.AI.calculateShapeTimer:Reset()
			end
	
			local shape = self.AI.targetShape
			if shape and math.random() < 0.5 then
				local angle = shape[1]
				local radius = shape[2]
				local center = target.Pos + shape[3]
				--PrimitiveMan:DrawCirclePrimitive(center, radius, 13)
				
				local rayOrigin = self.Head.Pos
				local rayPos = center + Vector(0, radius * RangeRand(-1,1)):RadRotate(angle)
				local rayVec = SceneMan:ShortestDistance(rayOrigin, rayPos, SceneMan.SceneWrapsX)
				
				local terrCheck = SceneMan:CastStrengthRay(rayOrigin, rayVec, 30, Vector(), math.random(6,8), 0, SceneMan.SceneWrapsX);
				if terrCheck == false then
					self.AI.targetForgetTimer:Reset()
				end
				if self.AI.debug then
					PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVec, 122);
				end
			end
			--PrimitiveMan:DrawBoxPrimitive(target.Pos + cornerA, target.Pos + cornerB, 13)
			
			if self.AI.debug then
				PrimitiveMan:DrawCirclePrimitive(self.Pos, 5, 13)
				PrimitiveMan:DrawCircleFillPrimitive(target.Pos, 2, 13)
				
				PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + dif, 13);
			end
			
			if not self.attacking then
				self.HFlipped = dif.X < 0
				
				self.AI.lookDirection = dif.AbsRadAngle
				if self.HFlipped then
					self.AI.lookDirection = -self.AI.lookDirection + math.pi
				end
				
				if math.random() < 0.01 then
					ctrl:SetState(Controller.BODY_JUMP, true)
					ctrl:SetState(Controller.BODY_JUMPSTART, true)
				end
				
				-- Move
				if dif.X > 0 then
					movementInput = 1
				elseif dif.X < 0 then
					movementInput = -1
				end
				
				if dif.Magnitude < 85 + math.random(-5,40) then
					ctrl:SetState(Controller.WEAPON_FIRE, true)
				end
			end
			
			if self.AI.targetForgetTimer:IsPastSimMS(self.AI.targetForgetDelay) then
				self.AI.target = nil
			end
		else
			self.AI.target = nil
		end
	else
		
		AIRadar.Update(self.AI.radar)
		
		if self.AI.wanderTimer:IsPastSimMS(self.AI.wanderDelay) then
			self.AI.wanderDelay = math.random(self.AI.wanderDelayMin, self.AI.wanderDelayMax)
			self.AI.wanderTimer:Reset()
			
			self.AI.state = math.random(0,1)
			
			self.HFlipped = math.random(0,1) < 1
		end
		
		--if self.AI.state == 0 then
			-- Stand still
		--elseif self.AI.state == 1 then
		if self.AI.state == 1 then
			-- Move Aroun
			movementInput = self.FlipFactor
		end
		
		self.AI.lookDirection = 0
		
		local targets = AIRadar.GetDetectedActorsThisFrame(self.AI.radar) -- Get actors
		if targets and #targets > 0 then
			local target = targets[math.random(1, #targets)] -- Pick random
			if target and target.ClassName ~= "ADoor" then
				self.AI.target = target.UniqueID
				self.AI.targetShape = nil
				
				-- Call others!
				-- local call = false
				for actor in MovableMan.Actors do
					if actor.Team == self.Team then
						local dif = SceneMan:ShortestDistance(self.Pos, actor.Pos, true);
						if dif.Magnitude < 800 then
							local terrainCheck = SceneMan:CastStrengthRay(self.Pos, dif, 50, Vector(), 4, 0, SceneMan.SceneWrapsX)
							if not terrainCheck then
								actor:SetNumberValue("Husk Target Found", self.AI.target)
								-- call = true
							else
								if IsAHuman(actor) and ToAHuman(actor).Head then -- if it is a human check for head
									dif = SceneMan:ShortestDistance(self.Pos, ToAHuman(actor).Head.Pos, true);
									
									terrainCheck = SceneMan:CastStrengthRay(self.Pos, dif, 50, Vector(), 4, 0, SceneMan.SceneWrapsX)
									if not terrainCheck then		
										actor:SetNumberValue("Husk Target Found", self.AI.target)
										-- call = true
									end
								end
								
							end
						end
					end
				end
				
				-- if call then -- YAHH
					-- self.soundDeath.Pitch = 1.2
					-- self.soundDeath:Play(self.Pos)
				-- end
			end
			
			self.AI.targetForgetTimer:Reset()
		end
		
		if not self.AI.target then
			if self:NumberValueExists("Husk Target Found") and self:GetNumberValue("Husk Target Found") ~= -1 then
				self.AI.target = self:GetNumberValue("Husk Target Found")
				self.AI.targetShape = nil
				self:SetNumberValue("Husk Target Found", -1)
				
				-- self.soundHurt.Pitch = 1.2
				-- self.soundHurt:Play(self.Pos)
			end
		end
		
		-- Debug
		if self.AI.debug then
			AIRadar.DrawDebugVisualization(self.AI.radar)
		end
	end
	--
	
	-- Alarm logic
	local alarmPos = self:GetAlarmPoint()
	if not alarmPos:IsZero() then
		self.AI.alarmPos = Vector(alarmPos.X, alarmPos.Y)
		self.AI.alarmTimer = Timer()
		
		local dif = SceneMan:ShortestDistance(self.Pos, self.AI.alarmPos, SceneMan.SceneWrapsX)
		if dif.X > 0 then
			movementInput = 1
		elseif dif.X < 0 then
			movementInput = -1
		end
	end
	
	if self.AI.alarmPos and self.AI.alarmTimer then
		local dif = SceneMan:ShortestDistance(self.Pos, self.AI.alarmPos, SceneMan.SceneWrapsX)
		
		self.HFlipped = dif.X < 0
		
		self.AI.lookDirection = dif.AbsRadAngle
		if self.HFlipped then
			self.AI.lookDirection = -self.AI.lookDirection + math.pi
		end
		
		if self.AI.debug then
			PrimitiveMan:DrawCirclePrimitive(self.Pos, 5, 86)
			PrimitiveMan:DrawCircleFillPrimitive(self.AI.alarmPos, 2, 86)
			
			PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + SceneMan:ShortestDistance(self.Pos, self.AI.alarmPos, SceneMan.SceneWrapsX), 86);
		end
		
		if self.AI.alarmTimer:IsPastSimMS(self.AI.alarmDuration) then
			self.AI.alarmPos = nil
			self.AI.alarmTimer = nil
		end
	end
	--
	
	-- Movement
	if movementInput ~= 0 then
		
		if self.FlipFactor ~= movementInput then
			self.HFlipped = true
		end
		
		if checkTerrain(self, movementInput) then
			if movementInput == 1 then
				ctrl:SetState(Controller.MOVE_RIGHT, true)
			elseif movementInput == -1 then
				ctrl:SetState(Controller.MOVE_LEFT, true)
			end
		end
		
	end
	
	--if self.AI.debug then -- Visualize Stuff
	--end
end

function OnCollideWithTerrain(self, terrainID)
	if self.attacking then
		self.attacking = false
		self.soundAttack:Stop()
		self.attackDelayTimer:Reset()
	end
end

function OnCollideWithMO(self, collidedMO, collidedRootMO)
	if self.attacking then
		self.attacking = false
		--self.soundAttack:Stop()
		self.attackDelayTimer:Reset()
		
		attackDamage(self)
	end
end

function Destroy(self)
	shutUp(self)
end