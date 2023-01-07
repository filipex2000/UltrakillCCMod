function Create(self)
	self.Frame = 1
	
	self.soundCoreEject = CreateSoundContainer("Charge Shotgun Core Eject", "Ultrakill.rte")
	
	self.soundCharge = CreateSoundContainer("Charge Shotgun Charge", "Ultrakill.rte")
	
	self.soundReloadVentSteam = CreateSoundContainer("Charge Shotgun Reload Vent Steam", "Ultrakill.rte")
	self.soundReloadClose = CreateSoundContainer("Charge Shotgun Reload Close", "Ultrakill.rte")
	self.soundReloadCloseCoreEject = CreateSoundContainer("Charge Shotgun Reload Close Core Eject", "Ultrakill.rte")
	
	local actor = self:GetRootParent();
	if actor and IsAHuman(actor) then
		self.parent = ToAHuman(actor);
	end
	
	self.barrelMOUID = nil
	self.barrelMO = nil
	
	self.barrelBend = math.pi * -0.3
	
	for mo in self.Attachables do
		if string.find(mo.PresetName, "Barrel") then
			self.barrelMOUID = mo.UniqueID
			self.barrelMO = mo
		end
	end
	
	self.steamVentTimer = Timer()
	
	self.wasPreviouslyReloading = false
	self.reloading = false
	self.reloadTimer = Timer()
	self.reloadDuration = 1400
	
	self.reloadStartTimer = Timer()
	self.reloadStartDelay = 250
	
	self.reloadCoreEject = false
	
	self.reloadPlayCloseSound = false
	
	-- Charge
	self.chargeTime = 0
	self.charging = false
	
	self.shot = false
	self.active = false
end

function OnDetach(self)
	self.parent = nil;
	self.parentSet = false;
	
	self.soundCharge:Stop(-1)
end
	
