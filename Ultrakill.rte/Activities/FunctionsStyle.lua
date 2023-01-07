UltrakillStyle = {}

UltrakillStyle.StyleToAdd = {}

function UltrakillStyle:AddStyleScore(self, style)
	--local score = style[1] * (1 + (self.styleMultiplier and self.styleMultiplier or 1)) * 0.5
	local score = style[1] * (self.styleMultiplier and self.styleMultiplier or 1)
	local name = style[2]
	local big = style[3]
	
	self.styleScore = self.styleScore + score
	
	if name == "" then return end
	
	if #self.styleText >= self.styleTextMaxLines then
		for i = #self.styleText, 1 do
			if self.styleText[i][2] <= score then
				self.styleText[i] = {name, score, Timer(), big}
			end
		end
	else
		self.styleText[#self.styleText + 1] = {name, score, Timer(), big}
	end
	--self.styleTextCleanTimer:Reset()
	self.styleRankTimer:Reset()
	self.styleRank = math.min(math.max(self.styleRank, 0) + score / self.styleRankScorePerRank, 7.99)
	--self.styleRankDecay = 0
	self.styleBoxEffect = self.styleBoxEffect + score / 50
end

function UltrakillStyle:DisplayStyleScore(self)
	local player = Activity.PLAYER_1
	local screenPos = SceneMan:GetOffset(player)
	
	local shake = Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * self.styleBoxEffect * 4
	
	--Vector(FrameMan.PlayerScreenWidth * 0.9, FrameMan.PlayerScreenHeight * 0.1)
	local boxPos = screenPos + Vector(FrameMan.PlayerScreenWidth - 120, 40)
	local boxWidth = 141
	local boxHeight = 25 + self.styleTextMaxLines * 11 + 30
	--PrimitiveMan:DrawTextPrimitive(boxPos, "AAAAAAAAAAAAAAAA", false, 2)
	
	if not self.rankSprite then
		self.rankSprite = CreateMOSRotating("Rank Sprite", "Ultrakill.rte")
		self.styleBoxZoom = 0
	end
	
	
	self.styleBoxZoom = (self.styleBoxZoom + 1) % 2
	
	--if self.styleBoxZoom == 0 then
		PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 - 2, -22), boxPos + Vector(boxWidth * 0.5 + 2, boxHeight + 10), 248)
	--else
		PrimitiveMan:DrawBoxPrimitive(boxPos + Vector(-boxWidth * 0.5 - 3, -23), boxPos + Vector(boxWidth * 0.5 + 3, boxHeight + 11), 246)
		PrimitiveMan:DrawBoxPrimitive(boxPos + Vector(-boxWidth * 0.5 - 2, -22), boxPos + Vector(boxWidth * 0.5 + 2, boxHeight + 10), 246)
	--end
	
	-- Rank decay bar
	--local factorDecayBar = ((1 - self.styleRankDecay) - 0.5) * 2
	local factorDecayBar = ((self.styleRank - math.floor(self.styleRank)) - 0.5) * 2
	
	if self.styleRank < 0 then
		factorDecayBar = 0
	end
	
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 + 2, 25), boxPos + Vector((boxWidth * 0.5 - 2), 35), 170)
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 + 2, 25), boxPos + Vector((boxWidth * 0.5 - 2) * factorDecayBar, 35), 177)
	
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 + 2, 25), boxPos + Vector((boxWidth * 0.5 - 2) * factorDecayBar, 27), 176)
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 + 2, 33), boxPos + Vector((boxWidth * 0.5 - 2) * factorDecayBar, 35), 184)
	
	local player = Activity.PLAYER_1
	local rank = math.min(math.floor(self.styleRank), 7)
	PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), boxPos + Vector(0, 2) + shake, self.rankSprite, 0, 7 - rank);
	
	
	for i = 1, #self.styleText do
		local style = self.styleText[i]
		
		local name = style[1]
		local score = style[2]
		local timer = style[3]
		local big = style[4]
		
		local factorA = (math.max(1 - (timer.ElapsedSimTimeMS / 400), 0) + math.max(1 - (timer.ElapsedSimTimeMS / 3000), 0))
		local factorB = math.max(1 - (timer.ElapsedSimTimeMS / 1000), 0)
		local factorC = math.max(1 - (timer.ElapsedSimTimeMS / 300), 0)
		--Vector(RangeRand(-1, 1), RangeRand(-1, 1))
		local pos = boxPos + Vector(0, 11) * i + Vector(-boxWidth * 0.5 + 10, 25) + Vector(7, 0) * factorA * 0.75 + Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * self.styleBoxEffect * 3 * factorB
		
		local small = (big == nil or big == false)
		
		local flashColor = small and 187 or 122
		
		if factorC > 0.1 and self.styleBoxZoom == 1 then
			PrimitiveMan:DrawBoxFillPrimitive(Vector(boxPos.X, 0) + Vector(-boxWidth * 0.5, pos.Y - 5 * factorC + 7), Vector(boxPos.X, 0) + Vector(boxWidth * 0.5, pos.Y + 5 * factorC + 7), flashColor)
		end
		
		PrimitiveMan:DrawTextPrimitive(pos, "+ ", false, 0)
		
		if small then
			pos = pos + Vector(2, 3)
		end
		
		PrimitiveMan:DrawTextPrimitive(pos, "  " ..name, small, 0)
		
		if factorC > 0.1 and self.styleBoxZoom == 0 then
			PrimitiveMan:DrawBoxFillPrimitive(Vector(boxPos.X, 0) + Vector(-boxWidth * 0.5, pos.Y - 5 * factorC + 7), Vector(boxPos.X, 0) + Vector(boxWidth * 0.5, pos.Y + 5 * factorC + 7), flashColor)
		end
		
	end
	if self.heroActor then
		local multiplier = tostring(math.floor(self.styleMultiplier)).."."..tostring(math.floor(self.styleMultiplier * 10) % 10)..tostring(math.floor(self.styleMultiplier * 100) % 10)
		
		PrimitiveMan:DrawTextPrimitive(boxPos + Vector(-50, boxHeight - 4), "Style multiplier: "..multiplier, true, 0)
	end
