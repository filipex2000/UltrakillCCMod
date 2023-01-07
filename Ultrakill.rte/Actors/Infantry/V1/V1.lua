
function mathSign(x)
   if x<0 then
     return -1
   elseif x>0 then
     return 1
   else
     return 0
   end
end

-- Huge thanks to SunoMikey and his awesome IK code!
function calcIK(l1, l2, point)
	point = Vector(point.X, point.Y):SetMagnitude(math.min(point.Magnitude, l1 + l2 - 0.001))
	
	local q1, q2 = 0
	local x = point.X
	local y = point.Y
	
	q2 = math.acos((x*x + y*y - l1*l1 - l2*l2)/(2 * l1 * l2))
	q1 = math.atan2(y, x) - math.atan2((l2 * math.sin(q2)), (l1 + l2 * math.cos(q2)))
	
	return {q1, q2}
end

function getPathAnimationVector(animation, factor) -- factor goes form 0 to 1
	if factor < 0 then
		factor = 1 - abs(factor)
	end
	
	local length = #animation
	--local factor = self.runCycleTimer.ElapsedSimTimeMS / self.runCycleDuration
	local factorFract = math.fmod(factor * length, 1)
	factorFract = math.min(factorFract, 1)
	factorFract = math.max(factorFract, 0)
	
	local segmentIndex = math.max(math.min(math.ceil(length * factor), length), 1)
	local segmentNextIndex = (segmentIndex) % (length) + 1
	
	local segment = Vector(animation[segmentIndex][1], animation[segmentIndex][2])
	local segmentNext = Vector(animation[segmentNextIndex][1], animation[segmentNextIndex][2])
	
	return ((segmentNext) + (segment - segmentNext) * (1 - factorFract))
end

function consumeBlood(self)
	if self.dead then
		return
	end
	-- for mo in MovableMan.AddedParticles do
		-- if mo.PresetName == "None" or (mo.ClassName == "MOPixel" and string.find(mo.PresetName, "Blood") and not string.find(mo.PresetName, "Stale")) then
			-- self.bloodParticles[mo.UniqueID] = mo
		-- end
	-- end
	
	-- PrimitiveMan:DrawCirclePrimitive(self.Pos, self.Radius, 13)
	-- for uniqueID, mo in pairs(self.bloodParticles) do
		-- local mo = MovableMan:FindObjectByUniqueID(uniqueID)
		-- if mo then
			-- if mo.PresetName == "None" then
				-- print("AAAAAA")
			-- end
			-- local distance = SceneMan:ShortestDistance(self.Pos, mo.Pos + mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs, SceneMan.SceneWrapsX).Magnitude
			
			-- PrimitiveMan:DrawCirclePrimitive(mo.Pos, 1, 5)
			-- if distance < self.Radius then
				-- mo.ToDelete = true
				-- heal = heal + 1
				-- self.bloodParticles[uniqueID] = nil
			-- end
		-- else
			-- self.bloodParticles[uniqueID] = nil
		-- end
	-- end
	
	local heal = 0
	local needHealing = self.Health < (self.MaxHealth - self.hardDamage)
	if needHealing then
		local i = 0
		local maxi = 120
		for mo in MovableMan.Particles do
			if i >= maxi then
				break
			end
			
			--if (mo.ClassName == "MOPixel" and string.find(mo.PresetName, "Blood") and not string.find(mo.PresetName, "Stale")) then
			if
			mo.ClassName == "MOPixel" and (
			mo.PresetName == "Drop Blood" or
			mo.PresetName == "Blood" or
			mo.PresetName == "Blood Liquid" or
			mo.PresetName == "Blood Normal" or
			mo.PresetName == "Blood Sticky"
			)
			then
				local diff = SceneMan:ShortestDistance(self.Pos, mo.Pos + mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs, SceneMan.SceneWrapsX)
				local distance = diff.X * diff.X + diff.Y * diff.Y -- Performance friendly!
				
				--PrimitiveMan:DrawCirclePrimitive(mo.Pos, 1, 5)
				local rand = ((mo.UniqueID * 2) % 10) / 10
				local bursting = mo.Age < 300 and math.random(0, 100) < 50
				
				local radius = self.Radius * self.Radius
				
				if mo.Age < 2000 and distance < (radius * 16.0 * (bursting and 3.0 or 1.0)) then
					i = i + 1
					local factor = math.max((1000 - mo.Age) / 500, 0)
					mo.Vel = mo.Vel - (Vector(diff.X, diff.Y):SetMagnitude(distance)):RadRotate(RangeRand(-1, 1) * math.rad(20)) * TimerMan.DeltaTimeSecs * 0.002 * (bursting and 6.0 or 1.0) * (1 + rand) * factor
					mo.Vel = mo.Vel - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs / (1 + distance * 0.001) * factor
					if distance < (radius * 0.4) then
						mo.ToDelete = true
						heal = heal + RangeRand(0.5,1.1) * (0.5 + factor) / 1.5 * 1.05-- * 0.7
					end
				end
			end
		end
		
	end
	
	self.healthGained = self.healthGained + math.floor(heal)
	self.Health = math.min(self.Health + heal, self.MaxHealth - self.hardDamage)
	if self.healthGained > self.healthGainedPerSound and needHealing then
		self.healthGained = self.healthGained - self.healthGainedPerSound
		self.soundHeal:Play(self.Pos)
		
		self:FlashWhite(50)
	end
end

