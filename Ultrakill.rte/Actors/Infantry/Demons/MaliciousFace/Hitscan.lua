
function Create(self)
	self.lastPos = nil; -- Important stuff
	self.lastPosList = {}
	
	self.raycast = true; -- Make sure to raycast once
	
	self.normalizedVel = Vector(1, 0):RadRotate(self.RotAngle); -- Get rotation and use this as direction (no more fucked up trajectory when flying)
	--self.normalizedVel = Vector(self.Vel.X,self.Vel.Y):SetMagnitude(1); -- Get starting velocity and use this as direction (unreliable, please replace)
	self.PinStrength = 1000; -- Stop
	self.Vel = Vector(0, 0); -- Stop even more
	
	self.coinDetectionRadius = 10
	
	self.soundRicochet = CreateSoundContainer("Bullet Marksman Ricochet", "Ultrakill.rte")
	self.soundRicochet.Pitch = 2.0
	
	self.state = 0
	
	self.ricochet = false
	self.done = false
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
							
							self.soundRicochet:Play(self.Pos)
							
							self.Lifetime = self.Lifetime + 50
							
							mo.ToDelete = true
							mo.Sharpness = 0
							mo.Vel = mo.Vel * 0.5
							mo.GlobalAccScalar = 1.5
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
			-- Reflect at the owner
			self.Team = -1
		end
	end
	
	if self.state == 0 or self.state == 2 then
		
		if self.raycast == true then -- Do the magic stuff
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
			end
			
			if not hit then
				local terrCheck = SceneMan:CastStrengthSumRay(rayOrigin, rayOrigin + rayVec, 2, 0); -- Raycast
				if terrCheck > 5 then
					local rayHitPos = SceneMan:GetLastRayHitPos()
					
					self.Pos = rayHitPos
					
					hit = true
				end
			end
			
			
			if hit then
				-- BOOM!
				local boom = CreateMOSRotating("Malicious Face Laser Blast", "Ultrakill.rte")
				boom.Pos = self.Pos - Vector(self.normalizedVel.X,self.normalizedVel.Y):SetMagnitude(5)
				MovableMan:AddParticle(boom)
				boom:GibThis()
			else
				self.Pos = self.Pos + rayVec
			end
			
			self.raycast = false
		end
	end
	
	--The Line
	local colors = {244, 122, 47, 96, 110, 94}
	local color
	if self.ricochet then
		color = 244
	else
		color = colors[math.floor((self.Age / (self.Lifetime)) * #colors)]
		if not color then
			color = colors[1]
		end
	end
	
	if self.Age < (self.Lifetime) then
		local maxi = 1
		if (self.Age > self.Lifetime * 0.15 and self.Age < self.Lifetime * 0.5) then
			local factor = (self.Age - self.Lifetime * 0.15) / (self.Lifetime * 0.5)
			factor = 1 + math.sin(factor * math.pi)
			maxi = 2 * factor
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