function Update(self)
	
	if self.parentSet == false then
		local actor = self:GetRootParent();
		if actor and IsAHuman(actor) then
			self.parent = ToAHuman(actor);
			self.parentSet = true;
		end
	end
	
	if self.barrelMOUID then
		self.barrelMO = ToAttachable(MovableMan:FindObjectByUniqueID(self.barrelMOUID))
	else
		self.barrelMO = nil
	end
	
	if self.barrelMO then
		self.barrelMO:RemoveWounds(self.barrelMO.WoundCount)
		
		if self.parent then
			local reloadDurationMultiplier = 1
			if self.reloadCoreEject then
				reloadDurationMultiplier = 1.4
			end
			
			if self.reloading then
				self:Deactivate();
				
				self.barrelMO.Frame = 0
				
				-- Barrel animation
				local factorA = math.min((self.reloadTimer.ElapsedSimTimeMS) / 180, 1)
				self.barrelMO.InheritedRotAngleOffset = self.barrelBend * (factorA)
				
				local factorOpen = math.sin((1 - math.pow(1 - factorA, 2)) * math.pi) - math.sin(math.pow(factorA, 2) * math.pi) * 1.0 + (1 - factorA)
				self.InheritedRotAngleOffset = math.pi * -0.1 * factorOpen
				
				if not self.wasPreviouslyReloading then -- Reload start function
					self.wasPreviouslyReloading = true
					
					self.soundReloadVentSteam:Play(self.Pos)
				end
				
				local endSilenceDuration = 300
				if self.reloadTimer:IsPastSimMS(self.reloadDuration * reloadDurationMultiplier) then -- Reload end
					self.reloading = false
					
					self.barrelMO.InheritedRotAngleOffset = 0
				elseif self.reloadTimer:IsPastSimMS(self.reloadDuration * reloadDurationMultiplier - 140 - endSilenceDuration) then -- Reload end sound
					
					-- Barrel animation
					local factorB = math.min((self.reloadTimer.ElapsedSimTimeMS - (self.reloadDuration * reloadDurationMultiplier - 140 - endSilenceDuration)) / 160, 1)
					
					self.barrelMO.InheritedRotAngleOffset = self.barrelBend * math.pow(1 - factorB, 3)
					
					--local factorClose = math.sin(factorB * math.pi) * 0.65 + (math.cos(factorB * math.pi * 0.5)) * 0.35
					local factorClose = math.sin((1 - math.pow(1 - factorB, 2)) * math.pi) - math.sin(math.pow(factorB, 2) * math.pi) * 1.0 + (1 - factorB)
					
					self.InheritedRotAngleOffset = math.pi * 0.1 * factorClose
					
					if self.reloadPlayCloseSound then
						self.reloadPlayCloseSound = false
						
						if self.reloadCoreEject then
							self.soundReloadCloseCoreEject:Play(self.Pos)
						else
							self.soundReloadClose:Play(self.Pos)
						end
					end
					
				end
				
				
				if self.steamVentTimer:IsPastSimMS(50) and not self.reloadTimer:IsPastSimMS(500) then
					self.steamVentTimer:Reset()
					
					local smoke = CreateMOSParticle(math.random(0, 1) < 1 and "Small Smoke Ball 1" or "Tiny Smoke Ball 1");
					smoke.Pos = self.barrelMO.Pos + Vector(-5 * self.FlipFactor, -3):RadRotate(self.barrelMO.RotAngle)
					smoke.Vel = Vector(-3, 2 * RangeRand(-1.0, 1.0)):RadRotate(self.barrelMO.RotAngle + math.pi * RangeRand(-1.0, 1.0) * 0.2) * RangeRand(0.3, 1.0)
					smoke.Lifetime = smoke.Lifetime * RangeRand(0.6, 1.6) * 0.3;
					MovableMan:AddParticle(smoke);
				end
				
				self.soundCharge:Stop(-1)
			else
				
				if self.wasPreviouslyReloading then -- Reload end function
					self.wasPreviouslyReloading = false
					
					-- Barrel animation
					self.barrelMO.InheritedRotAngleOffset = 0
					
					-- Reset variables
					self.reloadPlayCloseSound = true
					self.reloadCoreEject = false
				end
			end
			
			if self.shot then -- Delay before reload start
				self:Deactivate()
				
				self.barrelMO.InheritedRotAngleOffset = 0
				
				local factor = math.min((self.reloadStartTimer.ElapsedSimTimeMS) / (self.reloadStartDelay * reloadDurationMultiplier), 1)
				
				self.InheritedRotAngleOffset = math.pi * 0.2 * math.sin(math.sqrt(factor) * math.pi)
				
				if self.reloadStartTimer:IsPastSimMS(self.reloadStartDelay * reloadDurationMultiplier) then
					self.shot = false
					self.reloading = true
					
					self.reloadTimer:Reset()
				end
			else -- Fire function and fx
				--self.barrelMO.InheritedRotAngleOffset = 0
				
				local active = self:IsActivated()
				self:Deactivate()
				
				local chargeStartTime = 0.013 * 15
				
				if active then
					self.chargeTime = self.chargeTime + TimerMan.DeltaTimeSecs
					self.active = true
					
					if self.chargeTime > chargeStartTime and not self.charging then
						self.charging = true
						self.soundCharge:Play(self.Pos)
					end
					
					if self.soundCharge:IsBeingPlayed() then
						self.soundCharge.Pos = self.Pos
						self.soundCharge.Pitch = 0.1 + 0.9 * math.min((self.chargeTime - chargeStartTime) / 1, 1)
						
						self.barrelMO.Frame = math.floor(1 + 8 * math.min((self.chargeTime - chargeStartTime) / 1, 1) + 0.5)
						--self.soundCharge.Pitch = 1.0 + 0.1 * math.min(self.chargeTime / 1, 1)
					end
				else
					if self.charging then
						self.charging = false
						self.active = false
						
						
						-- Core Eject!
						self.soundCoreEject:Play(self.Pos)
						
						local vel = 3 + 37 * math.min((self.chargeTime - chargeStartTime) / 1, 1)
						local core = CreateMOSRotating("Core Charge Shotgun", "Ultrakill.rte")
						core.Pos = self.MuzzlePos;
						core.RotAngle = self.RotAngle
						core.Vel = self.Vel + Vector(vel * self.FlipFactor, 0):RadRotate(self.RotAngle)
						core.Team = self.Team
						core.IgnoresTeamHits = true
						MovableMan:AddParticle(core);
						
						self.reloadCoreEject = true
						
						self.shot = true
						self.reloadStartTimer:Reset()
						
						self.barrelMO.Frame = 0
						
						self.soundCharge:Stop(-1)
					elseif self.active then
						self.active = false
						self:Activate()
					end
					self.chargeTime = 0
				end
				
				--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, -90), "charging = ".. (self.charging and "true" or "false"), true, 0);
				--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, -120), "chargeTime = ".. math.floor(self.chargeTime * 1000), true, 0);
				
				if self.FiredFrame then
					local pos = self.MuzzlePos
					local vel = Vector(50 * self.FlipFactor, 0):RadRotate(self.RotAngle)
					for i = 1, math.random(2,6) do
						local poof = CreateMOSParticle(math.random(1,2) < 2 and "Tiny Smoke Ball 1" or "Small Smoke Ball 1");
						poof.Pos = pos
						poof.Vel = self.Vel + Vector(vel.X, vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.05) * RangeRand(0.1, 0.9) * 0.6;
						poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
						MovableMan:AddParticle(poof);
					end
					for i = 1, math.random(2,4) do
						local poof = CreateMOSParticle("Small Smoke Ball 1");
						poof.Pos = pos
						poof.Vel = self.Vel + (Vector(vel.X, vel.Y):RadRotate(math.pi * (math.random(0,1) * 2.0 - 1.0) * 2.5 + math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.6 + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.2) * 0.5;
						poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
						MovableMan:AddParticle(poof);
					end
					for i = 1, 3 do
						local poof = CreateMOSParticle("Explosion Smoke 2");
						poof.Pos = pos
						poof.Vel = self.Vel + Vector(vel.X, vel.Y):RadRotate(RangeRand(-1, 1) * 0.15) * RangeRand(0.9, 1.6) * 0.66 * i;
						poof.Lifetime = poof.Lifetime * RangeRand(0.8, 1.6) * 0.1 * i
						MovableMan:AddParticle(poof);
					end
					
					self.shot = true
					self.reloadStartTimer:Reset()
					--self.reloading = true
				end
				
			end
		end
		
	else
		self:GibThis()
	end
end

function Destroy(self)
	self.soundCharge:Stop(-1)
end