function drawCustomHUD(self)
	if self.dead then
		return
	end
	
	self.healthHUDAnimation = self.healthHUDAnimation / (1 + TimerMan.DeltaTimeSecs * 12.0)
	--self.healthHUDAnimation = math.floor(self.healthHUDAnimation * 1000) * 0.001
	
	
	-- Aim
	local item = self.EquippedItem
	if item and (IsHDFirearm(item)) then
		item = ToHDFirearm(item)
		
		local muzzlePos = item.MuzzlePos
		
		local aimVec = Vector(1 * self.FlipFactor, 0):RadRotate(self:GetAimAngle(false) * self.FlipFactor)--item.RotAngle)
		
		local origin = muzzlePos
		
		local endPos = Vector(origin.X, origin.Y); -- This value is going to be overriden by function below, this is the end of the ray
		local ray = SceneMan:CastObstacleRay(origin, aimVec * (item.SharpLength + self.AimDistance), Vector(0, 0), endPos, 0 , self.Team, 0, 1) -- Do the hitscan stuff, raycast
		
		local diff = SceneMan:ShortestDistance(origin, endPos, true)
		local length = diff.Magnitude
		
		local diffViewPoint = SceneMan:ShortestDistance(origin, self.ViewPoint, true)
		local d = (diffViewPoint - diff).Magnitude
		
		if d < 40 then
			local factor = math.min((40 - d) / 5, 1)
			diffViewPoint = diffViewPoint - (diffViewPoint - diff) * factor
		end
		
		
		local scale = 1
		PrimitiveMan:DrawLinePrimitive(endPos, endPos, 99)
		
		local recoil = 0
		
		if self:GetController():IsState(Controller.AIM_SHARP) then
			recoil = recoil + item.SharpShakeRange
		else
			recoil = recoil + item.ShakeRange
		end
		--recoil = recoil + item.ParticleSpreadRange
		
		-- Scale calculation
		local vec = Vector(length, 0):DegRotate(recoil)
		scale = scale * math.abs(vec.Y) * 0.5
		scale = math.max(scale, 0.75)
		
		PrimitiveMan:DrawLinePrimitive(origin + Vector(25 * self.FlipFactor,0):RadRotate(item.RotAngle), origin + Vector(30 * self.FlipFactor,0):RadRotate(item.RotAngle), 99)
		PrimitiveMan:DrawLinePrimitive(origin + Vector(45 * self.FlipFactor,0):RadRotate(item.RotAngle), origin + Vector(50 * self.FlipFactor,0):RadRotate(item.RotAngle), 99)
		
		local angle = math.pi * 0.25
		PrimitiveMan:DrawLinePrimitive(endPos + Vector(4,-2):RadRotate(angle) * scale, endPos + Vector(4,2):RadRotate(angle) * scale, 99)
		angle = angle + math.pi * 0.5
		PrimitiveMan:DrawLinePrimitive(endPos + Vector(4,-2):RadRotate(angle) * scale, endPos + Vector(4,2):RadRotate(angle) * scale, 99)
		angle = angle + math.pi * 0.5
		PrimitiveMan:DrawLinePrimitive(endPos + Vector(4,-2):RadRotate(angle) * scale, endPos + Vector(4,2):RadRotate(angle) * scale, 99)
		angle = angle + math.pi * 0.5
		PrimitiveMan:DrawLinePrimitive(endPos + Vector(4,-2):RadRotate(angle) * scale, endPos + Vector(4,2):RadRotate(angle) * scale, 99)
		
		local radiusFactor = math.max(math.min(diffViewPoint.Magnitude / math.max(length, 1), 1), 0)
		PrimitiveMan:DrawCirclePrimitive(origin + Vector(math.min(diffViewPoint.Magnitude, length) * self.FlipFactor,0):RadRotate(item.RotAngle), 7 * scale * radiusFactor, 99)
		
		-- local radius = 2
		-- local aimVecAlt = Vector(length * self.FlipFactor, 0):RadRotate(item.RotAngle)
		-- PrimitiveMan:DrawCirclePrimitive(endPos, radius, 99)
		-- PrimitiveMan:DrawCirclePrimitive(origin + aimVecAlt, radius + 4, 183)
		-- PrimitiveMan:DrawCirclePrimitive(origin + aimVecAlt, radius + 6, 97)
	end
	
	
	local center = Vector(self.Pos.X, self.Pos.Y)
	
	local highest = 0
	local lowest = 0
	local right = 0
	local left = 0
	for limb in self.Attachables do
		local pos = Vector(limb.Pos.X, limb.Pos.Y)
		local offset = center - pos
		
		local radius = limb.IndividualRadius
		
		if (offset.X + radius) > right then right = offset.X + radius end
		if (offset.X - radius) < left then left = offset.X - radius end
		
		if (offset.Y - radius) < lowest then lowest = offset.Y - radius end
		if (offset.Y + radius) > highest then highest = offset.Y + radius end
		
		
		for gear in limb.Attachables do
			local pos = Vector(gear.Pos.X, gear.Pos.Y)
			local offset = center - pos
			
			local radius = limb.IndividualRadius
			if (offset.X + radius) > right then right = offset.X + radius end
			if (offset.X - radius) < left then left = offset.X - radius end
			
			if (offset.Y - radius) < lowest then lowest = offset.Y - radius end
			if (offset.Y + radius) > highest then highest = offset.Y + radius end
			
			--PrimitiveMan:DrawCirclePrimitive(pos, radius, 5)
		end
		
		--PrimitiveMan:DrawCirclePrimitive(pos, radius, 5)
	end
	highest = -highest
	lowest = -lowest
	right = -right
	left = -left
	
	--[[
	local pos1 = center + Vector(left, highest)
	local pos2 = center + Vector(right, lowest)
	PrimitiveMan:DrawBoxPrimitive(pos1, pos2, 5);
	]]
	
	local origin = self.Pos
	
	local hudUpperPos = origin + Vector(0, highest - 5)
	local hudLowerPos = origin + Vector(0, lowest)
	
	local hudRightPos = origin + Vector(right, 0)
	local hudLeftPos = origin + Vector(lowest, 0)
	
	-- Shared
	local pos
	
	local colorOutlineBackground = 54
	local colorBackground = 1
	
	-- Healthbar
	local healthbarWidth = 35 - 5 * self.healthHUDAnimation
	local healthbarHeight = 3 + 2 * self.healthHUDAnimation
	
	local colorOutlineHealth = 244
	local colorHealth = 13
	
	local colorOutlineHardDamage = 94
	local colorHardDamage = 251
	
	pos = hudUpperPos + Vector(0, -healthbarHeight)
	pos = Vector(math.floor(pos.X), math.floor(pos.Y))
	
	local healthFactor = ((self.Health / self.MaxHealth) - 0.5)
	local hardDamageFactor = ((self.hardDamage / self.MaxHealth) - 0.5)
	
	PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-healthbarWidth * 0.5, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * 0.5, healthbarHeight * 0.5), colorBackground)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-healthbarWidth * 0.5, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * 0.5, healthbarHeight * 0.5), colorOutlineBackground)
	
	PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-healthbarWidth * hardDamageFactor, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * 0.5, healthbarHeight * 0.5), colorHardDamage)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-healthbarWidth * hardDamageFactor, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * 0.5, healthbarHeight * 0.5), colorOutlineHardDamage)
	
	PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-healthbarWidth * 0.5, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * healthFactor, healthbarHeight * 0.5), colorHealth)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-healthbarWidth * 0.5, -healthbarHeight * 0.5), pos + Vector(healthbarWidth * healthFactor, healthbarHeight * 0.5), colorOutlineHealth)
	
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-healthbarWidth * 0.5 - 1, -healthbarHeight * 0.5 - 1), pos + Vector(healthbarWidth * 0.5 + 1, healthbarHeight * 0.5 + 1), 1)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-healthbarWidth * 0.5 - 2, -healthbarHeight * 0.5 - 2), pos + Vector(healthbarWidth * 0.5 + 2, healthbarHeight * 0.5 + 2), 3)
	
	-- Stamina
	local staminabarWidth = 35 - 5 * self.healthHUDAnimation
	local staminabarHeight = 2 + 2 * self.healthHUDAnimation
	
	local colorOutlineStamina = 5
	local colorStamina = 197
	
	local colorOutlineLoadingStamina = 214
	local colorLoadingStamina = 210
	
	local staminaFactor = (math.floor(self.stamina) / 3) - 0.5
	local staminaLoadingFactor = (self.stamina / 3) - 0.5
	
	pos = hudUpperPos + Vector(0, healthbarHeight)
	pos = Vector(math.floor(pos.X), math.floor(pos.Y))
	
	PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * 0.5), colorBackground)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * 0.5), colorOutlineBackground)
	
	PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * staminaLoadingFactor, staminabarHeight * 0.5), colorLoadingStamina)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * staminaLoadingFactor, staminabarHeight * 0.5), colorOutlineLoadingStamina)
	
	PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * staminaFactor, staminabarHeight * 0.5), colorStamina)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * staminaFactor, staminabarHeight * 0.5), colorOutlineStamina)
	
	local frct
	frct = 0.3
	PrimitiveMan:DrawLinePrimitive(pos + Vector(-staminabarWidth * 0.5 + staminabarWidth * frct, -staminabarHeight * 0.5), pos + Vector(-staminabarWidth * 0.5 + staminabarWidth * frct, staminabarHeight * 0.5), 1)
	frct = 0.7
	PrimitiveMan:DrawLinePrimitive(pos + Vector(-staminabarWidth * 0.5 + staminabarWidth * frct, -staminabarHeight * 0.5), pos + Vector(-staminabarWidth * 0.5 + staminabarWidth * frct, staminabarHeight * 0.5), 1)
	
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5 - 1, -staminabarHeight * 0.5 - 1), pos + Vector(staminabarWidth * 0.5 + 1, staminabarHeight * 0.5 + 1), 1)
	PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5 - 2, -staminabarHeight * 0.5 - 2), pos + Vector(staminabarWidth * 0.5 + 2, staminabarHeight * 0.5 + 2), 3)
	
	-- PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * 0.5), colorBackground)
	-- PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * 0.5), colorOutlineBackground)
	
	-- PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * staminaLoadingFactor), colorLoadingStamina)
	-- PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * staminaLoadingFactor), colorOutlineLoadingStamina)
	
	-- PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * staminaFactor), colorStamina)
	-- PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5, -staminabarHeight * 0.5), pos + Vector(staminabarWidth * 0.5, staminabarHeight * staminaFactor), colorOutlineStamina)
	
	-- local frct
	-- frct = 0.33
	-- PrimitiveMan:DrawLinePrimitive(pos + Vector(-staminabarWidth * 0.5 - 1, staminabarHeight * 0.5 - (staminabarHeight * frct)), pos + Vector(staminabarWidth * 0.5 - 1, staminabarHeight * 0.5 - (staminabarHeight * frct)), 1)
	-- frct = 0.66
	-- PrimitiveMan:DrawLinePrimitive(pos + Vector(-staminabarWidth * 0.5 - 1, staminabarHeight * 0.5 - (staminabarHeight * frct)), pos + Vector(staminabarWidth * 0.5 - 1, staminabarHeight * 0.5 - (staminabarHeight * frct)), 1)
	
	-- PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5 - 1, -staminabarHeight * 0.5 - 1), pos + Vector(staminabarWidth * 0.5 + 1, staminabarHeight * 0.5 + 1), 1)
	-- PrimitiveMan:DrawBoxPrimitive(pos + Vector(-staminabarWidth * 0.5 - 2, -staminabarHeight * 0.5 - 2), pos + Vector(staminabarWidth * 0.5 + 2, staminabarHeight * 0.5 + 2), 3)
end

