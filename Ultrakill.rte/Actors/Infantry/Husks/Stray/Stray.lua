--require("AI/NativeHumanAI")   -- or NativeCrabAI or NativeTurretAI

function shutUp(self)
	for i = 1, #self.vo do
		local sound = self.vo[i]
		sound:Stop(-1)
	end
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
	
	self.soundAttack = CreateSoundContainer("Stray Attack", "Ultrakill.rte");
	self.soundHurt = CreateSoundContainer("Stray Hurt", "Ultrakill.rte");
	self.soundDeath = CreateSoundContainer("Stray Death", "Ultrakill.rte");
	
	self.soundAttackRanged = CreateSoundContainer("Stray Attack Ranged", "Ultrakill.rte");
	self.soundAttackRangedPlayed = false
	
	
	self.vo = {self.soundAttack, self.soundHurt, self.soundDeath}
	
	self.lastHealth = self.Health
	
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
	
	self.AI.radar = AIRadar.Create({position = self.Pos, rotation = 0, arc = math.rad(120), distance = 600, steps = 1, stepDeg = 5, team = self.Team})
	
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
	
	self.AI.lookDirection = 0
	
	self.attackSpeed = 1.5
	
	self.attacking = false
	self.attackTimer = Timer()
	self.attackDuration = 1500 / self.attackSpeed
	self.attackWindupDuration = 600 / self.attackSpeed
	self.attackDamageDuration = (self.attackDuration - self.attackWindupDuration) * 0.5 / self.attackSpeed
	self.attackCanDamage = false
	self.attackDamage = 8
	
	self.attackCanInterrupt = false
	
	self.attackDelayTimer = Timer()
	self.attackDelayMin = 650
	self.attackDelayMax = 3000
	self.attackDelay = math.random(self.attackDelayMin, self.attackDelayMax)
	
	self.Frame = math.random(0, self.FrameCount)
end

