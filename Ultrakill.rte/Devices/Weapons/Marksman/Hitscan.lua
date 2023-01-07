
function Create(self)
	self.lastPos = nil; -- Important stuff
	self.lastPosList = {}
	
	self.raycast = true; -- Make sure to raycast once
	
	self.normalizedVel = Vector(1, 0):RadRotate(self.RotAngle); -- Get rotation and use this as direction (no more fucked up trajectory when flying)
	--self.normalizedVel = Vector(self.Vel.X,self.Vel.Y):SetMagnitude(1); -- Get starting velocity and use this as direction (unreliable, please replace)
	self.PinStrength = 1000; -- Stop
	self.Vel = Vector(0, 0); -- Stop even more
	
	self.damage = 2
	
	self.coinDetectionRadius = 10
	self.coinOriginalID = -1
	
	self.state = 0
	if self:NumberValueExists("HitscanState") then
		self.state = self:GetNumberValue("HitscanState")
	end
	
	self.split = false
	self.isSplitshot = false
	if self:NumberValueExists("HitscanSplitshot") then
		self.isSplitshot = true
	end
	
	self.ignoreIDs = {}
	if self:NumberValueExists("HitscanIgnoreIDAmount") then
		for i = 1, self:GetNumberValue("HitscanIgnoreIDAmount") do
			table.insert(self.ignoreIDs, self:GetNumberValue("HitscanIgnoreID"..i))
		end
	end
	
	self.soundRicochet = CreateSoundContainer("Bullet Marksman Ricochet", "Ultrakill.rte")
	self.soundRicochet.Pitch = 3.0
	
	self.ricochet = false
	self.done = false
	
	self.coinBounces = 0
	
	self.piercing = self:NumberValueExists("Piercer")
	self.piercingI = 0
	self.pierceTimer = Timer()
	
	if self.piercing then
		self.piercingI = 4
		self.Lifetime = self.Lifetime * 3.5
	end
	
	-- self.particlePerMetre = 2.0 -- This variable defines quality of the trail, higher number --> more particles, lower number --> less particles
end

