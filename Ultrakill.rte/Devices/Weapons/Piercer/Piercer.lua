

function Create(self)
	self.soundBatteryReady = CreateSoundContainer("Piercer Battery Ready", "Ultrakill.rte")
	self.soundBatteryCharging = CreateSoundContainer("Piercer Battery Charging", "Ultrakill.rte")
	self.soundBatteryCharged = CreateSoundContainer("Piercer Battery Charged", "Ultrakill.rte")
	
	self.soundBatteryPierceCharge = CreateSoundContainer("Piercer Pierce Charge", "Ultrakill.rte")
	
	self.soundFireCharged = CreateSoundContainer("Piercer Fire Charged", "Ultrakill.rte")
	
	
	
	local actor = self:GetRootParent();
	if actor and IsAHuman(actor) then
		self.parent = ToAHuman(actor);
	end
	
	self.lastAge = self.Age
	
	self.batteryChargeSpeed = 0.18
	self.batteryCharge = 1
	self.batteryCharged = true
	self.pierceCharge = 0
	
	self.canFire = true
	self.piercerFire = false
	
	self.batterySprite = CreateMOSRotating("Piercer Battery Sprite", "Ultrakill.rte")
	
	-- self.coinFlipTimer = Timer()
	
	-- self.coins = 4
	-- self.coinsMax = 4
	-- self.coinRegenTimer = Timer()
	-- self.coinRegenDelay = 3000
	-- self.coinRegenDelayOffset = 0
end

function OnDetach(self)
	self.parent = nil;
	self.parentSet = false;
	
	self.soundBatteryPierceCharge:Stop(-1)
	self.soundBatteryCharging:Stop(-1)
	
	self.pierceCharge = 0
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
		self.batteryCharge = math.min(self.batteryCharge + timeDifference * 0.001 * self.batteryChargeSpeed, 1.01)
		
		if not self.batteryCharged and self.batteryCharge >= 1 then
			self.batteryCharged = true
			self.soundBatteryReady:Play(self.Pos)
		end
	end
	self.lastAge = self.Age + 0
	
	if self.batteryCharge < 1 then
		local rechargeSpeed = self.batteryChargeSpeed
		if self.batteryCharge < 1 and (self.batteryCharge / rechargeSpeed) > (1 / rechargeSpeed) - 3 then
			if not self.soundBatteryCharging:IsBeingPlayed() then
				self.soundBatteryCharging:Play(self.Pos)
			end
		else
			self.soundBatteryCharging:Stop(-1)
		end
		
		self.batteryCharge = math.min(self.batteryCharge + TimerMan.DeltaTimeSecs * rechargeSpeed, 1.01)
		if not self.batteryCharged and self.batteryCharge >= 1 then
			self.batteryCharged = true
			self.soundBatteryReady:Play(self.Pos)
			self.soundBatteryCharging:Stop(-1)
		end
	end
	
	if self.parent then
		local ctrl = self.parent:GetController();
	
		if not (self.parent:NumberValueExists("DisableHUD") and self.parent:GetNumberValue("DisableHUD") == 1) then
			local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
			
			local pos = self.parent.Pos + Vector(0, 26) + Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * self.pierceCharge * 2
			local frame = 5
			if self.pierceCharge > 0.06 then
				frame = math.floor(2 * self.pierceCharge + 0.5)
			else
				frame = 3 + math.floor(2 * self.batteryCharge)
			end
			
			PrimitiveMan:DrawBitmapPrimitive(screen, pos, self.batterySprite, 0, frame);
		end
		
		if self.pierceCharge > 0.06 then
			PrimitiveMan:DrawCircleFillPrimitive(self.MuzzlePos, math.random(0, 1) + 4 * self.pierceCharge, math.random() < 0.5 and 198 or 5);
			self.Pos = self.Pos + Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * self.pierceCharge * 1
		end

		
		local active = self:IsActivated()
		self:Deactivate()
		
		if active then
			local limit = 0.05
			if self.batteryCharged then
				limit = 1.01
			end
			
			self.pierceCharge = math.min(self.pierceCharge + TimerMan.DeltaTimeSecs * 1.5, limit)
			
			if self.pierceCharge > 0.06 then
				self:Deactivate()
				if not self.soundBatteryPierceCharge:IsBeingPlayed() then
					self.soundBatteryPierceCharge.Volume = 1
					self.soundBatteryPierceCharge.Pitch = 1
					self.soundBatteryPierceCharge:Play(self.Pos)
				else
					self.soundBatteryPierceCharge.Pos = self.Pos
					self.soundBatteryPierceCharge.Pitch = 1 + (self.pierceCharge * 1.0)
					self.soundBatteryPierceCharge.Volume = (self.pierceCharge + 0.5) / 1.1
				end
			elseif not self.batteryCharged and active then
				self:Activate()
			end
		else
			if self.pierceCharge > 0 then
				--self.soundBatteryPierceCharge:FadeOut(300)
				self.soundBatteryPierceCharge:Stop(-1)
				if self.batteryCharged and self.pierceCharge > 1 then
					-- Piercer fire!
					self.batteryCharged = false
					self.batteryCharge = 0
					
					self.piercerFire = true
					self:Activate()
				else
					-- Weaker fire!
					self:Activate()
				end
				self.pierceCharge = 0
			end
		end
		
		if self.FiredFrame then
			local projectile = CreateMOSRotating("Bullet Marksman", "Ultrakill.rte")
			projectile.Pos = self.MuzzlePos;
			projectile.RotAngle = self.RotAngle + math.pi * (-self.FlipFactor + 1) * 0.5
			projectile.Vel = self.Vel + Vector(130*self.FlipFactor,0):RadRotate(self.RotAngle)
			projectile.Team = self.Team
			projectile.IgnoresTeamHits = true
			MovableMan:AddParticle(projectile);
			
			if self.piercerFire then
				self.piercerFire = false
				
				projectile:SetNumberValue("Piercer", 1)
				--self.soundFireCharged.Volume = 0.7
				self.soundFireCharged:Play(self.Pos)
			end
		end
	end
end 

function Destroy(self)
	self.soundBatteryPierceCharge:Stop(-1)
	self.soundBatteryCharging:Stop(-1)
end