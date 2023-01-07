AIRadar = {}

AIRadar.debugColors = {
	yellow = 122,
	red = 13,
	cyan = 5,
	green = 162
}

--[[
	AI Radar framework for Cortex Command Community Project by filipex2000 (fil)
	
	2021-2021
	pre3-pre4
	
	Message me on Discord! (filipex2000#1080)
]]

--[[
Example:
	
	function Create(self)
		-- initialize our radar
		self.radar = AIRadar.Create({position = self.Pos, rotation = 0, arc = math.rad(90), distance = 200, steps = 1, team = self.Team})
	end
	
	function Update(self)
		-- update it!
		AIRadar.SetTransform(self.radar, self.Pos, self.RotAngle)
		AIRadar.Update(self.radar)
		
		local targets = AIRadar.GetDetectedActorsThisFrame(self.radar)
		for i = 0, target in ipairs(targets) do
			-- do something cool
		end
	end
	
--]]

function AIRadar.CalculateActorDimensions(actor)
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
	highest = -highest
	lowest = -lowest
	right = -right
	left = -left
	
	return {Vector(left, lowest), Vector(right, highest)}
end

function AIRadar.CalculateActorVisibilityShape(origin, actor)
	if not actor then return {0, 0, origin} end
	local dif = SceneMan:ShortestDistance(origin, actor.Pos, SceneMan.SceneWrapsX)
	
	-- Check if visible
	local size = AIRadar.CalculateActorDimensions(ToActor(actor))
	local cornerA = size[1]
	local cornerB = size[2]
	
	local center = Vector((cornerA.X + cornerB.X) * 0.5, (cornerA.Y + cornerB.Y) * 0.5)
	
	local radiusA = (math.abs(cornerA.X) + math.abs(cornerB.X)) * 0.4
	local radiusB = (math.abs(cornerA.Y) + math.abs(cornerB.Y)) * 0.4
	
	local angle = dif.AbsRadAngle
	local radius = math.abs(math.sin(angle)) * radiusA + math.abs(math.cos(angle)) * radiusB
	
	return {angle, radius, center}
end

--

function AIRadar.Create(data) --(position, rotation, arc, distance, steps, team)
	local position = data.position ~= nil and data.position or Vector(0, 0)
	local rotation = data.rotation ~= nil and data.rotation or 0
	
	local flipped = data.flipped ~= nil and data.flipped or false
	--local debug = data.debug ~= nil and data.debug or -1
	
	local arc = data.arc ~= nil and data.arc or math.rad(180)
	local distance = data.distance ~= nil and data.distance or 200
	local steps = data.steps ~= nil and data.steps or 1
	local stepDeg = data.stepDeg ~= nil and data.stepDeg or 5
	local stepsMax = data.stepsMax ~= nil and data.stepsMax or math.floor(math.abs(math.deg(arc) / stepDeg))
	
	local team = data.team ~= nil and data.team or -1
	
	local ignoreUIDs = data.ignoreUIDs ~= nil and data.ignoreUIDs or {}
	local ignoreIDs = data.ignoreIDs ~= nil and data.ignoreIDs or {}
	
	
	local radar = {}
	radar.Pos = {position.X, position.Y} -- The position / origin of the radar (remember to update it!)
	radar.Rotation = rotation -- The rotation of the radar (remember to update it!)
	
	radar.RangeArc = arc -- Vision cone range in radians
	radar.RangeDist = distance -- Vision cone range in pixels
	
	radar.StepsPerUpdate = steps -- How many raycasts per update
	radar.StepsMax = stepsMax -- How many steps per 
	radar.StepCurrent = 0
	
	--radar.Debug = debug
	radar.Flipped = flipped -- Is HORIZONTALLY flipped!
	radar.Team = team
	radar.IgnoreUIDs = ignoreUIDs
	radar.IgnoreIDs = ignoreIDs
	
	return radar
end

function AIRadar.SetPosition(radar, position)
	radar.Pos[1] = position.X
	radar.Pos[2] = position.Y
	--return radar
end

function AIRadar.SetRotation(radar, rotation)
	radar.Rotation = rotation
	--return radar
end

function AIRadar.SetTransform(radar, position, rotation, flipped)
	AIRadar.SetPosition(radar, position)
	AIRadar.SetRotation(radar, rotation)
	radar.Flipped = flipped
end

function AIRadar.Update(radar)
	radar.DebugSteps = {}
	radar.DebugLengths = {}
	radar.DetectedActors = {}
	
	
	for step = 1, radar.StepsPerUpdate do
		radar.StepCurrent = (radar.StepCurrent + 1) % (radar.StepsMax + 1)
		
		local factorStep = radar.StepCurrent / radar.StepsMax
		local factorStepAlt = (factorStep - 0.5) * 2.0
		
		local flipFactor = radar.Flipped and -1 or 1
		
		local rayOrigin = Vector(radar.Pos[1], radar.Pos[2])
		local rayVec = Vector(radar.RangeDist * flipFactor, 0):RadRotate(radar.Rotation + radar.RangeArc * 0.5 * factorStepAlt);
		
		local moCheck = SceneMan:CastMORay(rayOrigin, rayVec, 255, radar.Team, 0, false, math.random(4, 6)); -- Raycast
		if moCheck ~= rte.NoMOID then
			local mo = MovableMan:GetMOFromID(moCheck)
			if IsMOSRotating(mo) then
				local parent = mo:GetRootParent()
				if parent and IsActor(parent) then
					local actor = ToActor(parent)
					
					radar.DetectedActors[step] = actor
				end
			end
			
			radar.DebugLengths[step] = SceneMan:ShortestDistance(rayOrigin, SceneMan:GetLastRayHitPos(), SceneMan.SceneWrapsX).Magnitude
		else
			radar.DebugLengths[step] = radar.RangeDist
		end
		
		radar.DebugSteps[step] = radar.StepCurrent
	end
	
	--return radar
end


function AIRadar.GetDetectedActorsThisFrame(radar) -- WHEN UPDATING LESS FREQUENTLY THAN EVERY FRAME CHECK IF THOSE ACTORS STIlL EXIST!
	return radar.DetectedActors
end

--- Debug

function AIRadar.DrawDebugVisualization(radar)
	local colors = AIRadar.debugColors
	
	-- Draw origin
	local flipFactor = radar.Flipped and -1 or 1
	local pos = Vector(radar.Pos[1], radar.Pos[2])
	
	PrimitiveMan:DrawCircleFillPrimitive(pos, 2, colors.yellow)
	
	-- Debug vision cone
	PrimitiveMan:DrawLinePrimitive(pos, pos + Vector(radar.RangeDist * flipFactor, 0):RadRotate(radar.Rotation + radar.RangeArc * 0.5), colors.yellow);
	PrimitiveMan:DrawLinePrimitive(pos, pos + Vector(radar.RangeDist * flipFactor, 0):RadRotate(radar.Rotation - radar.RangeArc * 0.5), colors.yellow);
	
	local points = {}
	local maxi = math.floor(math.abs(math.deg(radar.RangeArc) / 20))
	for i = -maxi, maxi do
		local factor = i / maxi
		table.insert(points, Vector(radar.RangeDist * flipFactor, 0):RadRotate(radar.Rotation + radar.RangeArc * 0.5 * factor))
	end
	
	local pointLast = points[1]
	for i = 2, #points do
		local pointCurrent = points[i]
		PrimitiveMan:DrawLinePrimitive(pos + pointCurrent, pos + pointLast, colors.yellow);
		pointLast = points[i]
	end
	--
	
	-- Debug rays
	if radar.DebugSteps and radar.DebugLengths then
		for i = 1, radar.StepsPerUpdate do
			local factorStep = radar.StepCurrent / radar.StepsMax
			local factorStepAlt = (factorStep - 0.5) * 2.0
			PrimitiveMan:DrawLinePrimitive(pos, pos + Vector(radar.DebugLengths[i] * flipFactor, 0):RadRotate(radar.Rotation + radar.RangeArc * 0.5 * factorStepAlt), colors.red);
		end
	end
	--
	
end