

function Create(self)
	self.soundCoinReady = CreateSoundContainer("Marksman Coin Ready", "Ultrakill.rte")
	
	
	local actor = self:GetRootParent();
	if actor and IsAHuman(actor) then
		self.parent = ToAHuman(actor);
	end
	
	self.lastAge = self.Age
	
	self.coinFlipTimer = Timer()
	
	self.coins = 4
	self.coinsMax = 4
	self.coinRegenTimer = Timer()
	self.coinRegenDelay = 3000
	self.coinRegenDelayOffset = 0
end

function OnDetach(self)
	self.parent = nil;
	self.parentSet = false;
end

function Update(self)
	
	if self.parentSet == false then
		local actor = self:GetRootParent();
		if actor and IsAHuman(actor) then
			self.parent = ToAHuman(actor);
			self.parentSet = true;
		end
	end
	
	-- Check if switched weapons/hide in the inventory, etc.
	if self.Age > (self.lastAge + TimerMan.DeltaTimeSecs * 2000) then
		local timeDifference = self.Age - self.lastAge
		local coinGain = math.floor(timeDifference / self.coinRegenDelay)
		self.coins = math.min(self.coins + coinGain, self.coinsMax)
		if coinGain > 0 then
			self.soundCoinReady.Pitch = 0.95 + 0.12 * self.coins
			self.soundCoinReady:Play(self.Pos)
		end
		
		if self.coins < self.coinsMax then
			self.coinRegenDelayOffset = self.coinRegenDelayOffset + (timeDifference % self.coinRegenDelay)
		end
	end
	self.lastAge = self.Age + 0
	
	if self.FiredFrame then
		local projectile = CreateMOSRotating("Bullet Marksman", "Ultrakill.rte")
		projectile.Pos = self.MuzzlePos;
		projectile.RotAngle = self.RotAngle + math.pi * (-self.FlipFactor + 1) * 0.5
		projectile.Vel = self.Vel + Vector(130*self.FlipFactor,0):RadRotate(self.RotAngle)
		projectile.Team = self.Team
		projectile.IgnoresTeamHits = true
		MovableMan:AddParticle(projectile);
	end
	
	if self.coinFlipTimer:IsPastSimMS(300) then
		self.SupportOffset = Vector(-4, 1)
		
		self.StanceOffset = Vector(14, 0)
		self.SharpStanceOffset = Vector(15, -2)
	else
		self.SupportOffset = Vector(3, -5)
		
		self.StanceOffset = Vector(12, 3)
		self.SharpStanceOffset = Vector(12, 3)
	end
	
	if self.coins < self.coinsMax then
		if self.coinRegenTimer:IsPastSimMS(self.coinRegenDelay - self.coinRegenDelayOffset) then
			self.coins = self.coins + 1
			self.coinRegenTimer:Reset()
			
			self.coinRegenDelayOffset = 0
			
			self.soundCoinReady.Pitch = 0.95 + 0.12 * self.coins
			self.soundCoinReady:Play(self.Pos)
		end
	else
		self.coinRegenDelayOffset = 0
		self.coinRegenTimer:Reset()
	end
	
	if self.parent and not (self.parent:NumberValueExists("DisableHUD") and self.parent:GetNumberValue("DisableHUD") == 1) then
		local ctrl = self.parent:GetController();
		local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
		
		for i = 1, self.coinsMax do
			local pos = self.parent.Pos + Vector(0, 17) 
			
			--local factor = (((i - 0.5) / self.coinsMax) - 0.5) * 2.0
			local factorX = ((i % 2) - 0.5) * 2.0
			local factorY = math.ceil(i * 0.5)
			pos = pos + Vector(-5 * factorX, 10 * factorY)
			
			local color = 162
			if i == self.coins+1 then
				local colorFactor = math.min((self.coinRegenTimer.ElapsedSimTimeMS + self.coinRegenDelayOffset) / (self.coinRegenDelay), 1.0)
				local colors = {244, 47, 86, 87, 116, 135}
				
				colorFactor = math.pow(colorFactor, 2)
				
				color = colors[math.floor(colorFactor * (#colors)) + 1]
			elseif i > self.coins then
				color = -1
			end
			
			-- if small then
				-- -- PrimitiveMan:DrawLinePrimitive(pos, pos, color);
				-- -- PrimitiveMan:DrawCirclePrimitive(pos, 1, color)
				-- PrimitiveMan:DrawCircleFillPrimitive(screen,pos,1,color)
			-- else
			if color ~= -1 then
				-- PrimitiveMan:DrawLinePrimitive(pos + Vector(-1, -1), pos + Vector(1, -1), color);
				-- PrimitiveMan:DrawLinePrimitive(pos + Vector(-1, 0), pos + Vector(1, 0), color);
				-- PrimitiveMan:DrawLinePrimitive(pos + Vector(-1, 1), pos + Vector(1, 1), color);
				-- PrimitiveMan:DrawCirclePrimitive(pos, 2, color)
				PrimitiveMan:DrawCircleFillPrimitive(screen,pos,2,color)
			end
			PrimitiveMan:DrawCirclePrimitive(pos, 3, 246) -- Black Outline
		end
		
		-- Coin
		local active = self.parent:GetController():IsState(Controller.WEAPON_RELOAD)
		if active and self.coinFlipTimer:IsPastSimMS(200) and self.coins > 0 then
			local coin = CreateMOSParticle("Coin Marksman", "Ultrakill.rte")
			coin.Pos = self.parent.BGArm.Pos;
			coin.Vel = self.Vel + Vector(20*self.FlipFactor,-10 * math.abs(math.cos(self.RotAngle)) ):RadRotate(self.RotAngle)
			coin.Team = self.Team
			coin.IgnoresTeamHits = true
			MovableMan:AddParticle(coin);
			
			self.coins = self.coins - 1
			self.coinFlipTimer:Reset()
		end
	end
end 