function Create(self)
	--self.InheritedRotAngleOffset
	
	self.soundFootstep = CreateSoundContainer("V1 Movement Footstep", "Ultrakill.rte");
	self.soundJump = CreateSoundContainer("V1 Movement Jump", "Ultrakill.rte");
	self.soundLanding = CreateSoundContainer("V1 Movement Landing", "Ultrakill.rte");
	self.soundGroundSlam = CreateSoundContainer("V1 Movement Ground Slam", "Ultrakill.rte");
	
	self.soundFalling = CreateSoundContainer("V1 Movement Falling", "Ultrakill.rte");

	self.soundDash = CreateSoundContainer("V1 Movement Dash", "Ultrakill.rte");
	
	self.soundSlideStart = CreateSoundContainer("V1 Movement Start", "Ultrakill.rte");
	self.soundSlideStop = CreateSoundContainer("V1 Movement Stop", "Ultrakill.rte");
	self.soundSlide = CreateSoundContainer("V1 Movement Slide", "Ultrakill.rte");
	
	self.soundPunch = CreateSoundContainer("V1 Punch", "Ultrakill.rte");
	self.soundPunchHit = CreateSoundContainer("V1 Punch Hit", "Ultrakill.rte");
	self.soundPunchParry = CreateSoundContainer("V1 Punch Parry", "Ultrakill.rte");
	
	self.soundError = CreateSoundContainer("V1 Error", "Ultrakill.rte");
	self.soundTaunt = CreateSoundContainer("V1 Taunt", "Ultrakill.rte");
	
	self.soundHurt = CreateSoundContainer("V1 Hurt", "Ultrakill.rte");
	self.soundDeath = CreateSoundContainer("V1 Death", "Ultrakill.rte");
	
	self.soundHeal = CreateSoundContainer("V1 Heal", "Ultrakill.rte");
	
	--  "BLOOD IS FUEL
	--    FOR MY COCK"
	-- Civvie
	
	--self.bloodParticles = {}
	self.healthGained = 0
	self.healthGainedPerSound = 10
	
	self.lastHealth = self.Health
	
	self.hardDamageDamageMultiplier = 0.3
	self.hardDamage = 0
	self.hardDamageRegenerationTimer = Timer()
	self.hardDamageRegenerationDelay = 2000
	
	self.stamina = 3
	
	self.healthHUDAnimation = 0
	--
	
	self.styleMovementFactor = 0
	
	
	self.rayOrigins = {Vector(-2,5), Vector(3,5)}
	
	self.legs = {}
	self.legFeetContact = {true, true}
	self.legFeetContactTimer = {Timer(), Timer()}
	self.legLengthThigh = 8
	self.legLengthShin = 8
	
	self.legFeetSoundTimer = {Timer(), Timer()}
	self.legFeetLandSoundTimer = Timer();
	
	self.walkAnimationAcc = 0 -- "accumulator"
	self.walkFactorCont = 0
	
	self.walkAnimationSpeed = 0
	
	-- Bastardized vectors in raw form
	-- self.runCyclePathAnimation = {
		-- Vector(0, 7),
		-- Vector(8, 7),
		-- Vector(11, 10),
		-- Vector(6, 12),
		-- Vector(-4, 12),
		-- Vector(-11, 11)
	-- }
	
	self.slideLegPose = {
		{-8,9},
		{15,13}
	}
	
	self.jumpLegPose = {
		{6,16},
		{-3,8}
	}
	
	self.runCyclePathAnimation = {
		{0, 7},
		{8, 7},
		{11, 10},
		{6, 12},
		{-4, 12},
		{-11, 11}
	}
	-- wtf, real shit
	local longest = -1 -- Find the longest
	for i, vec in ipairs(self.runCyclePathAnimation) do
		longest = math.max(longest, Vector(vec[1], vec[2]).Magnitude)
	end
	for i = 1, #self.runCyclePathAnimation do -- Normalize them!
		local vec = Vector(self.runCyclePathAnimation[i][1], self.runCyclePathAnimation[i][2])
		vec = vec:SetMagnitude(vec.Magnitude / longest * (self.legLengthThigh + self.legLengthShin))
		self.runCyclePathAnimation[i] = {vec.X, vec.Y}
	end
	
	-- self.runCycleTimer = Timer()
	-- self.runCycleDuration = 1000
	
	self.doubleTapDownState = 0
	self.doubleTapDownTimer = Timer()
	self.doubleTapDownHolding = false
	
	self.doubleTapDashState = 0
	self.doubleTapDashTimer = Timer()
	self.doubleTapDashHolding = false
	
	--self.groundSlamming = false
	self.groundSlamming = self.Pos.Y < 50
	self.groundSlamSlideLock = false -- To prevent instant slide while holding down on landing
	self.groundSlamFallTime = 0
	self.stompPower = 1.5
	self.stompBoost = 5
	
	self.dashing = false
	self.dashingDirection = 0
	
	self.dashingDuration = 300
	self.dashingTimer = Timer()
	
	self.jumping = false
	self.jump = false
	self.jumpTimer = Timer()
	self.jumpCooldown = 500
	self.jumpLowGravity = false
	
	self.wallJumpHolding = false
	self.wallJumps = 0
	self.wallJumpsMax = 4
	
	self.landedTimer = Timer()
	self.landedDuration = 300
	
	self.airbone = false
	
	self.sliding = false
	
	self.coyoteTimer = Timer()
	self.coyoteTime = 100 -- makes jumping feel more responsive, just google "platformer coyote time"
	
	self.flipTimer = Timer()
	self.flipDelay = 100
	
	self.surfaceNormalAngle = 0
	self.surfaceNormal = Vector(0, 1)
	self.surfaceNormalUpdateTimer = Timer()
	self.surfaceNormalUpdateDelay = 50
	self.surfaceNormalUpdateDelayIdle = 195.5
	self.surfaceNormalUpdateDelayWalking = 65.5
	self.surfaceNormalUpdateDelayRunning = 39.5
	
	-- Punch!
	self.punching = false
	self.punchTimer = Timer()
	self.punchDuration = 300
	self.punchCooldownTimer = Timer()
	self.punchCooldown = 200
	self.punchPreviousWeapon = ""
	
	-- Movement Settings
	--self.jumpForce = 10
	self.jumpForce = 7
	
	self.walkSpeed = 30
	
	self.legSpring = 1.1
	self.bodyBalance = 1
end