end

function UltrakillStyle:UpdateStyleSystem(self)
	if self.heroActor then
		self.styleMultiplier = 1 + 2 * (self.heroActor:NumberValueExists("MovementFactor") and self.heroActor:GetNumberValue("MovementFactor") or 0)
		
		
		if self.lastPlayerHeath then
			if self.lastPlayerHeath ~= self.heroActor.Health then
				local diff = self.heroActor.Health - self.lastPlayerHeath
				if diff < 0 then
					local scorePenality = math.abs(diff) * 4
					self.styleScore = self.styleScore - scorePenality
					self.styleRank = math.max(self.styleRank - (scorePenality / self.styleRankScorePerRank) * 0.75, 0.0)
				end
				
				self.lastPlayerHeath = self.heroActor.Health
			end
		else
			self.lastPlayerHeath = self.heroActor.Health
		end
	
	end
	
	if #UltrakillStyle.StyleToAdd then
		for k, style in pairs(UltrakillStyle.StyleToAdd) do
			UltrakillStyle:AddStyleScore(self, style)
		end
		UltrakillStyle.StyleToAdd = {}
	end
	
	if self.styleMultikill > 0 and self.styleMultikillTimer:IsPastSimMS(100) then
		
		if self.styleMultikill > 1 then
			if self.styleMultikill > 3 then
				UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * self.styleMultikill + self.styleKills.MULTIKILL, "MULTIKILL x("..self.styleMultikill..")", true})
			elseif self.styleMultikill > 2 then
				UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * self.styleMultikill + self.styleKills.DOUBLEKILL, "TRIPLE KILL", true})
			elseif self.styleMultikill > 1 then
				UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * self.styleMultikill + self.styleKills.TRIPLEKILL, "DOUBLE KILL", true})
			end
			
			local removals = 0
			for j = 1, #self.styleText do
				--print(i)
				i = (#self.styleText - j + 1)
				local style = self.styleText[i]
				if style then
					
					local name = style[1]
					local score = style[2]
					local timer = style[3]
					
					if name == "KILL" then
						table.remove(self.styleText, i)
						removals = removals + 1
					end
					
					if removals >= self.styleMultikill then
						break
					end
				end
			end
			
		end
		
		self.styleMultikill = 0
	end
	
	for i = 1, #self.styleText do
		local style = self.styleText[i]
		if style then
			
			local name = style[1]
			local score = style[2]
			local timer = style[3]
			
			if timer:IsPastSimMS(6500 + score * 30) then
				table.remove(self.styleText, i)
			end
		end
	end
	
	if #self.styleText > 0 or self.styleRank > 0 then
		UltrakillStyle:DisplayStyleScore(self)
	end
	
	self.styleBoxEffect = math.max(self.styleBoxEffect - TimerMan.DeltaTimeSecs * math.max(1, self.styleBoxEffect), 0)
	
	if self.styleRank > 0 and self.styleRankTimer:IsPastSimMS(300) then
		self.styleRank = math.max(self.styleRank - TimerMan.DeltaTimeSecs * 0.15, -0.05)
		--self.styleRankDecay = self.styleRankDecay + TimerMan.DeltaTimeSecs * 0.15
	end
	-- if self.styleRank > -1 and self.styleRankDecay >= 1 then
		-- self.styleRank = math.floor(self.styleRank - 1)
		-- self.styleRankDecay = self.styleRankDecay - 1
	-- end
end