function Update(self)
	
	local limbs = {self.Head, self.FGLeg, self.BGLeg, self.FGArm, self.BGArm}
	for i, limb in ipairs(limbs) do
		if limb then
			if self.limbWounds[i] and (i == 4 or i == 1) and limb and self.attacking and self.attackCanDamage and self.attackCanInterrupt and limb.WoundCount > self.limbWounds[i] then
				local boom = CreateMOSRotating("Stray Interruption", "Ultrakill.rte")
				boom.Pos = limb.Pos
				MovableMan:AddParticle(boom)
				boom:GibThis()
				
				if UltrakillStyle then
					table.insert(UltrakillStyle.StyleToAdd, {100, "INTERRUPTION", true})
				end
				
				self.attackCanDamage = false
			end
			
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
				local factor = math.min(dif, 50) * 0.7
				self.AngularVel = self.AngularVel + RangeRand(-1, 1) * factor * self.FlipFactor + (self.AngularVel * factor * 0.03)
			end
		end
		
		self.lastHealth = self.Health
	end
	
	-- Look Around
	if self.Head then
		local factor = self.AI.lookDirection
		--self.Head.InheritedRotAngleOffset = math.pi * 0.5
		self:SetAimAngle(math.pi * 0.5 * factor)
	end
	
	-- Drunk
	--if self.Status < Actor.UNSTABLE then
	--	self.AngularVel = self.AngularVel - (0.3 * math.random() - (aimAngle) * 0.1) * self.FlipFactor * TimerMan.DeltaTimeSecs * 5;
	--end
	
	if not self.FGLeg or not self.BGLeg or not self.FGArm or not self.BGArm then
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
		if self.Head and self.FGArm and self.BGArm then
			local atk = ctrl:IsState(Controller.WEAPON_FIRE);
			if atk and self.Status < Actor.UNSTABLE and self.attackDelayTimer:IsPastSimMS(self.attackDelay) then
				if not self.attacking then
					self.attacking = true
					self.attackCanDamage = true
					self.attackTimer:Reset()
					
					self.soundAttackRangedPlayed = false
					
					--self.soundAttack:Play(self.Pos)
				end
			end
			
			if self.attacking then
				local attackAngle = self.Head.RotAngle--self:GetAimAngle(true)
				
				local angleOffset = self.HFlipped and math.pi or 0
				
				attackAngle = attackAngle * self.FlipFactor + angleOffset
				
				local projectileAngle = self.Head.RotAngle
				if not player and self.AI.target then
					local target = MovableMan:FindObjectByUniqueID(self.AI.target)
					if target then
						local dif = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX)
						if self.HFlipped then
							dif = Vector(-dif.X, -dif.Y)
						end
						projectileAngle = dif.AbsRadAngle
					end
				end
				
				ctrl:SetState(Controller.MOVE_LEFT, false)
				ctrl:SetState(Controller.MOVE_RIGHT, false)
				
				if not self.attackTimer:IsPastSimMS(self.attackWindupDuration) then
					local factor = (self.attackTimer.ElapsedSimTimeMS / self.attackWindupDuration)
					
					if factor > 0.5 then
						self.attackCanInterrupt = true
					end
					
					self.FGArm.IdleOffset = Vector(3, -12)
					self.BGArm.IdleOffset = Vector(5, 4)
					
					PrimitiveMan:DrawCircleFillPrimitive(ToArm(self.FGArm).HandPos, math.random(0, 2) + 5 * factor, math.random() < 0.5 and 244 or 13)
					
				elseif not self.attackTimer:IsPastSimMS(self.attackWindupDuration + self.attackDamageDuration) then
					local factor = ((self.attackTimer.ElapsedSimTimeMS - self.attackWindupDuration) / self.attackDamageDuration)
					
					if factor > 0.65 then
						self.attackCanInterrupt = false
					end
					
					self.FGArm.IdleOffset = Vector(3, -12) * (1 - factor) + Vector(15 * self.FlipFactor, 0):RadRotate(attackAngle) * factor
					self.BGArm.IdleOffset = Vector(5, 4) * (1 - factor) + Vector(-5, 11) * factor
					
					PrimitiveMan:DrawCircleFillPrimitive(ToArm(self.FGArm).HandPos, math.random(1, 5) + 6 * (1 - math.sin(factor * math.pi)), math.random() < 0.5 and 244 or 13)
					PrimitiveMan:DrawCircleFillPrimitive(ToArm(self.FGArm).HandPos, 1 + 3 * (1 - math.sin(factor * math.pi)), math.random() < 0.5 and 47 or 86)
					
					if not self.soundAttackRangedPlayed then
						self.soundAttackRangedPlayed = true
						self.soundAttackRanged:Play(self.Pos)
					end
					
				else
					local factor = ((self.attackTimer.ElapsedSimTimeMS - self.attackWindupDuration - self.attackDamageDuration) / (self.attackDuration - self.attackWindupDuration - self.attackDamageDuration))
					
					if self.attackCanDamage then
						local projectile = CreateAEmitter("Particle Hell Ball", "Ultrakill.rte");
						projectile.RotAngle = projectileAngle
						projectile.Vel = Vector(25 * self.FlipFactor, 0):RadRotate(projectile.RotAngle)
						projectile.Pos = ToArm(self.FGArm).HandPos;
						projectile.Team = self.Team -- It doesn't work, somehow
						projectile.IgnoresTeamHits = true;
						MovableMan:AddParticle(projectile);
						
						self.attackCanDamage = false
					end
					
					self.FGArm.IdleOffset = Vector(15 * self.FlipFactor, 0):RadRotate(attackAngle)
					self.BGArm.IdleOffset = Vector(0, 5)
				end
				
				
				if self.attackTimer:IsPastSimMS(self.attackDuration) then
					self.attacking = false
					self.attackDelayTimer:Reset()
					self.attackDelay = math.random(self.attackDelayMin, self.attackDelayMax)
				end
			else
				self.FGArm.IdleOffset = Vector(3, 12)
				self.BGArm.IdleOffset = Vector(3, 12)
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
			local visible = false
			if shape then
				if math.random() < 0.5 then
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
			if self.HFlipped then
				self.AI.lookDirection = -self.AI.lookDirection + math.pi
			end
			
			if not self.attacking then
				
				-- Move
				local input = 0
				if dif.X > 0 then
					input = 1
				elseif dif.X < 0 then
					input = -1
				end
				
				if self.AI.targetIsVisible and dif.Magnitude < 100 and math.abs(dif.Y) < 30 then
					input = input * -1
				elseif not self.AI.targetIsVisible then
					input = input
				end
				
				movementInput = input
				
				if self.AI.targetIsVisible then
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
				self.AI.targetIsVisible = false
				
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
				self.AI.targetIsVisible = false
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

function Destroy(self)
	shutUp(self)
end