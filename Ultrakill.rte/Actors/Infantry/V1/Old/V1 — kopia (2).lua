
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
	point = point:SetMagnitude(math.min(point.Magnitude, l1 + l2 - 0.001))
	
	local q1, q2 = 0
	local x = point.X
	local y = point.Y
	
	q2 = math.acos((x*x + y*y - l1*l1 - l2*l2)/(2 * l1 * l2))
	q1 = math.atan2(y, x) - math.atan2((l2 * math.sin(q2)), (l1 + l2 * math.cos(q2)))
	
	return {q1, q2}
end

function Create(self)
	--self.InheritedRotAngleOffset
	
	self.soundFootstep = CreateSoundContainer("V1 Movement Footstep", "Ultrakill.rte");
	self.soundJump = CreateSoundContainer("V1 Movement Jump", "Ultrakill.rte");
	self.soundLanding = CreateSoundContainer("V1 Movement Landing", "Ultrakill.rte");
	
	
	self.rayOrigins = {Vector(-2,5), Vector(3,5)}
	
	self.legs = {}
	self.legFeetContact = {false, false}
	self.legFeetContactTimer = {Timer(), Timer()}
	self.legLengthThigh = 8
	self.legLengthShin = 8
	
	self.legFeetSoundTimer = {Timer(), Timer()}
	self.legFeetLandSoundTimer = Timer();
	
	self.walkAnimationAcc = 0 -- "accumulator"
	self.walkFactorCont = 0
	
	self.jumping = false
	self.jump = false
	self.jumpTimer = Timer()
	self.jumpCooldown = 500
	
	self.airbone = false
	
	self.coyoteTimer = Timer()
	self.coyoteTime = 100 -- makes jumping feel more responsive, just google "platformer coyote time"
	
	self.flipTimer = Timer()
	self.flipDelay = 100
	
	-- Movement Settings
	self.jumpForce = 10
	
	self.walkSpeed = 70
end