function Update(self)
	if not self.FGArm then
		self.Health = -1
		self.dead = true
	end
	
	if self.Status == Actor.DEAD or self.Status == Actor.DYING then 
		if not self.dead then
			self.soundError:Play(self.Pos)
			self.soundDeath:Play(self.Pos)
			self.dead = true
			
			--self.deathGibTimer:Reset()
		end
		
		self.HitsMOs = true
		self.GetsHitByMOs = true
		
		self.sliding = false
		
		self.legSpring = math.max(self.legSpring - TimerMan.DeltaTimeSecs * 0.75, 0)
		self.bodyBalance = math.max(self.bodyBalance - TimerMan.DeltaTimeSecs * 5.5, 0)
	end
	
	-- Shameleslly stolen from pawnis: cheers, fil
	if (UInputMan:KeyPressed(24)) and self:IsPlayerControlled() and not self.soundTaunt:IsBeingPlayed() then
		self.soundTaunt:Play(self.Pos)
		self.Vel = self.Vel + Vector(0, 3)
	end
	
	if self.defaultHUDVisible == nil then
		self.defaultHUDVisible = self.HUDVisible
	end
	
	if self:IsPlayerControlled() then
		if not (self:NumberValueExists("DisableHUD") and self:GetNumberValue("DisableHUD") == 1) then
			drawCustomHUD(self)
		end
		self.HUDVisible = false
	else
		self.defaultHUDVisible = self.HUDVisible
	end
	
	
	-- ANIMATION TEST
	-- if self.runCycleTimer:IsPastSimMS(self.runCycleDuration) then
		-- self.runCycleTimer:Reset()
	-- end
	-- local animation = self.runCyclePathAnimation
	-- local factor = self.runCycleTimer.ElapsedSimTimeMS / self.runCycleDuration
	-- local size = 5.0
	
	-- local origin = self.Pos + Vector(0, -150)
	-- vec = getPathAnimationVector(animation, factor)
	-- vec = vec * size
	
	-- local l1 = self.legLengthThigh * size
	-- local l2 = self.legLengthShin * size
	
	-- local angles = calcIK(l1, l2, Vector(vec.X,vec.Y))
	
	-- local pos1 = origin + Vector(l1, 0):RadRotate(-angles[1])
	-- local pos2 = pos1 + Vector(l2, 0):RadRotate(-angles[1] - angles[2])
	
	-- local lasta = animation[#animation]
	-- lasta = Vector(lasta[1], lasta[2])
	-- for i, a in ipairs(animation) do
		-- a = Vector(a[1], a[2])
		-- PrimitiveMan:DrawLinePrimitive(origin + lasta * size, origin + a * size, 166);
		-- lasta = a
	-- end
	
	-- PrimitiveMan:DrawLinePrimitive(origin, pos1, 13);
	-- PrimitiveMan:DrawLinePrimitive(pos1, pos2, 5);
	-- TEST
	
	-- Clean terrain
	-- I hate it but gets the job done
	for i = 1, (1 + math.min(math.abs(self.Vel.X * 0.5), 5)) do
		local woosh = CreateMOPixel("V1 Grasschoppingandcleaningparticle", "Ultrakill.rte");
		woosh.Vel = self.Vel + Vector(0, 1):RadRotate(self.RotAngle + math.pi * RangeRand(-1,1) * 0.3) * 100
		woosh.Pos = self.Pos
		woosh.GlobalAccScalar = 0.0;
		MovableMan:AddParticle(woosh);
	end
	
	-- Consume the blood around the robot and heal
	consumeBlood(self)
	
	-- Surface normal calculation
	if math.abs(self.Vel.X) < 3 then
		self.surfaceNormalUpdateDelay = self.surfaceNormalUpdateDelayIdle
	elseif math.abs(self.Vel.X) > 8 then
		self.surfaceNormalUpdateDelay = self.surfaceNormalUpdateDelayRunning
	else
		self.surfaceNormalUpdateDelay = self.surfaceNormalUpdateDelayWalking
	end
	if self.surfaceNormalUpdateTimer:IsPastSimMS(self.surfaceNormalUpdateDelay) then
		if not self.airbone then
			local origin = self.Pos + Vector(0, -1)
			
			local maxi = 6
			local maxj = 5
			local arc = math.pi
			
			local radius = self.Radius * 1.2
			
			self.surfaceNormal = Vector(0, 0)
			
			for i = -maxi, maxi do
				local factorI = (i / maxi)
				
				for j = 1, maxj do
					local factorJ = (j / maxj)
					
					local ang = arc * factorI * 0.5 * (1 - factorJ * 0.3)
					local offset = Vector(0, radius * math.sqrt(factorJ)):RadRotate(ang)
					
					local point = origin + offset
					
					local checkPix = SceneMan:GetTerrMatter(point.X, point.Y)
					if checkPix > 0 then
						--PrimitiveMan:DrawCirclePrimitive(point, 1, 5);
						
						self.surfaceNormal = self.surfaceNormal + Vector(offset.X, offset.Y):SetMagnitude(2 + (maxj - j))
						break
					--else
						--PrimitiveMan:DrawCirclePrimitive(point, 1, 13);
					end
				end
				
			end
			
			self.surfaceNormal = self.surfaceNormal / ((maxi * 2 + 1) * maxj)
			self.surfaceNormal:SetMagnitude(1)
		else
			self.surfaceNormal = Vector(0, 1)
		end
		self.surfaceNormalUpdateTimer:Reset()
		
		self.surfaceNormalAngle = self.surfaceNormal.AbsRadAngle + math.pi * 0.5
	end
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + self.surfaceNormal * 10, 5)
	
	
	local ctrl = self:GetController()
	local player = false
	if self:IsPlayerControlled() then
		player = true
	end
	-- Get leg MOs
	local legIndex = 0
	for limb in self.Attachables do
		if string.find(limb.PresetName, "Leg") then
			legIndex = legIndex + 1
			self.legs[legIndex] = limb
			
			self.Health = self.Health - limb.WoundCount * 3
		end
		if limb:NumberValueExists("AccumulatedWoundCount") then
			limb:SetNumberValue("AccumulatedWoundCount", limb:GetNumberValue("AccumulatedWoundCount") + limb.WoundCount)
		else
			limb:SetNumberValue("AccumulatedWoundCount", limb.WoundCount)
		end
		--if self.dead and limb.WoundCount > 0 and limb:GetNumberValue("AccumulatedWoundCount") > limb.GibWoundLimit then
		--	limb:GibThis()
		--end
		if not self.dead then
			limb:RemoveWounds(limb.WoundCount)
		end
	end
	if not self.dead then
		self:RemoveWounds(self.WoundCount)
	end
	
	local item = self.EquippedItem
	if item and (IsHDFirearm(item)) then
		item = ToHDFirearm(item)
		self.Health = self.Health - item.WoundCount * 1
		item:RemoveWounds(item.WoundCount)
	end
	
	local contactAmoutMax = legIndex
	
	-- Accumulator
	local walkAcc = self.Vel.X * 0.5
	
	-- Raycast/Legs/Terrain detection
	local terrCont = {}
	
	
	-- Leg animation and physics
	local minLegLift = 1
	
	local contactAmout = 0
	
	local contactPos = {}
	local contactVec = {}
	local contactLength = {}
	for i = 1, contactAmoutMax do
		local leg = self.legs[i]
		
		--print(MovableMan:ValidMO(leg))
		--print(leg.Age)
		if leg then
			local thigh = leg
			local shin
			for mo in thigh.Attachables do
				shin = mo
				break
			end
			
			-- Shin wound removal
			if shin then
				self.Health = self.Health - shin.WoundCount * 2
				shin:RemoveWounds(shin.WoundCount)
			end
		
			local offset = Vector(self.rayOrigins[i].X, self.rayOrigins[i].Y)
			if thigh and shin then
				local animationOffset = (i - 1) * 0.5
				local animationFactor = (self.walkAnimationAcc + animationOffset) % 1
				local animationVector = getPathAnimationVector(self.runCyclePathAnimation, animationFactor)
				
				local legVector = Vector(animationVector.X, animationVector.Y * 2.0) + Vector(0, -8)
				
				if not self.landedTimer:IsPastSimMS(self.landedDuration) or self.airbone then
					local pose = self.jumpLegPose[i]
					local poseVector = Vector(pose[1] * self.FlipFactor, pose[2])
					
					local landedFactor = 1 - math.min(self.landedTimer.ElapsedSimTimeMS / self.landedDuration, 1)
					local factor = self.walkAnimationSpeed + (landedFactor - self.walkAnimationSpeed) * landedFactor
					
					legVector = poseVector + (legVector - poseVector) * factor
				end
				if self.sliding then
					--local slidei = self.HFlipped and (3 - i) or i
					local pose = self.slideLegPose[i]
					legVector = Vector(pose[1] * self.FlipFactor, pose[2])
				end
				
				local rotation = 0
				if self.sliding then
					rotation = self.surfaceNormalAngle
				end
				
				
				local rayOrigin = self.Pos + offset:RadRotate(self.RotAngle)
				--local rayVector = (Vector(self.Vel.X * GetPPM() * TimerMan.DeltaTimeSecs * 1.0, 0) + animationVector):RadRotate(self.RotAngle)
				local rayVector = Vector(legVector.X + self.Vel.X * GetPPM() * TimerMan.DeltaTimeSecs * 1.0, legVector.Y):RadRotate(rotation)--:RadRotate(self.RotAngle)
				rayVector = rayVector:SetMagnitude(rayVector.Magnitude + 2)
				local terrCheck = SceneMan:CastStrengthRay(rayOrigin, rayVector, 30, Vector(), 0, 0, SceneMan.SceneWrapsX);
				--PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVector, 5);
				
				local walkLegLift = math.abs(rayVector.Y) / (self.legLengthThigh + self.legLengthShin)
				
				local rayLength = rayVector.Magnitude
				
				local rayPos = rayOrigin + rayVector
				contactPos[i] = Vector(rayPos.X, rayPos.Y)
				contactVec[i] = Vector(rayVector.X, rayVector.Y)
				contactLength[i] = rayVector.Magnitude
				
				if terrCheck then
					local rayHitPos = SceneMan:GetLastRayHitPos()
					local hitPos = Vector(rayHitPos.X, rayHitPos.Y)
					contactAmout = contactAmout + 1
					contactPos[i] = Vector(hitPos.X, hitPos.Y)
					contactVec[i] = SceneMan:ShortestDistance(rayOrigin, contactPos[i], SceneMan.SceneWrapsX); --contactPos[i] - rayOrigin
					contactLength[i] = contactVec[i].Magnitude
					
					self.legFeetContactTimer[i]:Reset()
					
					if self.sliding then
						if i == 1 then
							
							local particle
							--for i = 1, 3 do
							particle = CreateMOPixel("Spark Yellow "..math.random(1, 2));
							particle.Pos = hitPos + Vector(0, -3);
							particle.Vel = self.Vel + (Vector(-1.5 * self.FlipFactor, -0.3)):RadRotate(math.pi * RangeRand(-0.3, 0.3)) * RangeRand(0.5, 1.0) * 10.0;
							particle.GlobalAccScalar = 0.5;
							particle.Lifetime = particle.Lifetime * RangeRand(0.6, 1.6) * 0.75;
							MovableMan:AddParticle(particle);
							--end
							
						end
					else
						-- Sound code shameleslly stolen from pawnis: cheers, fil
						if self.legFeetContact[i] == false and walkLegLift > 0.95 then
							self.legFeetContact[i] = true
							
							if (self.Vel.Y > 10 or self.groundSlamming) and self.legFeetLandSoundTimer:IsPastSimMS(500) then
								if self.groundSlamming then
									self.soundLanding.Pitch = 0.975
									self.soundLanding.Volume = 1.2
									
									local particle
									for j = 1, 5 do
										for i = -1, 1 do
											particle = CreateMOSParticle(math.random(0,1) > 0 and "Smoke Ball 1" or "Small Smoke Ball 1");
											particle.Pos = hitPos + Vector(0, -3);
											particle.HitsMOs = false
											particle.GlobalAccScalar = 0.3
											particle.Vel = self.Vel + (Vector(2.0 * i, -0.05)):RadRotate(math.pi * RangeRand(-0.3, 0.3)) * RangeRand(0.2, 1.0) * 25.0;
											particle.Lifetime = particle.Lifetime * RangeRand(0.6, 1.6) * 0.6;
											MovableMan:AddParticle(particle);
										end
									end
								else
									self.soundLanding.Pitch = 1.0
									self.soundLanding.Volume = 1 - 0.5 * (1 - math.min(math.abs(self.Vel.Y) / 15, 1.0))
								end
								self.soundLanding:Play(self.Pos)
								
								
								local terrPixel = SceneMan:GetTerrMatter(hitPos.X, hitPos.Y)
								
								if terrPixel ~= 0 then -- 0 = air
									self.soundFootstep.Pitch = RangeRand(0.95,1.05)
									self.soundFootstep.Volume = 1.0
									self.soundFootstep:Play(hitPos)
								end			
								
								self.legFeetLandSoundTimer:Reset();
								
								self.legFeetSoundTimer[1]:Reset();
								self.legFeetSoundTimer[2]:Reset();
							end
							
							if self.legFeetSoundTimer[i]:IsPastSimMS(250) then
								
								local terrPixel = SceneMan:GetTerrMatter(hitPos.X, hitPos.Y)
								
								if terrPixel ~= 0 then -- 0 = air
									self.soundFootstep.Pitch = RangeRand(0.95,1.05) - 0.2 * (1 - math.min(math.abs(walkAcc) / 2, 1.0))
									self.soundFootstep.Volume = (0.3 + 0.7 * math.abs(walkAcc) / 3) * 0.7
									self.soundFootstep:Play(hitPos)
								end						
								
								self.legFeetSoundTimer[i]:Reset()
							end
							
						elseif walkLegLift < 0.9 and self.legFeetContact[i] == true then
							self.legFeetContact[i] = false
						end
					end
					
					local fac = math.pow(1 - math.pow(contactLength[i] / rayLength, 3.0), 2.0) * 1.2
					self.Vel = Vector(self.Vel.X, self.Vel.Y / (1 + (TimerMan.DeltaTimeSecs * 1 * self.legSpring)))
					self.Vel = self.Vel - Vector(contactVec[i].X, contactVec[i].Y):SetMagnitude(fac) * TimerMan.DeltaTimeSecs * math.min(10 + math.min(math.abs(self.Vel.X * 0.6),20), 12) * 3 * self.legSpring -- Spring
					--self.Vel = self.Vel - SceneMan.GlobalAcc * (fac + 2) / 3 * TimerMan.DeltaTimeSecs * 0.5 -- Stop the gravity
					self.Vel = self.Vel - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * 0.15 * self.legSpring -- Stop the gravity
				elseif self.legFeetContactTimer[i]:IsPastSimMS(200) then
					self.legFeetContact[i] = false
				end
				
				local legVec = contactVec[i]
				--legVec:RadRotate(-self.RotAngle)
				legVec = Vector(legVec.X * self.FlipFactor, legVec.Y)
				--legVec:RadRotate(self.RotAngle)
				
				--PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVector, 13);
				--PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + legVec, 5);
				
				local angles = calcIK(self.legLengthThigh, self.legLengthShin, legVec)
				thigh.InheritedRotAngleOffset = -angles[1]
				shin.InheritedRotAngleOffset = -angles[2]
			else
				-- kil
				self.Health = self.Health - 5
			end
		end
		
	end
	local walkAnimationSpeedTarget = contactAmout / math.max(contactAmoutMax, 1)
	self.walkAnimationSpeed = (self.walkAnimationSpeed + walkAnimationSpeedTarget * TimerMan.DeltaTimeSecs * 2) / (1 + TimerMan.DeltaTimeSecs * 2)
	
	local finalWalkAnimationSpeed = math.max(self.walkAnimationSpeed, walkAnimationSpeedTarget)
	
	self.walkAnimationAcc = (self.walkAnimationAcc + TimerMan.DeltaTimeSecs * walkAcc * finalWalkAnimationSpeed) % 1
	local walkFactor = math.min(math.abs(self.Vel.X * 0.7), 1) / math.max(contactAmoutMax, 1) * contactAmout
	self.walkFactorCont = (self.walkFactorCont + walkFactor * TimerMan.DeltaTimeSecs * 20) / (1 + TimerMan.DeltaTimeSecs * 20)
	
	self.Vel = self.Vel + Vector(0, -math.max(self.Vel.Y, 0) * TimerMan.DeltaTimeSecs * 15):RadRotate(self.RotAngle) / math.max(contactAmoutMax, 1) * contactAmout -- Deaccelerate Y velocty
	
	-- Input and Movement
	if not self.dead and not (self:NumberValueExists("IgnoreInput") and self:GetNumberValue("IgnoreInput") == 1) and ctrl then
		local input = 0
		if ctrl:IsState(Controller.MOVE_LEFT) then
			input = -1
			if self.flipTimer:IsPastSimMS(self.flipDelay) and not self.HFlipped then
				--self.HFlipped = true
				self.flipTimer:Reset()
			end
		elseif ctrl:IsState(Controller.MOVE_RIGHT) then
			input = 1
			if self.flipTimer:IsPastSimMS(self.flipDelay) and self.HFlipped then
				--self.HFlipped = false
				self.flipTimer:Reset()
			end
		end
		
		-- Melee Attack!
		if self.FGArm then
			if not self.punching and self.punchCooldownTimer:IsPastSimMS(self.punchCooldown) and UInputMan:KeyPressed(6) and self:IsPlayerControlled() then
				
				-- local item = self.EquippedItem
				-- ToMOSRotating(self.FGArm):RemoveAttachable(ToAttachable(item), true, true)
				-- self:AddInventoryItem(ToMOSRotating(item):Clone())
				
				local itemPrevious = self.EquippedItem
				if itemPrevious then
					local name = ToHeldDevice(itemPrevious).PresetName
					if name ~= "Null Item" then
						self.punchPreviousWeapon = name
					end
				end
				
				-- Unequip weapon (thank you 4zK!)
				local item = CreateHeldDevice("Null Item");
				self:AddInventoryItem(item);
				self:EquipNamedDevice("Null Item", true);
				--item.ToDelete = true;
				ToMOSRotating(self.FGArm):RemoveAttachable(ToAttachable(item), false, false)
				
				self.punchTimer:Reset()
				self.punching = true
				
				self.Frame = 0
				
				--self.lastViewPoint = Vector(self.ViewPoint.X, self.ViewPoint.Y)
				self.lastViewPoint = SceneMan:ShortestDistance(self.Pos, Vector(self.ViewPoint.X, self.ViewPoint.Y), SceneMan.SceneWrapsX)
				
				local punchVel = 45
				
				local gfx = CreateMOSRotating("V1 Punch GFX", "Ultrakill.rte")
				gfx.Pos = ToArm(self.FGArm).HandPos
				gfx.RotAngle = self:GetAimAngle(true)
				gfx.Vel = self.Vel + Vector(punchVel, 0):RadRotate(self:GetAimAngle(true))
				gfx.AirResistance = gfx.AirResistance * 0.85
				gfx.Lifetime = gfx.Lifetime * 0.5
				gfx.Team = self.Team
				gfx.IgnoresTeamHits = true
				gfx:SetNumberValue("Parent", self.UniqueID)
				--gfx.HFlipped = self.HFlipped
				MovableMan:AddParticle(gfx)
				
				for i = 1, 3 do
					local pixel = CreateMOPixel("Epic Anime Speed Flyby Particles", "Ultrakill.rte");
					pixel.Pos = ToArm(self.FGArm).HandPos + Vector(RangeRand(-1,1), RangeRand(-1, 1)) * 3
					pixel.Vel = self.Vel + Vector(punchVel, 0):RadRotate(self:GetAimAngle(true) + math.rad(RangeRand(-1,1) * 5)) * RangeRand(0.8,1.0)
					pixel.Lifetime = pixel.Lifetime * 2
					pixel.AirResistance = gfx.AirResistance
					pixel.HitsMOs = true
					pixel.Team = self.Team
					pixel.IgnoresTeamHits = true
					pixel.Sharpness = 0
					MovableMan:AddParticle(pixel)
				end
				
				self.soundPunch:Play(self.Pos)
			end
			
			if self.punching then
				self:GetController():SetState(Controller.WEAPON_CHANGE_NEXT, false)
				self:GetController():SetState(Controller.WEAPON_CHANGE_PREV, false)
				
				if not self.originalFGArmOffset then
					self.originalFGArmOffset = Vector(self.FGArm.IdleOffset.X, self.FGArm.IdleOffset.Y)
				end
				
				local factorVel = math.min(self.Vel.Magnitude / 5, 3)
				self.ViewPoint = self.Pos + (self.lastViewPoint + SceneMan:ShortestDistance(self.Pos, Vector(self.ViewPoint.X, self.ViewPoint.Y), SceneMan.SceneWrapsX) * factorVel) / (1 + factorVel)
				
				local factor = self.punchTimer.ElapsedSimTimeMS / self.punchDuration
				local angle = self:GetAimAngle(true)
				
				local factorPunch = math.sin(math.sqrt(math.sqrt(factor)) * math.pi)
				
				self.FGArm.IdleOffset = Vector(30 * factorPunch, 0):RadRotate(angle * self.FlipFactor + (self.HFlipped and math.pi or 0))
				self.FGArm.RotAngle = angle * self.FlipFactor + (self.HFlipped and math.pi or 0)
				self.FGArm.Pos = self.FGArm.Pos + Vector(10 * factorPunch, 0):RadRotate(angle)
				self.FGArm.Scale = 1 + 0.25 * factorPunch
				
				self.Frame = math.min(math.floor(5 * factorPunch + 0.5), 4)
				
				if self.punchTimer:IsPastSimMS(self.punchDuration) then
					self.punching = false
					self.punchCooldownTimer:Reset()
					
					self.Frame = 0
					
					if self.punchPreviousWeapon and self.punchPreviousWeapon ~= "" then
						self:EquipNamedDevice(self.punchPreviousWeapon, true);
					end
					self.punchPreviousWeapon = ""
					
					self.FGArm.IdleOffset = Vector(self.originalFGArmOffset.X, self.originalFGArmOffset.Y)
				end
			end
		end
		
		--[[
			self.punching = false
			self.punchTimer = Timer()
			self.punchDuration = 500
			self.punchCooldownTimer = Timer()
			self.punchCooldown = 300
			self.punchPreviousWeapon = ""
		]]
		
		-- Double tap ground slam
		if ctrl:IsState(Controller.BODY_CROUCH) and not self.groundSlamming then
			if not self.doubleTapDownHolding then
				self.doubleTapDownHolding = true
				
				self.doubleTapDownState = self.doubleTapDownState + 1
				self.doubleTapDownTimer:Reset()
				if self.doubleTapDownState == 2 then
					self.doubleTapDownState = 0
					self.groundSlamming = true
					self.Vel = Vector(0, 30)
					
					self.groundSlamFallTime = 0
					
					self.groundSlamSlideLock = true
				end
			end
		else
			if not self.groundSlamming then
				self.groundSlamSlideLock = false
			end
			self.doubleTapDownHolding = false
		end
		
		if self.doubleTapDownTimer:IsPastSimMS(200) then
			self.doubleTapDownState = 0
		end
		--
		
		-- Double tap dash
		if input ~= 0 and not self.dashing then
			if not self.doubleTapDashHolding then
				self.doubleTapDashHolding = true
				
				self.doubleTapDashState = self.doubleTapDashState + input
				self.doubleTapDashTimer:Reset()
				
				--self.soundDash:Play(self.Pos)
				
				--if input ~= 0 and input ~= mathSign(self.doubleTapDashState) then
				--	self.doubleTapDashState = 0
				if math.abs(self.doubleTapDashState) > 1 and self.stamina >= 1 then -- and math.floor(self.stamina) >= 1 then
					self.soundDash:Play(self.Pos)
					
					self.stamina = self.stamina - 1
					--self.stamina = math.floor(self.stamina - 1)
					
					self.dashingTimer:Reset()
					self.dashingDirection = mathSign(self.doubleTapDashState)
					self.dashing = true
					self.Vel = Vector(0, 0)
					
					for i = 1, 5 do
						local particle = CreateMOPixel("Epic Anime Speed Flyby Particles", "Ultrakill.rte");
						particle.Pos = self.Pos + Vector(RangeRand(-1,1) * 1.2, RangeRand(-1,1)) * self.Radius - self.Vel * 0.5 * rte.PxTravelledPerFrame
						particle.Vel = self.Vel + Vector(RangeRand(0.5,2) * self.dashingDirection, 0) * 20
						particle.Lifetime = particle.Lifetime * RangeRand(0.6, 1.6) * 1.0
						MovableMan:AddParticle(particle)
					end
					
					self.doubleTapDashState = 0
				end
			end
		else
			self.doubleTapDashHolding = false
		end
		
		if self.doubleTapDashTimer:IsPastSimMS(200) then
			self.doubleTapDashState = 0
		end
		--
		
		if self.dashing then -- Dash
			self.groundSlamming = false
			self.soundFalling:Stop()
			self.sliding = false
			
			if math.random(0,100) < 70 then
				local particle = CreateMOPixel("Epic Anime Speed Flyby Particles", "Ultrakill.rte");
				particle.Pos = self.Pos + Vector(RangeRand(-1,1) * 1.2, RangeRand(-1,1)) * self.Radius - self.Vel * 0.5 * rte.PxTravelledPerFrame
				particle.Vel = self.Vel + Vector(RangeRand(0.5,2) * self.dashingDirection, 0) * 5
				particle.Lifetime = particle.Lifetime * RangeRand(0.6, 1.6) * 1.0
				MovableMan:AddParticle(particle)
			end
			
			self.Vel = Vector(self.dashingDirection * 15, 0)
			
			self.HitsMOs = false
			self.GetsHitByMOs = false
			
			if self.dashingTimer:IsPastSimMS(self.dashingDuration) then
				self.dashing = false
				
				self.Vel = Vector(self.Vel.X * 0.75, self.Vel.Y)
			end
			
		elseif self.groundSlamming then -- Ground Slam
			if self.soundFalling:IsBeingPlayed() then
				self.soundFalling.Pos = self.Pos
				self.soundFalling.Volume = 0.9
			else
				self.soundFalling:Play(self.Pos)
			end
			
			self.groundSlamFallTime = self.groundSlamFallTime + TimerMan.DeltaTimeSecs
			
			self.HitsMOs = true
			self.GetsHitByMOs = true
			
			if math.random(0,100) < 50 then
				local particle = CreateMOPixel("Epic Anime Speed Flyby Particles", "Ultrakill.rte");
				particle.Pos = self.Pos + Vector(RangeRand(-1,1), RangeRand(-1,1) * 1.2) * self.Radius
				particle.Vel = self.Vel + Vector(0, RangeRand(0.5,2)) * 5
				particle.Lifetime = particle.Lifetime * RangeRand(0.6, 1.6) * 3.0
				MovableMan:AddParticle(particle)
			end
			
			
			-- Shameleslly stolen from 4zK: cheers, fil
			local checkPos = self.Pos + Vector(self.Vel.X, self.Vel.Y + 10):SetMagnitude(self.Radius + self.Vel.Magnitude * 0.2);
			local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
			if moCheck ~= 255 then
				local mo = MovableMan:GetMOFromID(moCheck);
				if mo and IsMOSRotating(mo) and mo.Team ~= self.Team then
					if (mo.Mass + mo.Radius + mo.Vel.Y) / self.stompPower < (self.Mass + self.Radius + self.Vel.Y) then
						mo.Vel.Y = mo.Vel.Y / 2 + self.Vel.Y + self.stompBoost / 2;
						ToMOSRotating(mo):GibThis();
						self.Vel.Y = -self.Vel.Y / 2 - self.stompBoost;
						
						ToMOSRotating(mo):SetNumberValue("UltrakillGroundSlammed", 1)
						ToMOSRotating(ToMOSRotating(mo):GetRootParent()):SetNumberValue("UltrakillGroundSlammed", 1)
					else
						mo.Vel.Y = mo.Vel.Y + self.Vel.Y / math.sqrt(math.abs(mo.Mass) + 1);
						self.Vel.Y = -self.Vel.Y / 2 - 5;
						
						self.groundSlamming = false
						
						self.soundGroundSlam:Play(self.Pos)
						self.soundFalling:Stop()
					end
				end
			end
			
			if contactAmout > 0 then
				if ctrl:IsState(Controller.BODY_CROUCH) and math.floor(self.stamina) >= 2 and self.groundSlamFallTime > 0.07 then
					-- Actual ground slam!
					self.stamina = math.floor(self.stamina - 2)
					local slam = CreateMOSRotating("V1 Ground Slam", "Ultrakill.rte")
					slam.Pos = self.Pos
					slam.Team = self.Team
					slam.IgnoresTeamHits = true
					slam:SetNumberValue("Parent", self.UniqueID)
					MovableMan:AddParticle(slam)
					
					--[[
					local effectRangeX = 75
					local effectRangeY = 10
					
					-- Original code, unused
					-- Shameleslly stolen from 4zK: cheers, fil
					for actor in MovableMan.Actors do
						local dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, SceneMan.SceneWrapsX);
						local length = 1;
						if actor.Status < 1 then
							if IsAHuman(actor) then
								actor = ToAHuman(actor);
								if actor.FGLeg then
									length = ToMOSprite(actor.FGLeg):GetSpriteWidth() * (actor.FGLeg.Frame / actor.FGLeg.FrameCount);
								elseif actor.BGLeg then
									length = ToMOSprite(actor.BGLeg):GetSpriteWidth() * (actor.BGLeg.Frame / actor.BGLeg.FrameCount);
								end
							elseif IsACrab(actor) then
								actor = ToACrab(actor);
								if actor.RFGLeg then
									length = actor.RFGLeg.Radius;
								elseif actor.LFGLeg then
									length = actor.LFGLeg.Radius;
								end
							end
						end
						if dist.Magnitude < effectRangeX then
							--table.insert(self.shakeTable, actor);
							if math.abs(actor.Vel.Y) < 5 and math.abs(actor.Pos.Y - self.Pos.Y) < effectRangeY and actor.MissionCritical ~= true then
								length = length + 1 + ToMOSprite(actor):GetSpriteHeight() / 2;
								local hitPos = Vector(0, 0);
								local terrCheck = SceneMan:CastStrengthRay(actor.Pos, Vector(0, length), 1, hitPos, math.sqrt(length), 0, SceneMan.SceneWrapsX);
								if terrCheck then
									local sizeFactor = math.min(math.max(40 / actor.Radius, 0), 1);
									actor.Health = actor.Health - 5 * sizeFactor
									actor.Vel = actor.Vel / 2 - Vector(0, 18 * sizeFactor);
									actor.AngularVel = actor.AngularVel / 2 + math.random(-10, 10);
									hitPos = hitPos + Vector(0, -length / 2);
									-- local particleCount = 4;
									-- for i = 1, particleCount do
										-- local part = CreateMOSParticle("Mario.rte/Hit Effect Tiny Star");
										-- part.Lifetime = part.Lifetime * RangeRand(0.5, 1.0);
										-- part.Pos = hitPos;
										-- part.Vel = Vector((5 + math.sqrt(actor.Radius)), 0):RadRotate(0.79 + 6.28 * (i / particleCount)) + Vector(0, -5);
										-- MovableMan:AddParticle(part);
									-- end
									-- local glow = CreateMOPixel("Mario.rte/Hit Effect Star Glow");
									-- glow.Pos = hitPos;
									-- MovableMan:AddParticle(glow);
									-- AudioMan:PlaySound("Mario.rte/Sounds/smw/smw_stomp.wav", actor.Pos);
								end
							end
						end
					end
					]]
				end
				
				self.groundSlamming = false
				
				self.soundGroundSlam:Play(self.Pos)
				self.soundFalling:Stop()
				self.Vel = self.Vel * 0.1
			else
				self.Vel = Vector(self.Vel.X * 0.9, math.max(self.Vel.Y, 30))
			end
		else
			
			self.HitsMOs = true
			self.GetsHitByMOs = true
			
			if self.soundFalling:IsBeingPlayed() then
				self.soundFalling.Pos = self.Pos
				self.soundFalling.Pitch = 0.9 + 0.1 * (math.min(0.02 * math.max(self.Vel.Y, 0), 1))
				self.soundFalling.Volume = math.min(0.02 * math.max(self.Vel.Y, 0), 1)
			else
				self.soundFalling:Play(self.Pos)
			end
			
			-- Walljump
			local walljump = false
			if ctrl:IsState(Controller.MOVE_UP) and not self.wallJumpHolding then
				self.wallJumpHolding = true
				walljump = true
			elseif not ctrl:IsState(Controller.MOVE_UP) then
				self.wallJumpHolding = false
			end
			
			if self.jumpTimer:IsPastSimMS(self.jumpCooldown * 0.5) and self.airbone then
				
				if walljump and self.wallJumps < self.wallJumpsMax then
					-- Ray check
					local origin = self.Pos + Vector(0, -1) + self.Vel * rte.PxTravelledPerFrame * 0.5
					
					local maxi = 4
					
					local wallContactsRight = 0
					local wallContactsLeft = 0
					
					local margin = 14
					local bend = 12
					local height = 22
					
					-- Right
					for i = -maxi, maxi do
						local factorI = (i / maxi)
						local offset = Vector(margin + bend - bend * math.pow(factorI, 2), height * factorI):RadRotate(self.RotAngle)
						point = origin + offset
						
						local checkPix = SceneMan:GetTerrMatter(point.X, point.Y)
						if checkPix > 0 then
							wallContactsRight = wallContactsRight + 1
						--	PrimitiveMan:DrawCirclePrimitive(point, 1, 5);
						--else
						--	PrimitiveMan:DrawCirclePrimitive(point, 1, 13);
						end
					end
					
					-- Left
					for i = -maxi, maxi do
						local factorI = (i / maxi)
						local offset = Vector(-margin - bend + bend * math.pow(factorI, 2), height * factorI):RadRotate(self.RotAngle)
						point = origin + offset
						
						local checkPix = SceneMan:GetTerrMatter(point.X, point.Y)
						if checkPix > 0 then
							wallContactsLeft = wallContactsLeft + 1
						--	PrimitiveMan:DrawCirclePrimitive(point, 1, 5);
						--else
						--	PrimitiveMan:DrawCirclePrimitive(point, 1, 13);
						end
					end
					
					if math.max(wallContactsRight, wallContactsLeft) > 1 then
						local sideForce = 3.5
						if wallContactsRight > wallContactsLeft then
							self.Vel = self.Vel + Vector(-self.Vel.X * 1.7 - sideForce, -self.Vel.Y * 0.75 - self.jumpForce * 1.3)
						elseif wallContactsRight < wallContactsLeft then
							self.Vel = self.Vel + Vector(-self.Vel.X * 1.7 + sideForce, -self.Vel.Y * 0.75 - self.jumpForce * 1.3)
						else
							self.Vel = self.Vel + Vector(-self.Vel.X * 0.5, -self.jumpForce + math.min(math.max(-self.Vel.Y, 0.0) * 0.35, self.jumpForce * 0.4))
						end
						
						-- Bonust movement style!
						self.styleMovementFactor = math.min(self.styleMovementFactor + 0.15, 1)
						
						--self.jumpLowGravity = true
						
						self.jumping = true
						self.jump = false
						self.jumpTimer:Reset()
						
						--PrimitiveMan:DrawLinePrimitive(origin + Vector(-margin, 0), origin + Vector(margin, 0), 5)
						
						self.wallJumps = self.wallJumps + 1
						if self.wallJumps >= self.wallJumpsMax then
							self.soundError:Play(self.Pos)
						end
						
						self.soundJump.Pitch = 1 + self.wallJumps * 0.115
						self.soundJump:Play(self.Pos)
					end
				end
			end
			
			-- Jump
			if self.jumpTimer:IsPastSimMS(self.jumpCooldown) then
				if self.jump and ctrl:IsState(Controller.MOVE_UP) and not self.coyoteTimer:IsPastSimMS(self.coyoteTime) then
					self.jumpLowGravity = true
					
					self.jumping = true
					self.jump = false
					self.jumpTimer:Reset()
					
					self.soundJump.Pitch = 1.0
					self.soundJump:Play(self.Pos)
					
					self.Vel = self.Vel + Vector(0, -self.jumpForce + math.min(math.max(-self.Vel.Y, 0.0) * 0.35, self.jumpForce * 0.75))
				elseif contactAmout > 0 then
					if self.jumping then
						self.jumping = false
						self.Vel = Vector(self.Vel.X, self.Vel.Y * 0.5)
					end
					if not ctrl:IsState(Controller.MOVE_UP) then
						self.jump = true
					end
				end
			end
			
			-- L E V I T A T E
			if ctrl:IsState(Controller.MOVE_UP) then
				if self.jumpLowGravity and not self.jumpTimer:IsPastSimMS(self.jumpCooldown) then
					local factor = math.sqrt(1 - (self.jumpTimer.ElapsedSimTimeMS / self.jumpCooldown))
					self.Vel = self.Vel - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * 1.2 * factor -- Stop the gravity
				end
			else
				self.jumpLowGravity = false
			end
			
			if contactAmout > 0 then
				self.coyoteTimer:Reset()
			end
			
			local newAirboneState = self.coyoteTimer:IsPastSimMS(self.coyoteTime)
			if self.airbone == true and newAirboneState == false then
				self.landedTimer:Reset()
				self.wallJumps = 0
			end
			
			self.airbone = newAirboneState
			
			
			-- Slide
			if ctrl:IsState(Controller.BODY_CROUCH) and not self.airbone and not self.groundSlamSlideLock then
				local v = self.walkSpeed * TimerMan.DeltaTimeSecs / math.max(contactAmoutMax, 1) * contactAmout
				self.Vel = self.Vel + Vector(0, v * 0.6):RadRotate(self.surfaceNormalAngle)
				self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(-self.RotAngle)
				self.Vel = Vector(self.Vel.X, self.Vel.Y + math.max(-self.Vel.Y, 0) * TimerMan.DeltaTimeSecs * 2.0)
				self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(self.RotAngle)
				
				local min_value = -math.pi;
				local max_value = math.pi;
				local value = self.surfaceNormalAngle
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
				
				-- Ramp magic forces
				local rampFactor = math.min(math.max(math.deg(result) * self.FlipFactor / 30, 0), 1)
				local rampForce = -2 * rampFactor * TimerMan.DeltaTimeSecs
				
				--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, -90), "rampFactor = ".. math.floor(rampFactor * 100) / 100, true, 0);
				
				self.Vel = self.Vel + Vector(v * 0.3 * self.FlipFactor * rampFactor, rampForce):RadRotate(self.surfaceNormalAngle)
				
				
				if self.soundSlide:IsBeingPlayed() then
					self.soundSlide.Pos = self.Pos
				else
					self.soundSlide:Play(self.Pos)
				end
				
				if not self.sliding then
					self.soundSlideStart:Play(self.Pos)
					self.sliding = true
					self.Vel = self.Vel + Vector(v * 5 * self.FlipFactor, 0):RadRotate(self.surfaceNormalAngle)
				end
			else
				self.soundSlide:Stop()
				if self.sliding then
					if not self.airbone then
						self.soundSlideStop:Play(self.Pos)
					end
					self.sliding = false
				end
			end
			
			-- Run
			--local targetVel = self.walkSpeed / math.max(contactAmoutMax, 1) * contactAmout * input * math.pow(minLegLift, 2) * 1.5
			local targetVel = self.walkSpeed * input * math.pow(minLegLift, 2) * 0.50
			local targetSlideVel = self.walkSpeed * self.FlipFactor * math.pow(minLegLift, 2) * 0.475
			
			local diff = (targetVel - self.Vel.X) * TimerMan.DeltaTimeSecs * 5 -- 30
			local diffSlide = (targetSlideVel - self.Vel.X) * TimerMan.DeltaTimeSecs * 7.5 -- 30
			
			if self.airbone then
				diff = diff * 1.3
			else
				targetVel = targetVel * 1.5
			end
			
			if self.sliding then
				self.Vel = self.Vel + Vector(diffSlide / math.max(contactAmoutMax, 1) * (contactAmout + 1) / 3, 0):RadRotate(self.surfaceNormalAngle)-- + --Vector(v, 0)
			else
				
				if input ~= 0 then-- and (diff / math.abs(diff)) == self.FlipFactor then
					local brake = math.abs(input - mathSign(self.Vel.X)) * 0.5 + 0.75
					
					self.Vel = self.Vel + Vector(diff / math.max(contactAmoutMax, 1) * (contactAmout + 1) / 3, 0):RadRotate(self.surfaceNormalAngle)-- + --Vector(v, 0)
					self.Vel = Vector(self.Vel.X / (1 + (TimerMan.DeltaTimeSecs * 5 / math.max(contactAmoutMax, 1) * contactAmout) * brake), self.Vel.Y) -- Friction
				else
					self.Vel = Vector(self.Vel.X / (1 + (TimerMan.DeltaTimeSecs * 16 / math.max(contactAmoutMax, 1) * contactAmout)), self.Vel.Y) -- Friction
				end
			end
			
		end
		
		ctrl:SetState(Controller.BODY_CROUCH,false)
	end
	
	-- Style factor! 
	local reset = not (self.airbone or self.sliding or self.dashing or self.groundSlamming)
	
	if not reset then
		self.styleMovementFactor = math.min(self.styleMovementFactor + TimerMan.DeltaTimeSecs * 0.9, 1)
	else
		self.styleMovementFactor = math.max(self.styleMovementFactor - TimerMan.DeltaTimeSecs * 3, 0)
	end
	self:SetNumberValue("MovementFactor", self.styleMovementFactor)
	--
	
	-- Balance
	local balanceStrength = self.bodyBalance
	local surfaceBend = 1
	local lean = math.rad(math.min(math.max(self.Vel.X * 2.0, -90), 90));
	if self.airbone then
		lean = lean * -(math.min((self.coyoteTimer.ElapsedSimTimeMS - self.coyoteTime) / 800, 1) - 0.5) * 3.0
	end
	if self.sliding then
		lean = lean * -0.5
	end
	if self.groundSlamming then
		lean = 0
		balanceStrength = balanceStrength * 3
		surfaceBend = 0
	end
	
	local min_value = -math.pi;
	local max_value = math.pi;
	local value = self.RotAngle + lean - self.surfaceNormalAngle * surfaceBend
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
	
	self.RotAngle = (self.RotAngle - result * TimerMan.DeltaTimeSecs * 4 * balanceStrength)
	self.AngularVel = (self.AngularVel - result * TimerMan.DeltaTimeSecs * (10 + 15 * contactAmout) * balanceStrength)
	self.AngularVel = (self.AngularVel) / (1 + TimerMan.DeltaTimeSecs * 22.5 * balanceStrength)-- - self.Vel.X * TimerMan.DeltaTimeSecs * 6
	
	
	if self.lastHealth ~= self.Health then
		if self.Health < self.lastHealth then
			if not self.soundHurt:IsBeingPlayed() then
				self.soundHurt:Play(self.Pos)
			end
			self.hardDamage = math.min(self.hardDamage + math.abs(self.Health - self.lastHealth) * self.hardDamageDamageMultiplier, self.MaxHealth - self.Health)
			self.hardDamageRegenerationTimer:Reset()
			
			self.healthHUDAnimation = math.max(self.healthHUDAnimation - 0.5, -1)
		else
			self.healthHUDAnimation = math.min(self.healthHUDAnimation + 0.2, 1)
		end
		
		self.lastHealth = self.Health
	end
	
	if self.hardDamageRegenerationTimer:IsPastSimMS(self.hardDamageRegenerationDelay) then
		self.hardDamage = math.max(self.hardDamage - TimerMan.DeltaTimeSecs * 8, 0)
	end
	
	if not self.dashing and not self.sliding then
		self.stamina = math.max(math.min(self.stamina + TimerMan.DeltaTimeSecs * 0.75, 3), 0)
	end
