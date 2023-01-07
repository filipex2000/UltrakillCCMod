Prelude0 = {
	SkipIntro = false,
	
	Name = "0-0: INTO THE FIRE",
	
	ScoreToCompare = {
		Kills = 38, -- In dead bodies
		Time = 2.0, -- In minutes
		Style = 6000, -- In points
	},
	
	Music = {
		Action = CreateSoundContainer("Prelude 0 Action", "Ultrakill.rte");
		Clean = CreateSoundContainer("Prelude 0 Clean", "Ultrakill.rte");
		Bass = CreateSoundContainer("Prelude 0 Bass", "Ultrakill.rte");
		Intro = CreateSoundContainer("Prelude 0 Intro", "Ultrakill.rte");
		IntroDrone = CreateSoundContainer("Prelude 0 Intro Drone", "Ultrakill.rte");
	},
	
	Create = function(self)
		local level = self.levelLogic.Prelude0
		
		self.levelZones = {
			IntroTrigger = SceneMan.Scene:GetArea("IntroTrigger"),
			HallwayATrigger = SceneMan.Scene:GetArea("HallwayATrigger"),
			HallwayBTrigger = SceneMan.Scene:GetArea("HallwayBTrigger"),
			HallwayBigTrigger = SceneMan.Scene:GetArea("HallwayBigTrigger"),
			HallwayBigStraySpawnA = SceneMan.Scene:GetArea("HallwayBigStraySpawnA"),
			HallwayBigStraySpawnB = SceneMan.Scene:GetArea("HallwayBigStraySpawnB"),
			HallwayBigFilthSpawnA = SceneMan.Scene:GetArea("HallwayBigFilthSpawnA"),
			HallwayBigFilthSpawnB = SceneMan.Scene:GetArea("HallwayBigFilthSpawnB"),
			HallwayCTrigger = SceneMan.Scene:GetArea("HallwayCTrigger"),
			HallwayTallTrigger = SceneMan.Scene:GetArea("HallwayTallTrigger"),
			HallwayTallFilthSpawn = SceneMan.Scene:GetArea("HallwayTallFilthSpawn"),
			HallwayTallStraySpawnA = SceneMan.Scene:GetArea("HallwayTallStraySpawnA"),
			HallwayTallStraySpawnB = SceneMan.Scene:GetArea("HallwayTallStraySpawnB"),
			BossTrigger = SceneMan.Scene:GetArea("BossTrigger")
		}
		
		self.heroActor:SetNumberValue("DisableHUD", 1)
		
		self.introDoor = Ultrakill:GetDoorInsideArea(self, "IntroDoor")
		self.introDoor:SetNumberValue("Closed", 1)
		
		self.hallwayBigDoorA = Ultrakill:GetDoorInsideArea(self, "HallwayBigDoorA")
		self.hallwayBigDoorB = Ultrakill:GetDoorInsideArea(self, "HallwayBigDoorB")
		
		self.bossDoors = Ultrakill:GetDoorInsideArea(self, "BossDoors")
		
		self.endDoors = Ultrakill:GetDoorInsideArea(self, "EndDoors")
		-- Closed by default
		for i, door in ipairs(self.endDoors) do
			door:SetNumberValue("Closed", 1)
			door:SetNumberValue("Open", 0)
		end
		
		self.soundIntroThud = CreateSoundContainer("Intro Thud", "Ultrakill.rte")
		self.introState = 0
		
		self.startingGun = CreateHDFirearm("Piercer Revolver", "Ultrakill.rte")
		self.startingGun.GibWoundLimit = 999999
		--self.startingGun.MissionCritical = true
		self.startingGunFloat = 0
		
		self.firstEnemyEncounterState = -1
		self.firstEnemyEncounterWaveA = nil
		self.firstEnemyEncounterWaveB = nil
		self.firstEnemyEncounterTimerA = Timer()
		self.firstEnemyEncounterTimerB = Timer()
		
		self.hallwayAEnemyEncounterWave = nil
		self.hallwayBEnemyEncounterWave = nil
		
		self.hallwayBigEnemyEncounterWaveA = nil
		self.hallwayBigEnemyEncounterWaveB = nil
		self.hallwayBigEnemyEncounterTimerA = Timer()
		self.hallwayBigEnemyEncounterTimerB = Timer()
		self.hallwayBigState = 0
		
		self.hallwayCEnemyEncounterWave = nil
		
		self.hallwayTallEncounterWave = nil
		
		self.bossEnemyEncounter = nil
		self.bossFight = false
		
		self.musicBassFactor = 0
		
		self.musicPlayer.Play({level.Music.IntroDrone}, self.musicPlayer.Modes.LOOP)
	end,
	
	
	Update = function(self)
		local level = self.levelLogic.Prelude0
		
		if not self.heroActor then return end -- Antifuck 2000
		
		if self.introState == 0 and self.heroActor then
			local introZonePos = self.levelZones.IntroTrigger:GetCenterPoint()
			
			local dif = math.abs(self.heroActor.Pos.X - introZonePos.X)
			local difMax = 1200
			local factor = math.max(difMax - dif, 0) / difMax
			
			if self.musicPlayer.ModeCurrent ~= self.musicPlayer.Modes.INACTIVE then
				
				self.musicPlayer.TracksMix[1] = factor
				if dif < 150 then
					self.musicPlayer.Stop()
				end
			end
			
			local camPos = self.heroActor.Head.Pos + Vector(dif, 0) * math.min(math.sqrt(factor), 1) * 0.7
			SceneMan:SetScrollTarget(camPos, 0.05, false, 0)
			
			--local epicBarsFactor = (0.3 + (1 - factor * 1.2)) * math.cos((1.2 - factor) * math.pi * 0.5) * 3.0
			--if dif > 150 then
			local epicBarsFactor = math.cos((1.2 - factor) * math.pi * 0.5) * 1.05
			local epicBarsColor = 246
			local screenPos = SceneMan:GetOffset(0)-- + Vector(FrameMan.PlayerScreenWidth * 0.5, FrameMan.PlayerScreenHeight * 0.5)
			
			PrimitiveMan:DrawBoxFillPrimitive(camPos + Vector(FrameMan.PlayerScreenWidth * -1, FrameMan.PlayerScreenHeight * -1), camPos + Vector(FrameMan.PlayerScreenWidth * 1, FrameMan.PlayerScreenHeight * -1 * (1 - epicBarsFactor)), epicBarsColor)
			PrimitiveMan:DrawBoxFillPrimitive(camPos + Vector(FrameMan.PlayerScreenWidth * -1, FrameMan.PlayerScreenHeight * 1), camPos + Vector(FrameMan.PlayerScreenWidth * 1, FrameMan.PlayerScreenHeight * 1 * (1 - epicBarsFactor)), epicBarsColor)
			--PrimitiveMan:DrawBoxFillPrimitive(screenPos + Vector(-100, -100), screenPos + Vector(FrameMan.PlayerScreenWidth + 100, FrameMan.PlayerScreenHeight * 0.45 * epicBarsFactor), epicBarsColor)
			--PrimitiveMan:DrawBoxFillPrimitive(screenPos + Vector(-100, FrameMan.PlayerScreenWidth), screenPos + Vector(FrameMan.PlayerScreenWidth + 100, FrameMan.PlayerScreenHeight - FrameMan.PlayerScreenHeight * 0.45 * epicBarsFactor), epicBarsColor)
			--end
			
			-- Draw weapon
			self.startingGunFloat = (self.startingGunFloat + TimerMan.DeltaTimeSecs * 0.5) % 2
			local factor = math.sin(self.startingGunFloat * math.pi)
			
			local player = Activity.PLAYER_1
			PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), SceneMan:MovePointToGround(introZonePos, 0, 0) + Vector(0, -30) + Vector(0, 5 * factor), self.startingGun, 0, 0);
			--PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), SceneMan:MovePointToGround(introZonePos, 0, 0) + Vector(0, -2), self.startingGun, math.rad(-18.5), 0);
			
			
			if self.levelZones.IntroTrigger:IsInside(self.heroActor.Pos) then
				self.introState = 1
				self.musicPlayer.Play({level.Music.Intro}, self.musicPlayer.Modes.SINGLE)
				
				-- Block the starting area
				local block = CreateTerrainObject("Concrete Tile 1")
				block.Pos = Vector(864, 768)
				SceneMan:AddTerrainObject(block)
				-- Make it dark
				
				SceneMan:RestoreUnseenBox(0, 0, 904, SceneMan.Scene.Height, self.playerTeam)
				
				-- Dramatic hit
				self.soundIntroThud:Play(-1)
				
				-- Remember that we already have seen the cutscene, after death skip it!
				Prelude0.SkipIntro = true
				
				self.levelPlaytimeTimer:Reset() -- Compensate time for "cutscene"
				
				-- Give player the gun!
				self.heroActor:AddInventoryItem(self.startingGun);
			elseif Prelude0.SkipIntro then
				self.heroActor.Pos = self.levelZones.IntroTrigger:GetCenterPoint()
			end
		end
		
		if self.introState == 1 then
			if not level.Music.Intro:IsBeingPlayed() then
				self.introState = 2
				self.musicPlayer.Play({level.Music.Action, level.Music.Clean, level.Music.Bass}, self.musicPlayer.Modes.LOOP)
				
				self.introDoor:SetNumberValue("Danger", 1)
				
				Ultrakill:ForceActionFactor(self, 1, 800)
				self.actionFactor = 1
				self.heroActor:SetNumberValue("DisableHUD", 0)
				
				
				self.firstEnemyEncounterState = 0
				self.firstEnemyEncounterTimerA:Reset()
			else
				if not self.logoSprite then
					self.logoSprite = CreateMOSRotating("ULTRAKILL Logo Sprite", "Ultrakill.rte")
				end
				local player = Activity.PLAYER_1
				local screenPos = SceneMan:GetOffset(player) + Vector(FrameMan.PlayerScreenWidth * 0.5, FrameMan.PlayerScreenHeight * 0.5)
				
				PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), screenPos, self.logoSprite, 0, 0);
			end
		end
		
		if self.introState == 2 then
			--local dif = math.abs(self.heroActor.Pos.X - self.levelZones.IntroTrigger:GetCenterPoint().X)
			--local factor = math.max(50 - dif, 0) / 50
			factor = Ultrakill:UpdateActionFactor(self)
			
			self.musicPlayer.TracksMix[1] = factor * (1 - self.musicBassFactor)
			self.musicPlayer.TracksMix[2] = 1 - factor
			self.musicPlayer.TracksMix[3] = factor * self.musicBassFactor
		end
		
		
		
		if self.firstEnemyEncounterState == 0 then
			
			if self.firstEnemyEncounterTimerA:IsPastSimMS(700) then
				
				if not self.firstEnemyEncounterWaveA then
					local enemies = {}
					
					for i = 1, 2 do
						local pos = self.levelZones.IntroTrigger:GetCenterPoint() + Vector(70, 0) + Vector(25, 0) * i
						pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
						
						enemies[i] = {position = pos, presetName = "Filth"}
						--Ultrakill:SpawnEnemy(self, pos, "Filth")
					end
					
					
					
					self.firstEnemyEncounterWaveA = Ultrakill:AddEnemyWave(self, enemies)
				end
				
				if Ultrakill:EnemyWaveIsDead(self, self.firstEnemyEncounterWaveA) then
					self.firstEnemyEncounterState = 1
					self.firstEnemyEncounterTimerB:Reset()
					
					Ultrakill:ForceActionFactor(self, 1, 600)
				else
					Ultrakill:ForceActionFactor(self, 1, 100)
				end
			end
		elseif self.firstEnemyEncounterState == 1 then
			if self.firstEnemyEncounterTimerB:IsPastSimMS(400) and #self.enemies < 1 then
				if not self.firstEnemyEncounterWaveB then
					local enemies = {}
					for i = 1, 2 do
						local pos = self.levelZones.IntroTrigger:GetCenterPoint() + Vector(70, 0) + Vector(25, 0) * i
						pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
						
						enemies[i] = {position = pos, presetName = "Filth"}
					end
					for i = 1, 2 do
						local pos = self.levelZones.IntroTrigger:GetCenterPoint() + Vector(-70, 0) + Vector(-25, 0) * i
						pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
						
						enemies[i+2] = {position = pos, presetName = "Filth"}
					end
					self.firstEnemyEncounterWaveB = Ultrakill:AddEnemyWave(self, enemies)
				end
				
				if Ultrakill:EnemyWaveIsDead(self, self.firstEnemyEncounterWaveB) then
					-- Open doors!
					self.firstEnemyEncounterState = 2
					self.introDoor:SetNumberValue("Danger", 0)
					self.introDoor:SetNumberValue("Closed", 0)
				end
			end
		end
		
		local trigger
		
		trigger = self.levelZones.HallwayATrigger
		if not self.hallwayAEnemyEncounterWave and trigger:IsInside(self.heroActor.Pos) then
			local enemies = {}
			for i = 1, 3 do
				local pos = trigger:GetCenterPoint() + Vector(80, 0) + Vector(20, 0) * i
				pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
				
				enemies[i] = {position = pos, presetName = "Filth"}
			end
			
			self.hallwayAEnemyEncounterWave = Ultrakill:AddEnemyWave(self, enemies)
		end
		
		trigger = self.levelZones.HallwayBTrigger
		if not self.hallwayBEnemyEncounterWave and trigger:IsInside(self.heroActor.Pos) then
			local enemies = {}
			for i = 1, 4 do
				local pos = trigger:GetCenterPoint() + Vector(55, 0) + Vector(27, 0) * i
				pos = pos + Vector(0, 5)
				--pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
				
				enemies[i] = {position = pos, presetName = "Filth"}
			end
			
			self.hallwayBEnemyEncounterWave = Ultrakill:AddEnemyWave(self, enemies)
		end
		
		trigger = self.levelZones.HallwayBigTrigger
		if not self.hallwayBigState ~= 3 and (self.hallwayBigState > 0 or trigger:IsInside(self.heroActor.Pos)) then
			if self.hallwayBigState == 0 then
				self.hallwayBigState = 1
				
				self.musicBassFactor = 1
				
				Ultrakill:ForceActionFactor(self, 1, 700)
				
				self.hallwayBigEnemyEncounterTimerA:Reset()
				
				self.hallwayBigDoorA:SetNumberValue("Closed", 1)
				self.hallwayBigDoorA:SetNumberValue("Danger", 1)
				
				self.hallwayBigDoorB:SetNumberValue("Closed", 1)
				self.hallwayBigDoorB:SetNumberValue("Danger", 1)
				
			elseif self.hallwayBigState == 1 then
				if self.hallwayBigEnemyEncounterTimerA:IsPastSimMS(700) then
					
					
					if not self.hallwayBigEnemyEncounterWaveA then
						local enemies = {
							{position = self.levelZones.HallwayBigStraySpawnA:GetCenterPoint(), presetName = "Stray"},
							{position = self.levelZones.HallwayBigStraySpawnB:GetCenterPoint(), presetName = "Stray"}
						}
						self.hallwayBigEnemyEncounterWaveA = Ultrakill:AddEnemyWave(self, enemies)
					end
					
					if Ultrakill:EnemyWaveIsDead(self, self.hallwayBigEnemyEncounterWaveA) then
						Ultrakill:ForceActionFactor(self, 1, 700)
						
						self.hallwayBigState = 2
						
						self.hallwayBigEnemyEncounterTimerB:Reset()
					end
				end
			elseif self.hallwayBigState == 2 then
				if self.hallwayBigEnemyEncounterTimerB:IsPastSimMS(700) then
					self.musicBassFactor = math.max(self.musicBassFactor - TimerMan.DeltaTimeSecs, 0)
					
					if not self.hallwayBigEnemyEncounterWaveB then
						local enemies = {
							{position = self.levelZones.HallwayBigStraySpawnA:GetCenterPoint(), presetName = "Stray"},
							{position = self.levelZones.HallwayBigStraySpawnB:GetCenterPoint(), presetName = "Stray"}
						}
						local maxi = 6
						
						maxi = maxi * 0.5 -- Spawn twice
						for i = 1, maxi do
							local factor = ((i / maxi) - 0.5) * 2.0 * maxi
							local pos = self.levelZones.HallwayBigFilthSpawnA:GetCenterPoint() + Vector(0, 0) + Vector(math.random(25,35), 0) * factor
							pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
							
							local name = "Filth"
							if i == 1 then
								name = "Stray"
							end
							
							enemies[2+i] = {position = pos, presetName = name}
						end
						
						for i = 1, maxi do
							local factor = ((i / maxi) - 0.5) * 2.0 * maxi
							local pos = self.levelZones.HallwayBigFilthSpawnB:GetCenterPoint() + Vector(0, 0) + Vector(math.random(25,35), 0) * factor
							pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
							
							local name = "Filth"
							if i == maxi then
								name = "Stray"
							end
							
							enemies[2+maxi+i] = {position = pos, presetName = name}
						end
						
						self.hallwayBigEnemyEncounterWaveB = Ultrakill:AddEnemyWave(self, enemies)
					end
					
					if Ultrakill:EnemyWaveIsDead(self, self.hallwayBigEnemyEncounterWaveB) then
						Ultrakill:ForceActionFactor(self, 1, 700)
						
						self.musicBassFactor = 0
						
						self.hallwayBigState = 3
						
						self.hallwayBigDoorA:SetNumberValue("Closed", 0)
						self.hallwayBigDoorA:SetNumberValue("Danger", 0)
						
						self.hallwayBigDoorB:SetNumberValue("Closed", 0)
						self.hallwayBigDoorB:SetNumberValue("Danger", 0)
					end
				end
			end
		end
		
		trigger = self.levelZones.HallwayCTrigger
		if not self.hallwayCEnemyEncounterWave and trigger:IsInside(self.heroActor.Pos) then
			local enemies = {}
			for i = 1, 3 do
				local pos = trigger:GetCenterPoint() + Vector(180, 0) + Vector(27, 0) * i
				pos = pos + Vector(0, 5)
				--pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
				
				enemies[i] = {position = pos, presetName = "Filth"}
			end
			for i = 1, 3 do
				local pos = trigger:GetCenterPoint() + Vector(260, 0) + Vector(-20, 0) * i
				pos = pos + Vector(0, 5)
				--pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
				
				enemies[3 + i] = {position = pos, presetName = "Stray"}
			end
			
			self.hallwayCEnemyEncounterWave = Ultrakill:AddEnemyWave(self, enemies)
		end
		
		trigger = self.levelZones.HallwayTallTrigger
		if not self.hallwayTallEncounterWave and trigger:IsInside(self.heroActor.Pos) then
			local enemies = {
				{position = (self.levelZones.HallwayTallStraySpawnA:GetCenterPoint() + Vector(-30, 0)), presetName = "Stray"},
				{position = (self.levelZones.HallwayTallStraySpawnA:GetCenterPoint() + Vector(30, 0)), presetName = "Stray"},
				{position = (self.levelZones.HallwayTallStraySpawnB:GetCenterPoint() + Vector(15, 0)), presetName = "Stray"},
				{position = (self.levelZones.HallwayTallStraySpawnB:GetCenterPoint() + Vector(-50, 0)), presetName = "Stray"}
			}
			for i = 1, 4 do
				local pos = self.levelZones.HallwayTallFilthSpawn:GetRandomPoint()
				pos = pos + Vector(0, 5)
				pos = SceneMan:MovePointToGround(pos, 0, 0) + Vector(0, -8)
				
				enemies[4 + i] = {position = pos, presetName = "Filth"}
			end
			
			self.hallwayTallEncounterWave = Ultrakill:AddEnemyWave(self, enemies)
		end
		
		trigger = self.levelZones.BossTrigger
		if not self.bossEnemyEncounter and trigger:IsInside(self.heroActor.Pos) then
			for i, door in ipairs(self.bossDoors) do
				door:SetNumberValue("Closed", 1)
				door:SetNumberValue("Danger", 1)
			end
			
			self.bossFight = true
			
			-- TODO: Replace with "Add Boss Wave" function
			self.bossEnemyEncounter = Ultrakill:AddBoss(self, trigger:GetCenterPoint(), "Malicious Face", "M   A   L   I   C   I   O   U   S      F   A   C   E")
			--self.bossEnemyEncounter = Ultrakill:AddEnemyWave(self, {{position = trigger:GetCenterPoint(), presetName = "Malicious Face"}})
		end
		
		if self.bossFight then
			
			local boss = MovableMan:FindObjectByUniqueID(self.bossEnemyEncounter)
			if not boss or (boss and ToActor(boss).Health < 1) then
				self.bossFight = false
				--self.musicPlayer.Stop()
				
				for i, door in ipairs(self.bossDoors) do
					door:SetNumberValue("Closed", 0)
					door:SetNumberValue("Danger", 0)
				end
				
				for i, door in ipairs(self.endDoors) do
					door:SetNumberValue("Closed", 0)
					door:SetNumberValue("Open", 1)
				end
			end
		end
	end
}