function Update(self)
	
	local ctrl = self:GetController()
	local player = false
	if self:IsPlayerControlled() then
		player = true
	end
	
	local legIndex = 0
	for limb in self.Attachables do
		if string.find(limb.PresetName, "Leg") then
			legIndex = legIndex + 1
			self.legs[legIndex] = limb
			
			--limb:RemoveWounds(limb.WoundCount)
		end
	end
	local contactAmoutMax = legIndex
	
	-- for i, leg in ipairs(self.legs) do
		-- local thigh = leg
		-- local shin
		-- for mo in thigh.Attachables do
			-- shin = mo
			-- break
		-- end
		-- local angles = calcIK(self.legLengthThigh, self.legLengthShin, Vector(1, 1))
		-- thigh.InheritedRotAngleOffset = -angles[1]
		-- shin.InheritedRotAngleOffset = -angles[2]
	-- end
	
	-- Accumulator
	local walkAcc = self.Vel.X * 0.8
	
	-- Raycast/Legs/Terrain detection
	local terrCont = {}
	
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
		
			local offset = Vector(self.rayOrigins[i].X, self.rayOrigins[i].Y)
			local rayLength = self.legLengthThigh + self.legLengthShin + 2
			if thigh and shin then
				
				-- math.max(math.sin(self.walkAnimationAcc * math.pi + math.pi * (i-1)) * mathSign(walkAcc), 0) * mathSign(walkAcc)
				-- Absolue mathematical and programming clusterf#ck
				local walkSin = math.sin(self.walkAnimationAcc * math.pi + math.pi * (i-1)) + math.min(math.sin(self.walkAnimationAcc * math.pi + math.pi * (i-1)) * mathSign(walkAcc), 0) * mathSign(walkAcc) * 1.0
				--walkSin = walkSin * self.FlipFactor
				walkSin = math.abs(walkSin) * mathSign(walkSin)
				local walkLegLift = 1 * (1 - self.walkFactorCont) + (((math.abs(math.sin(self.walkAnimationAcc * 0.5 * math.pi + math.pi * (i-1) * 0.5)) + 1) / 2)) * self.walkFactorCont
				local walkAngle = walkSin * self.walkFactorCont * 0.4
				
				minLegLift = math.min(minLegLift, walkLegLift)
				
				local rayOrigin = self.Pos + offset:RadRotate(self.RotAngle)--Vector(leg.Pos.X, leg.Pos.Y)
				local rayVector = Vector(self.Vel.X * GetPPM() * TimerMan.DeltaTimeSecs * 2.0, rayLength):RadRotate(self.RotAngle + walkAngle)-- * Vector(self.FlipFactor, 1)
				local terrCheck = SceneMan:CastStrengthRay(rayOrigin, rayVector, 30, Vector(), 0, 0, SceneMan.SceneWrapsX);
				--PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVector,  147);
				local pos = rayOrigin + rayVector
				contactPos[i] = Vector(pos.X, pos.Y)
				contactVec[i] = Vector(rayVector.X, rayVector.Y)
				contactLength[i] = rayLength
				
				
				if terrCheck then
					local hitPos = SceneMan:GetLastRayHitPos()
					local pos = Vector(hitPos.X, hitPos.Y)
					contactAmout = contactAmout + 1
					contactPos[i] = Vector(pos.X, pos.Y)
					contactVec[i] = SceneMan:ShortestDistance(rayOrigin, contactPos[i], SceneMan.SceneWrapsX); --contactPos[i] - rayOrigin
					contactLength[i] = contactVec[i].Magnitude
					
					self.legFeetContactTimer[i]:Reset()
					if self.legFeetContact[i] == false and walkLegLift > 0.85 then
						self.legFeetContact[i] = true
						
						if self.Vel.Y > 10 and self.legFeetLandSoundTimer:IsPastSimMS(500) then
							self.soundLanding:Play(self.Pos)
							
							local terrPixel = SceneMan:GetTerrMatter(pos.X, pos.Y)
							
							if terrPixel ~= 0 then -- 0 = air
								self.soundFootstep:Play(pos)
							end			
							
							self.legFeetLandSoundTimer:Reset();
							
							self.legFeetSoundTimer[1]:Reset();
							self.legFeetSoundTimer[2]:Reset();
						end
						
						if self.legFeetSoundTimer[i]:IsPastSimMS(250) then
							
							local terrPixel = SceneMan:GetTerrMatter(pos.X, pos.Y)
							
							if terrPixel ~= 0 then -- 0 = air
								self.soundFootstep:Play(pos)
							end						
							
							self.legFeetSoundTimer[i]:Reset()
						end
						
					elseif walkLegLift < 0.8 and self.legFeetContact[i] == true then
						self.legFeetContact[i] = false
					end
					
					local fac = math.pow(1 - math.pow(contactLength[i] / rayLength, 3.0), 2.0) * 1.2
					self.Vel = Vector(self.Vel.X, self.Vel.Y / (1 + (TimerMan.DeltaTimeSecs * 1)))
					self.Vel = self.Vel - Vector(contactVec[i].X, contactVec[i].Y):SetMagnitude(fac) * TimerMan.DeltaTimeSecs * math.min(10 + math.min(math.abs(self.Vel.X * 0.6),20), 12) * 3 -- Spring
					--self.Vel = self.Vel - SceneMan.GlobalAcc * (fac + 2) / 3 * TimerMan.DeltaTimeSecs * 0.5 -- Stop the gravity
					self.Vel = self.Vel - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * 0.25 -- Stop the gravity
					
					--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, 10 + 10 * i), "fac"..i.." = "..math.floor(fac * 100), true, 0);
					
					--for i = 0, 3 do
					--	local offset = Vector(2,0):RadRotate(math.pi * 0.5 * i)
					--	PrimitiveMan:DrawLinePrimitive(pos, pos + offset, 13);
					--end
				elseif self.legFeetContactTimer[i]:IsPastSimMS(200) then
					self.legFeetContact[i] = false
				end
				
				
				-- local angle = rayVector.AbsRadAngle + (math.pi * (-self.FlipFactor + 1) / 2)
				-- leg.InheritedRotAngleOffset = angle * self.FlipFactor - self.RotAngle-- + math.pi * (-self.FlipFactor + 1) / 2
				
				local legVec = rayVector * (1.0 - math.max(math.min((1 - (contactLength[i] * walkLegLift / rayLength)), 1.0), 0))
				--legVec:RadRotate(-self.RotAngle)
				legVec = Vector(legVec.X * self.FlipFactor, legVec.Y)
				--legVec:RadRotate(self.RotAngle)
				
				--PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + rayVector, 13);
				--PrimitiveMan:DrawLinePrimitive(rayOrigin, rayOrigin + legVec, 5);
				
				local angles = calcIK(self.legLengthThigh, self.legLengthShin, legVec)
				thigh.InheritedRotAngleOffset = -angles[1] - self.RotAngle
				shin.InheritedRotAngleOffset = -angles[2]
				
				-- local drawPos = Vector(rayOrigin.X, rayOrigin.Y) + Vector(contactVec[i].X, contactVec[i].Y) * walkLegLift
				-- drawPos = Vector(math.floor(drawPos.X), math.floor(drawPos.Y))
				-- for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					-- if not SceneMan:IsUnseen(drawPos.X, drawPos.Y, ActivityMan:GetActivity():GetTeamOfPlayer(player)) then
						-- PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), drawPos, self.legFootSprite, self.RotAngle + rayVector.AbsRadAngle + math.pi * 0.5, 0);
					-- end
				-- end
				
				terrCont[i] = terrCheck
			end
		end
		
	end
	self.walkAnimationAcc = (self.walkAnimationAcc + TimerMan.DeltaTimeSecs * walkAcc / math.max(contactAmoutMax, 1) * contactAmout) % 4
	local walkFactor = math.min(math.abs(self.Vel.X * 0.7), 1) / math.max(contactAmoutMax, 1) * contactAmout
	self.walkFactorCont = (self.walkFactorCont + walkFactor * TimerMan.DeltaTimeSecs * 20) / (1 + TimerMan.DeltaTimeSecs * 20)
	
	self.Vel = self.Vel + Vector(0, -math.max(self.Vel.Y, 0) * TimerMan.DeltaTimeSecs * 15):RadRotate(self.RotAngle) / math.max(contactAmoutMax, 1) * contactAmout -- Deaccelerate Y velocty
	
	if ctrl then
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
		
		
		-- Run
		--local targetVel = self.walkSpeed / math.max(contactAmoutMax, 1) * contactAmout * input * math.pow(minLegLift, 2) * 1.5
		local targetVel = self.walkSpeed * input * math.pow(minLegLift, 2) * 0.50
		local v = self.walkSpeed * TimerMan.DeltaTimeSecs / math.max(contactAmoutMax, 1) * contactAmout
		
		
		local diff = (targetVel - self.Vel.X) * TimerMan.DeltaTimeSecs * 10 -- 30
		
		if not self.airbone then
			targetVel = targetVel * 1.5
		else
			diff = diff * 0.5
		end
		
		if input ~= 0 then-- and (diff / math.abs(diff)) == self.FlipFactor then
			local brake =math.abs(input - mathSign(self.Vel.X)) * 0.5 + 0.75
			
			self.Vel = self.Vel + Vector(diff / math.max(contactAmoutMax, 1) * (contactAmout + 1) / 3, 0)-- + --Vector(v, 0)
			self.Vel = Vector(self.Vel.X / (1 + (TimerMan.DeltaTimeSecs * 5 / math.max(contactAmoutMax, 1) * contactAmout) * brake), self.Vel.Y) -- Friction
		else
			self.Vel = Vector(self.Vel.X / (1 + (TimerMan.DeltaTimeSecs * 8 / math.max(contactAmoutMax, 1) * contactAmout)), self.Vel.Y) -- Friction
		end
		
		-- Jump
		if self.jumpTimer:IsPastSimMS(self.jumpCooldown) then
			if self.jump and ctrl:IsState(Controller.MOVE_UP) and not self.coyoteTimer:IsPastSimMS(self.coyoteTime) then
				self.jumping = true
				self.jump = false
				self.jumpTimer:Reset()
				
				self.soundJump:Play(self.Pos)
				
				self.Vel = self.Vel + Vector(0, -self.jumpForce + math.min(math.max(-self.Vel.Y, 0.0) * 0.35, self.jumpForce * 0.75))
			elseif contactAmout > 0 then
				if not self.jump then
					self.jump = true
					self.jumping = false
					self.Vel = Vector(self.Vel.X, self.Vel.Y * 0.5)
				end
			end
		end
		
		if contactAmout > 0 then
			self.coyoteTimer:Reset()
		end
		
		if self.coyoteTimer:IsPastSimMS(self.coyoteTime) then
			self.airbone = true
		end
		
		if ctrl:IsState(Controller.BODY_CROUCH) then
			self.Vel = self.Vel + Vector(0, v)
		end
		
		ctrl:SetState(Controller.BODY_CROUCH,false)
	end
	
	-- Balance
	local min_value = -math.pi;
	local max_value = math.pi;
	local value = self.RotAngle-- + math.rad(math.min(math.max(self.Vel.X * 3.0, -90), 90));
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
	
	self.RotAngle = (self.RotAngle - result * TimerMan.DeltaTimeSecs * 8)
	self.AngularVel = (self.AngularVel - result * TimerMan.DeltaTimeSecs * (20 + 30 * contactAmout))
	self.AngularVel = (self.AngularVel) / (1 + TimerMan.DeltaTimeSecs * 45)-- - self.Vel.X * TimerMan.DeltaTimeSecs * 6
end

function OnCollideWithTerrain(self, terrainID)
	if self.Status == Actor.DEAD or self.Status == Actor.DYING then 
	end
	
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
		end
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, self.Pos - offset, 46);
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, endPos, 116);
	end
end