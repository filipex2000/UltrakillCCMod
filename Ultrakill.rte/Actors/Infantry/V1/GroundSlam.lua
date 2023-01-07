
function Create(self)
	self.slopeMaxHeight = 20
	self.slopeSkip = 0
	
	self.slamBoxAmount = 20
	self.slamBoxWidth = 10
	self.slamBoxHeight = 30
	
	self.slamBoxData = {}
	self.slamBoxDataIndex = {}
	
	self.spawnEffects = true
	
	-- Move to terrain
	local maxi = 6
	local closestY = math.huge
	for i = -maxi, maxi do
		local pos = self.Pos + Vector(i, 0)
		closestY = math.min(SceneMan:MovePointToGround(pos, 0, 1).Y, closestY)
	end
	self.Pos = Vector(self.Pos.X, closestY)
end

function Update(self)
	if #self.slamBoxDataIndex < 1 then
		for j = 0, 1 do
			local side = (j - 0.5) * 2
			
			local maxi = math.floor(self.slamBoxAmount * 0.5)
			for i = 1, maxi do
				local invalid = false
				local pos = self.Pos + Vector(i * self.slamBoxWidth * side, 0)
				
				local maxe = math.floor(self.slopeMaxHeight / (self.slopeSkip + 1))
				for e = 0, maxe do
					local checkPix = SceneMan:GetTerrMatter(pos.X, pos.Y)
					if checkPix > 0 then
						pos = pos + Vector(0, -(self.slopeSkip + 1))
						invalid = (e == maxe)
					else
						break
					end
				end
				
				if invalid then
					break
				end
				
				local groundPos = SceneMan:MovePointToGround(pos, 0, 1)
				if (groundPos.Y - pos.Y) > self.slopeMaxHeight then
					break
				else
					pos = Vector(groundPos.X, groundPos.Y)
				end
				
				local boxHeight = self.slamBoxHeight / (1 + (math.sqrt(i) - 1))
				
				table.insert(self.slamBoxDataIndex, i * side)
				self.slamBoxData[i * side] = {X = pos.X, Y = pos.Y, width = self.slamBoxWidth, height = boxHeight}
				
				--PrimitiveMan:DrawBoxPrimitive(pos + Vector(self.slamBoxWidth * -0.5, boxHeight * -1.0), pos + Vector(self.slamBoxWidth * 0.5, 0), 5)
			end
		end
	end
	
	-- Effects
	for _, i in ipairs(self.slamBoxDataIndex) do
		local data = self.slamBoxData[i]
		local pos = Vector(data.X, data.Y)
		
		if self.spawnEffects then
			particle = CreateMOSParticle(math.random(0,1) > 0 and "Smoke Ball 1" or "Small Smoke Ball 1");
			particle.Pos = pos + Vector(i * -2, -5)
			particle.HitsMOs = false
			particle.GlobalAccScalar = 0.05
			particle.Vel = Vector((3 / i) * 15, 0)
			particle.Lifetime = particle.Lifetime * RangeRand(0.6, 1.6) * (0.75 + math.abs(i / 2) * 0.5) * 0.3;
			particle.AirResistance = 5
			particle.AirThreshold = 0
			MovableMan:AddParticle(particle);
		end
		
		-- if math.abs(i / self.slamBoxAmount) < (self.Age / 500) then
			-- local width = data.width
			-- local height = data.height
			
			-- PrimitiveMan:DrawBoxPrimitive(pos + Vector(width * -0.5, height * -1.0), pos + Vector(width * 0.5, 0), 5)
		-- end
	end
	self.spawnEffects = false
	
	
	for actor in MovableMan.Actors do
		if actor.Team ~= self.Team and (not actor:NumberValueExists("V1GroundslammedbitchAge") or actor:GetNumberValue("V1GroundslammedbitchAge") < actor.Age) then
			local center = Vector(actor.Pos.X, actor.Pos.Y)
			
			local highest = 0
			local lowest = 0
			local right = 0
			local left = 0
			for limb in actor.Attachables do
				if limb.GetsHitByMOs == true then
					local pos = Vector(limb.Pos.X, limb.Pos.Y)
					local offset = center - pos
					
					local radius = limb.IndividualRadius
					
					if (offset.X + radius) > right then right = offset.X + radius end
					if (offset.X - radius) < left then left = offset.X - radius end
					
					if (offset.Y - radius) < lowest then lowest = offset.Y - radius end
					if (offset.Y + radius) > highest then highest = offset.Y + radius end
					
					
					-- for gear in limb.Attachables do
						-- local pos = Vector(gear.Pos.X, gear.Pos.Y)
						-- local offset = center - pos
						
						-- local radius = limb.IndividualRadius
						-- if (offset.X + radius) > right then right = offset.X + radius end
						-- if (offset.X - radius) < left then left = offset.X - radius end
						
						-- if (offset.Y - radius) < lowest then lowest = offset.Y - radius end
						-- if (offset.Y + radius) > highest then highest = offset.Y + radius end
						
						-- --PrimitiveMan:DrawCirclePrimitive(pos, radius, 5)
					-- end
					
					--PrimitiveMan:DrawCirclePrimitive(pos, radius, 5)
				end
			end
			highest = math.abs(highest)
			lowest = math.abs(lowest)
			right = math.abs(right)
			left = math.abs(left)
			
			local intersects = false
			for _, i in ipairs(self.slamBoxDataIndex) do
				if math.abs(i / self.slamBoxAmount) < (self.Age / self.Lifetime) then
					
					local data = self.slamBoxData[i]
					local pos = Vector(data.X, data.Y)
					local width = data.width
					local height = data.height
					
					local boxA = Box(Vector(width * -0.5, height * -1.0), width, height)
					local boxB = Box(SceneMan:ShortestDistance(pos, center + Vector(-left, -highest), SceneMan.SceneWrapsX), right + left, highest + lowest)
					
					if boxA:IntersectsBox(boxB) then
						intersects = true
						
						local sizeFactor = math.min(math.max(40 / actor.Radius, 0), 1);
						actor.Health = actor.Health - 5 * sizeFactor
						actor.Vel = actor.Vel / 2 - Vector(0, 18 * sizeFactor);
						actor.AngularVel = actor.AngularVel / 2 + math.random(-10, 10);
						actor:SetNumberValue("V1GroundslammedbitchAge", actor.Age + self.Lifetime)
						if actor.Status < 1 then
							actor.Status = 1
						end
						
						break
					end
					
				end
			end
			
			-- Debug
			-- if intersects then
				-- PrimitiveMan:DrawBoxPrimitive(center + Vector(-left, -highest), center + Vector(right, lowest), 5)
			-- else
				-- PrimitiveMan:DrawBoxPrimitive(center + Vector(-left, -highest), center + Vector(right, lowest), 13)
			-- end
			
		end
	end
	
	PrimitiveMan:DrawCirclePrimitive(self.Pos, 2, 5)
end