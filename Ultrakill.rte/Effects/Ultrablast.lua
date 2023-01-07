-- Fermat Spiral script shamelessly stolen from 4zK who also stole it form CaveCricket48
-- CaveCricket48, great man with great ambitions, cheers
-- 4zK too ofc

function Create(self)
	self.strength = self.Mass * 150;
	self.range = 5 * self.Vel.Magnitude;
	
	self.Lifetime = 1000
	
	self.pointCount = math.floor(2 * self.range);	-- Number of points
	self.spiralScale = self.range / math.sqrt(self.pointCount);	-- Size of the spiral
	self.skipPoints = 2;	-- Skip first points (radius: points inside the object itself)
	
	self.kaboom = true
	
	self.shake = 100
	
	self.ToSettle = false
end
function Update(self)
	--PrimitiveMan:DrawCirclePrimitive(self.Pos, self.range, 5)
	local lifetimeFactor = math.pow((self.Lifetime - self.Age) / self.Lifetime, 2)
	
	--TimerMan.TimeScale = math.min(TimerMan.TimeScale + TimerMan.DeltaTimeSecs * 4, 1)
	
	-- Shake
	if self.shakeTable then
		for i = 1, #self.shakeTable do
			local actor = self.shakeTable[i];
			if actor and IsActor(actor) then
				actor = ToActor(actor)
				local dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, SceneMan.SceneWrapsX).Magnitude
				local distFactor = math.sqrt(1 + dist * 0.03)
				
				actor.ViewPoint = actor.ViewPoint + Vector(self.shake * RangeRand(-1, 1), self.shake * RangeRand(-1, 1)) * lifetimeFactor / distFactor;
			end
		end
	end
	
	if self.kaboom then
		-- Get shake actors
		self.shakeTable = {}
		for actor in MovableMan.Actors do
			actor = ToActor(actor)
			table.insert(self.shakeTable, actor);
		end
		
		-- Freeze time????
		local slowdown = false
		
		-- GFX
		local scale = self.spiralScale;
		for i = self.skipPoints, self.pointCount - 1 do
			local radius = scale * math.sqrt(i);
			local angle = i * 137.508;
			local checkPos = self.Pos + Vector(radius, 0):DegRotate(angle);
			if SceneMan.SceneWrapsX == true then
				if checkPos.X > SceneMan.SceneWidth then
					checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
				elseif checkPos.X < 0 then
					checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
				end
			end
			local color = 254;
			local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
			if terrCheck ~= 0 then
				color = 5;
			end
			
			local rayVec = SceneMan:ShortestDistance(self.Pos, checkPos, SceneMan.SceneWrapsX)
			local ray = SceneMan:CastStrengthRay(self.Pos, rayVec, 10, Vector(), 3, 255, SceneMan.SceneWrapsX)
			if not ray then
				local smoke
				local explosiveness = 2
				local factor = (self.range - rayVec.Magnitude) / self.range
				
				smoke = CreateMOSParticle("Flame Smoke 2 Glow")--CreateMOSParticle("Explosion Smoke 1");
				smoke.Pos = checkPos - Vector(rayVec.X, rayVec.Y) * 0.25
				smoke.Vel = Vector(rayVec.X, rayVec.Y):SetMagnitude(1):RadRotate(RangeRand(-1, 1) * math.pi * 0.25) * RangeRand(0.5, 1) * 15 * (0.5 + factor) * explosiveness
				smoke.AirResistance = smoke.AirResistance * explosiveness
				smoke.Lifetime = (100 + (1 - factor) * 1000) / explosiveness * RangeRand(0.9, 1.5)
				MovableMan:AddParticle(smoke);
				
				local names = {"Explosion Smoke 1", "Fire Puff Medium", "Fire Puff Small"}
				
				smoke = CreateMOSParticle(names[math.random(1, #names)]);
				smoke.Pos = checkPos - Vector(rayVec.X, rayVec.Y) * 0.3
				smoke.Vel = Vector(rayVec.X, rayVec.Y):SetMagnitude(1):RadRotate(RangeRand(-1, 1) * math.pi * 0.25) * RangeRand(0.5, 1) * 5 * explosiveness
				smoke.AirResistance = smoke.AirResistance * 0.05 * explosiveness
				smoke.GlobalAccScalar = 0
				smoke.Lifetime = (500 + (factor) * 1000) / explosiveness * RangeRand(0.9, 1.5)
				MovableMan:AddParticle(smoke);
				
				smoke = CreateMOSParticle("Fire Ball 1");
				smoke.Pos = checkPos - Vector(rayVec.X, rayVec.Y) * 0.1
				smoke.Vel = Vector(rayVec.X, rayVec.Y):SetMagnitude(1):RadRotate(RangeRand(-1, 1) * math.pi * 0.25) * RangeRand(0.5, 1) * 5 * (0.5 + factor) * explosiveness
				smoke.AirResistance = smoke.AirResistance * explosiveness
				smoke.Lifetime = (600 + (1 - factor) * 100) / explosiveness * RangeRand(0.9, 1.3)
				MovableMan:AddParticle(smoke);
				
				--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + rayVec, color);
			 end
		end
		-- PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, self.spiralScale * math.sqrt(self.pointCount) + 7), "pointCount = ".. self.pointCount, true, 0);
		-- PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, self.spiralScale * math.sqrt(self.pointCount) + 14), "spiralScale = ".. self.spiralScale, true, 0);
		-- PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, self.spiralScale * math.sqrt(self.pointCount) + 21), "skipPoints = ".. self.skipPoints, true, 0);
		
		self.kaboom = false
		for i = 1 , MovableMan:GetMOIDCount() - 1 do
			local mo = MovableMan:GetMOFromID(i);
			if mo and mo.PinStrength == 0 then
				local dist = SceneMan:ShortestDistance(self.Pos, mo.Pos, SceneMan.SceneWrapsX);
				if dist.Magnitude < self.range then
					local strSumCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + dist, 3, rte.airID);
					if strSumCheck < self.strength then
						local massFactor = math.sqrt(1 + math.abs(mo.Mass));
						local distFactor = math.sqrt(1 + dist.Magnitude * 0.1)
						local forceVector =	dist:SetMagnitude((self.strength - strSumCheck) /distFactor);
						
						local closeFactor = math.min(dist.Magnitude * 0.02, 1)
						mo.Vel = mo.Vel + forceVector / massFactor * closeFactor;
						mo.AngularVel = mo.AngularVel - forceVector.X /(massFactor + math.abs(mo.AngularVel));
						mo:AddForce(forceVector * massFactor * closeFactor * 12.0, Vector());
						
						if IsActor(mo) then
							mo:AddForce(Vector(0, -math.max(-forceVector.Y, 0) * 0.5 - (math.abs(forceVector.Y) + math.abs(forceVector.X)) * 0.25) * massFactor * closeFactor * 80.0, Vector());
						end
						
						if IsMOSRotating(mo) then
							mo = ToMOSRotating(mo)
							-- 400 - 200
							local wounding = math.pow((self.strength - strSumCheck) / distFactor / 50, 2.0) * 1.3
							local woundName = mo:GetEntryWoundPresetName()
							local woundNameExit = mo:GetExitWoundPresetName()
							if woundName and woundName ~= "" and woundNameExit and woundNameExit ~= "" and math.floor(wounding + 0.5) > 0 then
								slowdown = true
								for i = 1, math.floor(wounding + 0.5) do
									local wound = CreateAEmitter(woundName)
									if wound then
										local pos = Vector(RangeRand(-1,1),RangeRand(-1,1)) * mo.IndividualRadius * 0.7
										mo:AddWound(wound, pos, true)
										
										if math.random(0, 100) < 50 then
											local smokeWound = CreateAEmitter("Ultrablast Sticky Smoke")
											smokeWound.Lifetime = smokeWound.Lifetime * RangeRand(0.5, 1.5)
											mo:AddWound(smokeWound, pos, false)
										end
										
										if math.random(0, 100) < 30 then
											local fire = CreatePEmitter("Flame Hurt Short Float")
											fire.Pos = mo.Pos + pos
											fire.Vel = Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * 15
											MovableMan:AddParticle(fire);
										end
									end
									
								end
								if wounding > 0.7 and IsActor(mo) and IsAHuman(mo) then
									local act = ToActor(mo)
									if act.Status == 0 then
										act.Status = 1
									end
								end
								
							end
							
							if IsActor(mo) and ((mo.WoundCount + math.floor(wounding + 0.5)) > mo.GibWoundLimit or (ToActor(mo).Health - math.floor(wounding + 0.5) * 2) < 0) then
								mo:SetNumberValue("UltrakillExploded", 1)
							end
							
							if mo.GibImpulseLimit ~= nil and mo.GibImpulseLimit > 0 and (forceVector * massFactor).Magnitude > (mo.GibImpulseLimit * distFactor) * RangeRand(1.3,3) * 1.5 then
								mo:GibThis()
							end
							
						end
					end
				end
			end	
			
		end
		
		-- Intentional epic slow-mo
		if slowdown and ToGameActivity(ActivityMan:GetActivity()).PresetName == "ULTRAKILL: INFINITE HYPERDEATH" then
			TimerMan.TimeScale = RangeRand(0.5, 0.25)
		end
	end
	
	self.ToSettle = false
	--self.ToDelete = true;
end