end

function OnCollideWithTerrain(self, terrainID)
	--if self.Status == Actor.DEAD or self.Status == Actor.DYING then 
	--end
	
	-- Custom move out of terrain script, EXPERIMENTAL
	local radius = self.IndividualRadius
	--PrimitiveMan:DrawCirclePrimitive(self.Pos, radius, 13);
	local maxi = 6
	for i = 1, maxi do
		local offset = Vector(radius, 0):RadRotate(((math.pi * 2) / maxi) * i)
		local endPos = self.Pos + offset; -- This value is going to be overriden by function below, this is the end of the ray
		self.ray = SceneMan:CastObstacleRay(self.Pos + offset, offset * -1.0, Vector(0, 0), endPos, 0 , self.Team, 0, 1)
		if self.ray == 0 then
			--self.Pos = self.Pos - offset * 0.1;
			self.Pos = self.Pos - offset * 0.01;
			self.Vel = self.Vel * 0.8 - offset * 0.05;
			
			self.dashing = false
		end
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, self.Pos - offset, 46);
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, endPos, 116);
	end
	
	if self.dead then
		if self.Vel.Magnitude > 10 then
			for attachable in self.Attachables do
				if string.find(attachable.PresetName, "Wings") then
					attachable:GibThis()
				end
			end
			self:GibThis()
		end
		
		-- EXPERIMENTAL BETTER RAGDOLL
		local radius = self.Radius * 0.9
		
		local min_value = -math.pi;
		local max_value = math.pi;
		local value = self.RotAngle
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
		
		local str = math.max(1 - math.abs(result / math.pi * 2.0), 0)
		--local normal = Vector(0,0)
		--local slide = false
		
		-- Trip on the ground
		for j = 0, 1 do
			local pos = self.Pos + Vector(0, -3):RadRotate(self.RotAngle)
			if self.Head and math.random(1,2) < 2 then
				pos = self.Head.Pos
			end
			
			local maxi = 6
			for i = 0, maxi do
				local checkVec = Vector(radius * (0.7 - 0.2 * j),0):RadRotate(math.pi * 2 / maxi * i + self.RotAngle)
				local checkOrigin = Vector(pos.X, pos.Y) + checkVec + Vector(self.Vel.X, self.Vel.Y) * rte.PxTravelledPerFrame * 0.3
				local checkPix = SceneMan:GetTerrMatter(checkOrigin.X, checkOrigin.Y)
				
				if checkPix > 0 then
					self.Vel = self.Vel - Vector(checkVec.X, checkVec.Y):SetMagnitude(30 * str) * TimerMan.DeltaTimeSecs
					self.AngularVel = self.AngularVel + (self.AngularVel / math.abs(self.AngularVel)) * str * 20 * TimerMan.DeltaTimeSecs
					
					--normal = normal + checkVec
					--slide = true
				end
			end
			
		end
		-- EXPERIMENTAL BETTER RAGDOLL
		
		self.legSpring = 0
		self.bodyBalance = 0
	end
end

function Destroy(self)
	self.soundSlide:Stop()
	self.soundFalling:Stop()
end