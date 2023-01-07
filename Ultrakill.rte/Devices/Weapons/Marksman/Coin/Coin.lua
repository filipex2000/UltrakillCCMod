

function Create(self)
	self.Sharpness = 1
	
	self.soundFlip = CreateSoundContainer("Coin Marksman Flip", "Ultrakill.rte")
	self.soundStop = CreateSoundContainer("Coin Marksman Stop", "Ultrakill.rte")
	
	self.soundSpin = CreateSoundContainer("Coin Marksman Spin", "Ultrakill.rte")
	
	self.soundFlash = CreateSoundContainer("Coin Marksman Flash", "Ultrakill.rte")
	self.soundFlash.Volume = 0.25
	
	self.soundFlashLoop = CreateSoundContainer("Coin Marksman Flash Loop", "Ultrakill.rte")
	self.soundFlashLoop.Volume = 0.25
	self.soundFlashLoop:Play(self.Pos)
	
	
	self.soundFlip.Volume = 1.25
	self.soundFlip:Play(self.Pos)
	self.soundSpin:Play(self.Pos)
	
	self.flash = true
	self.flashSecond = true
	self.flashTimer = Timer()
	
	self.flashTime = 300
	self.flashDuration = 13 * 8
	
	self.flashSecondTime = 1500
end

function Update(self)
	
	
	
	if self.Sharpness > 0 then
		-- Active
		if self.soundSpin:IsBeingPlayed() then
			self.soundSpin.Pos = self.Pos
			self.soundSpin.Volume = 0.3 + 0.1 * math.sin((self.Age / 500) * math.pi) + 0.6 * math.sin(math.min((self.Age / 100), 1.0) * math.pi)
			self.soundSpin.Pitch = 1.1 - 0.15 * math.min((self.Age / 1600), 1.0)
		end
		
		if self.soundFlashLoop:IsBeingPlayed() then
			self.soundFlashLoop.Pos = self.Pos
			--self.soundSpin.Volume = 0.3 + 0.1 * math.sin((self.Age / 500) * math.pi) + 0.6 * math.sin(math.min((self.Age / 100), 1.0) * math.pi)
			self.soundSpin.Pitch = 1 - 0.2 * math.min((self.Age / 1600), 1.0)
		end
		
		if self.flash or self.flashSecond then
			if (self.flashTimer:IsPastSimMS(self.flashTime) and self.flash) or (self.flashTimer:IsPastSimMS(self.flashSecondTime) and self.flashSecond) then
				self.soundFlash:Play(self.Pos)
				
				local flash = CreateMOPixel("Glow Flash Coin Marksman", "Ultrakill.rte");
				flash.Vel = self.Vel
				flash.Pos = self.Pos
				flash.GlobalAccScalar = 0.0;
				MovableMan:AddParticle(flash);
				
				self.Sharpness = 2
				if self.flash then
					self.flash = false
				elseif self.flashSecond then
					self.flashSecond = false
				end
			end
		end
		
		if not self.flashTimer:IsPastSimMS(self.flashTime) or (self.flashTimer:IsPastSimMS(self.flashTime + self.flashDuration) and not self.flashTimer:IsPastSimMS(self.flashSecondTime)) then
			self.Sharpness = 1
		else
			self.Sharpness = 2
		end
	else
		-- Dead
		self.soundSpin:Stop(-1)
		self.soundFlashLoop:Stop(-1)
	end
end 

function OnCollideWithTerrain(self, terrainID)
	if self.Sharpness > 0 then
		self.Sharpness = 0
		self.soundStop:Play(self.Pos)
		
		self.soundSpin:Stop(-1)
		self.soundFlashLoop:Stop(-1)
		
		self.ToSettle = true
		self.RestThreshold = 100
	end
end

function Destroy(self)
	self.soundSpin:Stop(-1)
	self.soundFlashLoop:Stop(-1)
end