function Update(self)
	if self.lastPos == nil then
		self.lastPos = Vector(self.Pos.X,self.Pos.Y) - self.normalizedVel * 2.0; -- Important stuff, get the starting pos for hitscan stuff
		table.insert(self.lastPosList, Vector(self.lastPos.X, self.lastPos.Y))
	end
	
	
	if not self.done then
		
		if self.state == 0 then
			
			for mo in MovableMan.Particles do
				
				if mo and mo.HitsMOs == true and mo.Sharpness > 0 and mo.PresetName == "Coin Marksman" then
					
					--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + SceneMan:ShortestDistance(self.Pos, mo.Pos,SceneMan.SceneWrapsX), 5);
					--PrimitiveMan:DrawCirclePrimitive(mo.Pos, self.coinDetectionRadius, 5)
					
					local coinPos = mo.Pos
					local diff = SceneMan:ShortestDistance(self.Pos, coinPos,SceneMan.SceneWrapsX)
					
					local coinDist = diff.Magnitude
					
					local detectionPoint = Vector(self.Pos.X, self.Pos.Y) + Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(coinDist)
					if SceneMan:ShortestDistance(detectionPoint, coinPos,SceneMan.SceneWrapsX).Magnitude <= self.coinDetectionRadius then
						local terrCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + diff, 2, 0); -- Raycast
						if terrCheck < 2 then
							self.lastPos = Vector(self.Pos.X,self.Pos.Y)
							table.insert(self.lastPosList, Vector(self.lastPos.X, self.lastPos.Y))
							self.Pos = coinPos
							
							if mo.Sharpness > 1 then -- Split shot!
								self.split = true
							end
							
							self.coinBounces = self.coinBounces + 1
							
							self.soundRicochet:Play(self.Pos)
							
							self.Lifetime = self.Lifetime + 50
							
							mo.ToDelete = true
							mo.Sharpness = 0
							mo.Vel = mo.Vel * 0.5
							mo.GlobalAccScalar = 1.5
							
							self.damage = self.damage + 2
							
							self.state = 1
							
							self.coinOriginalID = mo.UniqueID
							self.ricochet = true
							break
						end
						
					end
				end
			end
			
			if self.state ~= 1 then
				self.done = true
			end
		elseif self.state == 1 then
			
			local splitProjectile
			if self.split then
				-- print("I DID SPLIT!")
				splitProjectile = CreateMOSRotating("Bullet Marksman", "Ultrakill.rte")
				splitProjectile.Pos = self.Pos;
				splitProjectile.Team = self.Team
				splitProjectile.IgnoresTeamHits = true
				splitProjectile:SetNumberValue("HitscanState", 1)
				splitProjectile:SetNumberValue("HitscanSplitshot", 1)
				MovableMan:AddParticle(splitProjectile);
				
				self.split = false
			end
			
			
			local targetsEnemy = {}
			local targetsCoin = {}
			local targetsGrenades = {}
			
			for mo in MovableMan.Particles do
				if mo and self.coinOriginalID ~= mo.UniqueID and mo.HitsMOs == true and mo.Sharpness > 0 and mo.PresetName == "Coin Marksman" then
					local valid = true
					
					for i, ID in ipairs(self.ignoreIDs) do
						if ID == mo.UniqueID then
							valid = false
							break
						end
					end
					if valid then
						
						local coinPos = mo.Pos
						local diff = SceneMan:ShortestDistance(self.Pos, coinPos,SceneMan.SceneWrapsX)
						
						local terrCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + diff, 2, 0); -- Raycast
						if terrCheck < 2 then
							table.insert(targetsCoin, {mo, diff.Magnitude})
						end
					end
					
				end
			end
			
			for mo in MovableMan.Particles do
				if mo and mo.HitsMOs == true and mo.UniqueID ~= self.UniqueID and mo.Mass > 0 and (mo.ClassName ~= "MOPixel" and mo.ClassName ~= "MOSParticle") and (
				string.find(mo.PresetName, "RPG-7") or
				string.find(mo.PresetName, "RPG") or
				string.find(mo.PresetName, "Bomb") or
				string.find(mo.PresetName, "Grenade") or
				string.find(mo.PresetName, "Rocket") or
				string.find(mo.PresetName, "Missle") or
				string.find(mo.PresetName, "RPG-7") or
				string.find(mo.PresetName, "Launcher") or
				string.find(mo.PresetName, "Flash") or
				string.find(mo.PresetName, "Shot")
--				or (
--				(string.find(mo.PresetName, "Cannon") and string.find(mo.PresetName, "Launch")) or (
--				not string.find(mo.PresetName, "Shell") and
--				not string.find(mo.PresetName, "Casing")))) then
				) then
				
					local valid = true
					
					for i, ID in ipairs(self.ignoreIDs) do
						if ID == mo.UniqueID then
							valid = false
							break
						end
					end
					if valid then
						if IsMOSRotating(mo) then
							mo = ToMOSRotating(mo)
							valid = true
						elseif IsAEmitter(mo) then
							mo = ToAEmitter(mo)
							valid = true
						else
							valid = false
						end
						
						if mo:GetParent() then
							valid = false
						end
					end
					
					if valid then
						local grenadePos = mo.Pos
						local diff = SceneMan:ShortestDistance(self.Pos, grenadePos,SceneMan.SceneWrapsX)
						
						local terrCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + diff, 2, 0); -- Raycast
						if terrCheck < 2 then
							table.insert(targetsGrenades, {mo, diff.Magnitude})
						end
					end
					
				end
			end
			
			for actor in MovableMan.Actors do
				actor = ToActor(actor)
				if actor.Team ~= self.Team and actor.Health > 0 then
					
					local valid = true
					
					for i, ID in ipairs(self.ignoreIDs) do
						if ID == actor.UniqueID then
							valid = false
							break
						end
					end
					if valid then
						
						local head = false
						if IsAHuman(actor) then
							actor = ToAHuman(actor)
							
							local diff = SceneMan:ShortestDistance(self.Pos, actor.Head.Pos,SceneMan.SceneWrapsX)
							local terrCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + diff, 2, 0); -- Raycast
							if terrCheck < 2 then
								head = true
								table.insert(targetsEnemy, {actor.Head.Pos, diff.Magnitude, actor})
							end
						end
						
						if not head then
							local diff = SceneMan:ShortestDistance(self.Pos, actor.Pos,SceneMan.SceneWrapsX)
							local terrCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + diff, 2, 0); -- Raycast
							if terrCheck < 2 then
								table.insert(targetsEnemy, {actor.Pos, diff.Magnitude, actor})
							end
						end
						
					end
					
				end
				
			end
			
			if #targetsCoin > 0 and not self.isSplitshot then
				local closest = nil
				local closestDist = math.huge
				for i, coin in ipairs(targetsCoin) do
					local dist = coin[2]
					if not closest or dist < closestDist then
						closest = coin[1]
						closestDist = dist
					end
				end
				
				if closest then
					table.insert(self.ignoreIDs, closest.UniqueID)
					
					if closest.Sharpness == 2 then -- Split shot!
						self.split = true
					end
					
					if self.split and #targetsEnemy > 0 then
						local closestActor = nil
						local closestDist = math.huge
						for i, enemy in ipairs(targetsEnemy) do
							local dist = enemy[2]
							if not closest or dist < closestDist then
								closestActor = enemy[3]
								closestDist = dist
							end
						end
						
						if closestActor then
							table.insert(self.ignoreIDs, closestActor.UniqueID)
						end
					end
					
					self.coinBounces = self.coinBounces + 1
					
					self.lastPos = Vector(self.Pos.X,self.Pos.Y)
					table.insert(self.lastPosList, Vector(self.lastPos.X, self.lastPos.Y))
					self.Pos = closest.Pos
					
					self.Lifetime = self.Lifetime + 50
					
					self.soundRicochet.Pitch = self.soundRicochet.Pitch *2
					self.soundRicochet:Play(self.Pos)
					
					closest.ToDelete = true
					closest.Sharpness = 0
					closest.Vel = closest.Vel * 0.5
					closest.GlobalAccScalar = 1.5
					
					self.damage = self.damage + 2
					
					self.state = 1
				end
			elseif #targetsGrenades > 0 then
				local closest = nil
				local closestDist = math.huge
				for i, grenade in ipairs(targetsGrenades) do
					local dist = grenade[2]
					if (not closest or dist < closestDist) then-- and (closest and closest.UniqueID ~= self.UniqueID) then
						closest = grenade[1]
						closestDist = dist
					end
				end
				
				if closest then
					
					table.insert(self.ignoreIDs, closest.UniqueID)
					
					self.lastPos = Vector(self.Pos.X,self.Pos.Y)
					table.insert(self.lastPosList, Vector(self.lastPos.X, self.lastPos.Y))
					self.Pos = Vector(closest.Pos.X, closest.Pos.Y)
					
					self.Lifetime = self.Lifetime + 50
					
					self.soundRicochet.Pitch = self.soundRicochet.Pitch * 3
					self.soundRicochet:Play(self.Pos)
					
					closest:GibThis()
					closest.ToDelete = true
					
					self.state = -1
					self.done = true
				end
			elseif #targetsEnemy > 0 then
				
				local closestActor = nil
				local closest = nil
				local closestDist = math.huge
				for i, enemy in ipairs(targetsEnemy) do
					local dist = enemy[2]
					if not closest or dist < closestDist then
						closest = enemy[1]
						closestActor = enemy[3]
						closestDist = dist
					end
				end
				
				if closest then
					table.insert(self.ignoreIDs, closestActor.UniqueID)
					
					self.lastPos = Vector(self.Pos.X,self.Pos.Y)
					table.insert(self.lastPosList, Vector(self.lastPos.X, self.lastPos.Y))
					
					self.state = 2
					self.RotAngle = SceneMan:ShortestDistance(self.Pos, closest, SceneMan.SceneWrapsX).AbsRadAngle
					self.normalizedVel = Vector(1, 0):RadRotate(self.RotAngle)
					
					if UltrakillStyle then
						if self.coinBounces < 2 then
							table.insert(UltrakillStyle.StyleToAdd, {30, "RICOSHOT", true})
						else
							table.insert(UltrakillStyle.StyleToAdd, {30 + 7 * (self.coinBounces - 1), "RICOSHOT x("..self.coinBounces..")", true})
						end
					end
				end
			else
				
				self.lastPos = Vector(self.Pos.X,self.Pos.Y)
				table.insert(self.lastPosList, Vector(self.lastPos.X, self.lastPos.Y))
				
				self.state = 2
				self.RotAngle = math.pi * RangeRand(-2, 2)
				self.normalizedVel = Vector(1, 0):RadRotate(self.RotAngle)
				
				self.done = true
			end
			
			-- Add exceptions to the split shot!
			if splitProjectile and #self.ignoreIDs > 0 then
				splitProjectile:SetNumberValue("HitscanIgnoreIDAmount", #self.ignoreIDs)
				for i = 1, #self.ignoreIDs do
					-- print(#self.ignoreIDs)
					-- print(self.ignoreIDs[i])
					splitProjectile:SetNumberValue("HitscanIgnoreID"..i, self.ignoreIDs[i])
				end
				
			end
		end
	end
	
	if self.state == 0 or self.state == 2 then
		
		if self.raycast == true or (self.piercingI > 0 and self.pierceTimer:IsPastSimMS(70)) then -- Do the magic stuff
			self.Pos = self.Pos - Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(5) -- Offset back
			
			local hit = false
			
			local rayOrigin = Vector(self.Pos.X, self.Pos.Y);
			local rayVec = Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(60 * GetPPM());
			
			local moCheck = SceneMan:CastMORay(rayOrigin, rayVec, self.ID, self.Team, 0, false, 1); -- Raycast
			if moCheck ~= rte.NoMOID then
				local rayHitPos = SceneMan:GetLastRayHitPos()
				local MO = MovableMan:GetMOFromID(moCheck)
				
				self.Pos = rayHitPos

				hit = true
				
				if IsMOSRotating(MO) then
					MO = ToMOSRotating(MO)
					
					if not string.find(MO.PresetName, "Head") then
						self.damage = math.max(math.floor(self.damage * 0.75), 1)
					end
					local ignoreArmor = false
					if string.find(MO.PresetName, "Helmet") or string.find(MO.PresetName, "Hat") or string.find(MO.PresetName, "Ushanka") or string.find(MO.PresetName, "Mask") or string.find(MO.PresetName, "Goggles") or string.find(MO.PresetName, "Armor ") or string.find(MO.PresetName, "Armour ") then
						ignoreArmor = true
						--self.damage = MO.GibWoundLimit
						self.damage = self.damage * 2.0
					end
					--pixel:SetWhichMOToNotHit(self.MOHit, -1)
					
					for i = 1, (self.damage + 1) do
						local pixel = CreateMOPixel("Bullet Marksman Damage", "Ultrakill.rte");
						pixel.Vel = (Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(120)):RadRotate(math.pi * RangeRand(-0.15, 0.15));
						pixel.Pos = self.Pos - Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(5);
						pixel.Team = self.Team -- It doesn't work, somehow
						pixel.IgnoresTeamHits = true;
						MovableMan:AddParticle(pixel);
						if ignoreArmor then
							pixel:SetWhichMOToNotHit(MO, -1)
						end
						
					end
					
					if self.piercingI > 0 then
						self.Pos = self.Pos + Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(MO.IndividualRadius * RangeRand(0.2, 0.75))
						
						if ToGameActivity(ActivityMan:GetActivity()).PresetName == "ULTRAKILL: INFINITE HYPERDEATH" then
							TimerMan.TimeScale = RangeRand(0.5, 0.7)
						end
					end
					
					local actor
					if IsActor(MO) then
						actor = ToActor(MO)
					end
					local parent = MO:GetRootParent()
					if IsActor(parent) then
						actor = ToActor(parent)
					end
					
					if actor then
						actor:SetNumberValue("UltrakillHitscanned", actor.Age)
					end
					
				end
			end
			
			if not hit then
				local terrCheck = SceneMan:CastStrengthSumRay(rayOrigin, rayOrigin + rayVec, 2, 0); -- Raycast
				if terrCheck > 5 then
					local rayHitPos = SceneMan:GetLastRayHitPos()
					
					self.Pos = rayHitPos
					
					hit = true
				end
			end
			
			
			--self.impactSound:Play(self.Pos)
			
			-- Damage, create a pixel that makes a hole
			
			-- Add addational particles - the yellow sparks and more
			if hit then
				for i = 1, 3 do
					local bzzt = CreateMOPixel("Spark Yellow 1");
					bzzt.Pos = self.Pos - Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(5);
					bzzt.Vel = (Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(1)):RadRotate(math.pi * RangeRand(-0.3, 0.3)) * RangeRand(0.5, 1.0) * -50.0;
					bzzt.GlobalAccScalar = 1.0;
					bzzt.Lifetime = bzzt.Lifetime * RangeRand(0.6, 1.6) * 10.5;
					MovableMan:AddParticle(bzzt);
					
					bzzt = CreateMOPixel("Spark Yellow 2");
					bzzt.Pos = self.Pos - Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(5);
					bzzt.Vel = (Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(1)):RadRotate(math.pi * RangeRand(-0.6, 0.6)) * RangeRand(0.5, 1.0) * -20.0;
					bzzt.GlobalAccScalar = 1.0;
					bzzt.Lifetime = bzzt.Lifetime * RangeRand(0.6, 1.6) * 6.5;
					MovableMan:AddParticle(bzzt);
					
					local buh = CreateMOSParticle("Small Smoke Ball 1");
					buh.Pos = self.Pos - Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(5);
					buh.Vel = (Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(1)):RadRotate(math.pi * RangeRand(-0.3, 0.3)) * RangeRand(0.5, 1.0) * -20.0;
					buh.Lifetime = buh.Lifetime * RangeRand(0.6, 1.6) * 0.5;
					MovableMan:AddParticle(buh);
				end
			else
				self.Pos = self.Pos + rayVec
			end
			
			self.raycast = false
			
			self.pierceTimer:Reset()
			if self.piercingI > 0 then
				
				self.lastPos = Vector(self.Pos.X,self.Pos.Y)
				table.insert(self.lastPosList, Vector(self.lastPos.X, self.lastPos.Y))
				
				self.piercingI = self.piercingI - 1
			end
		end
	end
	
	--The Line
	local colors = {120, 122, 99, 96, 110, 94}
	if self.piercing then
		colors = {4, 5, 198, 96, 215, 209}
	end
	local color
	if self.ricochet then
		if self.piercing then
			color = 5
		else
			color = 120
		end
	else
		color = colors[math.floor((self.Age / (self.Lifetime)) * #colors)]
		if not color then
			color = colors[1]
		end
	end
	
	if self.Age < (self.Lifetime) then
		local maxi = 1
		if (self.Age > self.Lifetime * 0.15 and self.Age < self.Lifetime * 0.5) then
			maxi = 3
			if self.piercing then
				local factor = (self.Age - self.Lifetime * 0.15) / (self.Lifetime * 0.5)
				factor = 1 + math.sin(factor * math.pi)
				maxi = 2 * factor
			end
		end
		
		for i = 1, maxi do
			local factor = (((i - 0.5) / maxi) - 0.5) * 2.0
			local offset = Vector(0, factor * maxi * 0.5):RadRotate(self.RotAngle)
			
			if #self.lastPosList > 2 then
				local maxj = #self.lastPosList
				for j = 1, maxj do
					local nextj = j + 1
					local posA = self.lastPosList[j]
					local posB = self.Pos
					if nextj <= maxj then
						posB = self.lastPosList[nextj]
					end
					
					PrimitiveMan:DrawLinePrimitive(posA + offset, posA + SceneMan:ShortestDistance(posA,posB,SceneMan.SceneWrapsX) + offset, color);
				end
			else
				local posA = self.lastPosList[1]
				local posB = self.Pos
				PrimitiveMan:DrawLinePrimitive(posA + offset, posA + SceneMan:ShortestDistance(posA,posB,SceneMan.SceneWrapsX) + offset, color);
			end
			
			--PrimitiveMan:DrawLinePrimitive(self.lastPos + offset, self.lastPos + SceneMan:ShortestDistance(self.lastPos,self.Pos,SceneMan.SceneWrapsX) + offset, color);
		end
		
	end
end

function OnCollideWithTerrain(self, terrainID) -- I'm not sure why did I put it here
  self.ToDelete = true;
  self.raycast = false;
end