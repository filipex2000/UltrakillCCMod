dofile("Base.rte/Constants.lua")
-- Menu
dofile("Ultrakill.rte/Activities/Menu.lua")

-- Systems
dofile("Ultrakill.rte/Activities/MusicPlayer.lua") -- 			(UltrakillMusicPlayer)
dofile("Ultrakill.rte/Activities/FunctionsSaveLoad.lua") -- 	(UltrakillFileManager)
dofile("Ultrakill.rte/Activities/FunctionsActionFactor.lua") -- (Ultrakill)
dofile("Ultrakill.rte/Activities/FunctionsStyle.lua") -- 		(UltrakillStyle)
dofile("Ultrakill.rte/Activities/FunctionsEnemy.lua") -- 		(Ultrakill)

-- Map scripts
dofile("Ultrakill.rte/Scenes/Prelude0.lua")

LevelWorkInProgress = {
	Name = "X-X: WORK IN PROGRESS"
}



function Ultrakill:GetDoorInsideArea(self, area)
	local doors = {}
	local area = SceneMan.Scene:GetArea(area)
	for actor in MovableMan.Actors do
		if actor.ClassName == "ADoor" and area:IsInside(actor.Pos) then
			table.insert(doors, ToADoor(actor))
		end
	end
	
	if #doors > 1 then
		return doors
	elseif #doors == 1 then
		return doors[1]
	end
	return nil
end

function Ultrakill:SpawnPlayer(self, position)
	local actor = CreateAHuman("V1", "Ultrakill.rte");
	actor.Pos = position;
	actor.Team = self.playerTeam;
	actor.IgnoresTeamHits = true;
	actor.HUDVisible = false
	MovableMan:AddActor(actor);
	
	self:SwitchToActor(actor, 0, 0)
	
	actor.FGArm.MissionCritical = true
	actor.BGArm.MissionCritical = true
	
	for limb in actor.Attachables do -- Weird instadeath bug fix
		limb.GibWoundLimit = 999999
		limb.JointStrength = 999999
		limb.MissionCritical = true
		
		for subLimb in limb.Attachables do
			subLimb.GibWoundLimit = 999999
			subLimb.JointStrength = 999999
			subLimb.MissionCritical = true
			for subSubLimb in limb.Attachables do
				subSubLimb.GibWoundLimit = 999999
				subSubLimb.JointStrength = 999999
				subSubLimb.MissionCritical = true
			end
		end
	end
	
	self.heroActor = ToAHuman(actor)
	self.heroActorUID = actor.UniqueID
end


function Ultrakill:UpdateFOG(self)
	local width = SceneMan.SceneWidth
	local height = SceneMan.SceneHeight
	
	local downscale = 2
	local resolution = self.FOWSize * downscale
	
	local maxX = math.floor(width / resolution)
	local maxY = math.floor(height / resolution)
	
	for x = 1, maxX do
		for y = 1, maxY do
			local point = Vector((x - 0.5) * resolution, (y - 0.5) * resolution)
			local checkPix = SceneMan:GetTerrMatter(point.X, point.Y)
			
			if checkPix <= 0 then
				--SceneMan:RevealUnseen(point.X, point.Y, self.playerTeam)
				local boxSize = resolution * 4.0 * RangeRand(0.25, 1)
				SceneMan:RevealUnseenBox(point.X - boxSize * 0.5, point.Y - boxSize * 0.5, boxSize, boxSize, self.playerTeam)
			end
		end
	end
end

function Ultrakill:FadeInFOG(self)
	local width = SceneMan.SceneWidth
	local height = SceneMan.SceneHeight
	
	local downscale = 4
	local resolution = self.FOWSize * downscale
	
	local maxX = math.floor(width / resolution)
	local maxY = math.floor(height / resolution)
	
	for x = 1, maxX do
		for y = 1, maxY do
			if math.random() < 0.1 then
				local point = Vector((x - 0.5) * resolution, (y - 0.5) * resolution)
				
				--SceneMan:RevealUnseen(point.X, point.Y, self.playerTeam)
				local boxSize = resolution * 4.0 * RangeRand(0.25, 1)
				SceneMan:RestoreUnseenBox(point.X - boxSize * 0.5, point.Y - boxSize * 0.5, boxSize, boxSize, self.playerTeam)
			end
		end
	end
end

function Ultrakill:InitializeScoreboard(self)
	self.scoreBoardAcc = 0
	self.scoreBoardIntroFactor = 0
	
	self.scoreBoardAnimationShake = 0
	
	self.scoreBoardAnimationReset = true
	self.scoreBoardAnimationTimer = Timer()
	
	self.scoreBoardAnimationRank = 0
	
	self.scoreBoardOutroFactor = nil
	
	self.scoreBoardSoundRankGet = CreateSoundContainer("Style Score Rank Get", "Ultrakill.rte");
	self.scoreBoardSoundRankGetEpic = CreateSoundContainer("Style Score Rank Get Epic", "Ultrakill.rte");
	self.scoreBoardSoundRankProgress = CreateSoundContainer("Style Score Rank Progress", "Ultrakill.rte");
end

function Ultrakill:ShowScoreboard(self)
	local player = Activity.PLAYER_1
	local screenPos = SceneMan:GetOffset(player)
	--Ultrakill:InitializeScoreboard(self)
	
	local timeMS = math.floor(self.levelPlaytime % 1000)
	local timeS = math.floor(self.levelPlaytime / 1000) % 60
	local timeM = math.floor(math.floor(self.levelPlaytime / 1000) / 60)
	local timeMandS = math.floor(self.levelPlaytime / 1000) / 60
	--print(math.floor(self.levelPlaytime))
	
	if not self.rankIconSprite then
		self.rankIconSprite = CreateMOSRotating("Rank Icon Sprite", "Ultrakill.rte")
		self.rankIconBigSprite = CreateMOSRotating("Rank Icon Big Sprite", "Ultrakill.rte")
	end
	
	local rankKills = math.floor((self.enemyDeaths / self.currentLevelLogic.ScoreToCompare.Kills) * 4)
	local rankTime = 4
	if timeMandS > self.currentLevelLogic.ScoreToCompare.Time * 2.5 then
		rankTime = 0
	elseif timeMandS > self.currentLevelLogic.ScoreToCompare.Time * 2.0 then
		rankTime = 1
	elseif timeMandS > self.currentLevelLogic.ScoreToCompare.Time * 1.45 then
		rankTime = 2
	elseif timeMandS > self.currentLevelLogic.ScoreToCompare.Time * 1.1 then
		rankTime = 3
	end
	
	local rankStyle = 0
	if self.styleScore > (self.currentLevelLogic.ScoreToCompare.Style - 100) then
		rankStyle = 4
	elseif self.styleScore > (self.currentLevelLogic.ScoreToCompare.Style / 1.5) then
		rankStyle = 3
	elseif self.styleScore > (self.currentLevelLogic.ScoreToCompare.Style / 1.5) then
		rankStyle = 2
	elseif self.styleScore > (self.currentLevelLogic.ScoreToCompare.Style / 2) then
		rankStyle = 1
	end
		
	local totalRank = math.floor((rankKills + rankStyle + rankTime) * 0.33 + 0.5)
	if rankKills == 4 and rankStyle == 4 and rankTime == 4 then
		totalRank = 5
	end
	
	
	self.scoreBoardIntroFactor = math.min(self.scoreBoardIntroFactor + TimerMan.DeltaTimeSecs * 0.75, 1)
	self.scoreBoardAnimationShake = math.max(self.scoreBoardAnimationShake - TimerMan.DeltaTimeSecs * 5, 0)
	
	if self.scoreBoardOutroFactor ~= nil then
		self.scoreBoardOutroFactor = math.min(self.scoreBoardOutroFactor + TimerMan.DeltaTimeSecs, 1)
	end
	
	if self.scoreBoardIntroFactor > 0.95 and self.scoreBoardAnimationReset then
		self.scoreBoardAnimationReset = false
		self.scoreBoardAnimationTimer:Reset()
	elseif self.scoreBoardIntroFactor > 0.95 then
		
		if self.scoreBoardAnimationRank < 3 then
			if self.scoreBoardAnimationTimer:IsPastSimMS(600) then
				self.scoreBoardAnimationTimer:Reset()
				self.scoreBoardAnimationRank = self.scoreBoardAnimationRank + 1
				
				local epicnessFactor = 0
				if self.scoreBoardAnimationRank == 1 then
					epicnessFactor = rankTime / 4
				elseif self.scoreBoardAnimationRank == 2 then
					epicnessFactor = rankKills / 4
				elseif self.scoreBoardAnimationRank == 3 then
					epicnessFactor = rankStyle / 4
					self.scoreBoardSoundRankProgress:Play(-1)
				end
				
				self.scoreBoardAnimationShake = self.scoreBoardAnimationShake + (1 + epicnessFactor) / 2
				
				if self.scoreBoardAnimationRank < 4 then
					self.scoreBoardSoundRankGet.Volume = (1 - epicnessFactor)
					self.scoreBoardSoundRankGet:Play(-1) -- Unepic
					
					self.scoreBoardSoundRankGetEpic.Volume = epicnessFactor
					self.scoreBoardSoundRankGetEpic:Play(-1) -- Epic
				end
			end
		else
			if self.scoreBoardAnimationRank < 4 and self.scoreBoardAnimationTimer:IsPastSimMS(2160) then
				local epicnessFactor = totalRank / 5
				
				self.scoreBoardAnimationShake = 1 + epicnessFactor
				
				self.scoreBoardSoundRankGet.Volume = (1 - epicnessFactor)
				self.scoreBoardSoundRankGet:Play(-1) -- Unepic
				
				self.scoreBoardSoundRankGetEpic.Volume = epicnessFactor
				self.scoreBoardSoundRankGetEpic:Play(-1) -- Epic
				
				self.scoreBoardAnimationRank = 4
			end
		end
	end
	
	
	self.scoreBoardAcc = (self.scoreBoardAcc + TimerMan.DeltaTimeSecs * 0.5) % 4
	local wiggle = Vector(math.cos(self.scoreBoardAcc * math.pi * 0.5) * 3, math.sin(self.scoreBoardAcc * math.pi) * 5)
	local shake = Vector(RangeRand(-1,1), RangeRand(-1, 1)) * self.scoreBoardAnimationShake * 6
	
	--local offsetIntroOutro = Vector(0, -FrameMan.PlayerScreenHeight * (1 - math.sin(self.scoreBoardIntroFactor * math.pi * 0.5)))
	local offsetIntroOutro = Vector(0, -FrameMan.PlayerScreenHeight * math.pow(1 - self.scoreBoardIntroFactor, 3))
	if self.scoreBoardOutroFactor ~= nil then
		offsetIntroOutro = offsetIntroOutro + Vector(0, FrameMan.PlayerScreenHeight * math.pow(self.scoreBoardOutroFactor, 3))
	end
	
	local boxPos = screenPos + Vector(FrameMan.PlayerScreenWidth * 0.5, FrameMan.PlayerScreenHeight * 0.5) + shake + wiggle + offsetIntroOutro
	local boxWidth = 300
	local boxHeight = 200
	
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(boxWidth * -0.5, boxHeight * -0.5), boxPos + Vector(5, boxHeight * 0.3), 248)
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(12, boxHeight * -0.5), boxPos + Vector(boxWidth * 0.5, boxHeight * 0.3), 248)
	
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(boxWidth * -0.5, boxHeight * -0.5 - 42), boxPos + Vector(boxWidth * 0.5, boxHeight * -0.5 - 8), 248)
	
	PrimitiveMan:DrawTextPrimitive(boxPos + Vector(0, boxHeight * -0.5 - 40), self.currentLevelName, false, 1)
	PrimitiveMan:DrawTextPrimitive(boxPos + Vector(0, boxHeight * -0.5 - 24), "-- VIOLENT --", false, 1)
	
	if self.scoreBoardAnimationRank > 0 then
		local lines = math.min(self.scoreBoardAnimationRank, 3)
		for line = 1, lines do
			local textPos = boxPos + Vector(13 + boxWidth * -0.5, boxHeight * -0.5 - 5) + Vector(0, 25 * line)
			local textLeft = ""
			local textRight
			
			local rank = 0
			
			if line == 1 then
				
				-- LORD HAVE MERCY FOR MY SINS
				local MS = tostring(timeMS)
				if string.len(MS) == 0 then
					MS = MS.."000"
				elseif string.len(MS) == 1 then
					MS = MS.."00"
				elseif string.len(MS) == 2 then
					MS = MS.."0"
				end
				local S = tostring(timeS)
				if string.len(MS) == 0 then
					S = S.."00"
				elseif string.len(MS) == 1 then
					S = S.."0"
				end
				local M = tostring(timeM)
				-- FOR I HAVE MADE A PIECE OF CODE THAT BRINGS SHAME AND TORMENT TO MY HEART
				-- but it works, okay?
				
				rank = rankTime
				
				textLeft = "TIME:"
				textRight = M..":"..S.."."..MS
			elseif line == 2 then
				
				rank = rankKills
				
				textLeft = "KILLS:"
				textRight = tostring(self.enemyDeaths)
			elseif line == 3 then
				
				rank = rankStyle
				
				textLeft = "STYLE:"
				textRight = tostring(math.floor(self.styleScore))
			end
			PrimitiveMan:DrawTextPrimitive(textPos + Vector(-3, 0), textLeft, false, 0)
			PrimitiveMan:DrawTextPrimitive(textPos + Vector(boxWidth * 0.5 - 15 - 5, 0), textRight, false, 2)
			
			local rankPos = textPos + Vector(boxWidth * 0.5 + 16, 8)
			PrimitiveMan:DrawBoxFillPrimitive(rankPos + Vector(-11, -11), rankPos + Vector(11, 11), 251)
			PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), rankPos, self.rankIconSprite, 0, rank);
		end
		if self.scoreBoardAnimationRank > 3 then
			local totalRankPos = boxPos + Vector(boxWidth * 0.5 - 52, -48)
			PrimitiveMan:DrawBoxFillPrimitive(totalRankPos + Vector(-45, -45), totalRankPos + Vector(44, 44), 251)
			PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), totalRankPos, self.rankIconBigSprite, 0, totalRank);
		end
	end
	
	PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(15, 22), boxPos + Vector(boxWidth * 0.5 - 3, 52), 251)
	PrimitiveMan:DrawTextPrimitive(boxPos + Vector(11 + 12, 5), "CHALLANGE:", false, 0)
	
	PrimitiveMan:DrawTextPrimitive(boxPos + Vector(22, 32), "be yourself, don't die, find love", true, 0)
	
	PrimitiveMan:DrawTextPrimitive(boxPos + Vector(boxWidth * -0.5 + 11, 5), "SECRETS", false, 0)
	PrimitiveMan:DrawTextPrimitive(boxPos + Vector(0, 5), "0 / 3", false, 2)
	for i = 1, 3 do
		local secretPos = boxPos +  Vector(boxWidth * -0.5 - 12 + 32 * i, boxHeight * 0.3 - 18)
		PrimitiveMan:DrawBoxFillPrimitive(secretPos + Vector(-11, -11), secretPos + Vector(11, 11), 251)
	end
	
	PrimitiveMan:DrawTextPrimitive(boxPos + Vector(0, boxHeight * 0.5 - 24), "-- press any key to continue --", true, 1)
end


function Ultrakill:DebugZones(self)
	local zones = {}
	local zoneSets = {self.basicZones, self.levelZones}
	
	for _, zoneSet in pairs(zoneSets) do
		for key, zone in pairs(zoneSet) do
			zones[key] = zone
		end
	end
	
	for key, zone in pairs(zones) do
		local name = zone.Name
		if self.debugZoneSizes[key] == nil then
			
			local data = {}
			data.cornerA = {0,0}
			data.cornerB = {0,0}
			
			for i = 0, 4000 do
				local pos = zone:GetRandomPoint() - zone:GetCenterPoint()
				if pos.X < data.cornerA[1] and pos.Y < data.cornerA[2] then
					data.cornerA = {pos.X, pos.Y}
				end
				if pos.X > data.cornerB[1] and pos.Y > data.cornerB[2] then
					data.cornerB = {pos.X, pos.Y}
				end
			end
			
			self.debugZoneSizes[key] = data
		end
		
		local pos = zone:GetCenterPoint()
		local cA = self.debugZoneSizes[key].cornerA
		local cB = self.debugZoneSizes[key].cornerB
		
		local color = 13
		if self.heroActor and zone:IsInside(self.heroActor.Pos) then
			color = 162
		end
		
		local cAPos = Vector(cA[1], cA[2])
		local cBPos = Vector(cB[1], cB[2])
		PrimitiveMan:DrawBoxPrimitive(pos + cAPos + Vector(-1, -1), pos + cBPos + Vector(1, 1), color)
		PrimitiveMan:DrawBoxPrimitive(pos + cAPos, pos + cBPos, color)
		
		PrimitiveMan:DrawTextPrimitive(pos, name, false, 0)
	end
end

function Ultrakill:InitializeData(self)
	self.gameStageCurrent = self.gameStage.GAMEPLAY;
	self.levelStageCurrent = self.levelStage.INTRO;
	
	self.heroActor = nil
	self.heroActorUID = nil
	
	self.actorLastPos = nil
	
	self.enemyDeaths = 0
	self.enemies = {}
	
	self.enemyWaveSpawnEnemyTimer = Timer()
	self.enemyWaveSpawnEnemyDelayMin = 80
	self.enemyWaveSpawnEnemyDelayMax = 150
	self.enemyWaveSpawnEnemyDelay = math.random(self.enemyWaveSpawnEnemyDelayMin, self.enemyWaveSpawnEnemyDelayMax)
	
	self.enemyWaves = {}
	self.enemyWavesAmount = 0

	self.enemyBosses = {}
	
	self.lastDeathCountCPU = 0
	
	self.styleText = {}
	self.styleMultiplier = 1
	self.styleScore = 0
	self.styleRank = -1
	--self.styleRankDecay = 0
	self.styleRankTimer = Timer()
	self.styleMultikill = 0
	self.debugZoneSizes = {}
	self.basicZones = {
		HeroSpawn = SceneMan.Scene:GetArea("HeroSpawn"),
		LevelEnd = SceneMan.Scene:GetArea("LevelEnd")
	}
	self.levelZones = {}
	
	self.levelPlaytime = 0
	self.levelPlaytimeTimer = Timer()
	
	self.toNextLevel = false
	self.toNextLevelTimer = Timer()
	
	--- Test
	-- Instance player
	Ultrakill:SpawnPlayer(self, self.basicZones.HeroSpawn:GetCenterPoint())
	---
	
	-- FOW
	self.FOWSize = 2
	for i = 1, 4 do
		SceneMan:MakeAllUnseen(Vector(self.FOWSize, self.FOWSize), i - 1)
	end
	Ultrakill:UpdateFOG(self)
	self.makeAllDarkPlease = nil
	self.makeAllDarkTimer = Timer()
	--
end

function Ultrakill:LoadLevel(self, scene)
	if not scene then
		print("NO SCENE TO LOAD")
		return
	end
	MovableMan:PurgeAllMOs()
	self.musicPlayer.Stop()
	
	print("EXITING PREVIOUS SCENE! -- "..SceneMan.Scene.PresetName)
	print("LODAING NEW SCENE! -- "..scene)
	
	SceneMan:LoadScene(scene , true)
	
	self.currentLevelLogicCreate = true
	self.currentLevelLogic = self.levelLogic[SceneMan.Scene.PresetName]
	if self.currentLevelLogic == nil then
		print("ERROR! -- failed to load "..SceneMan.Scene.PresetName.." level logic and data!")
	else
		print("LEVEL LOGIC LOADED! - "..SceneMan.Scene.PresetName)
	end
	
	self.currentLevelName = self.currentLevelLogic.Name
	
	Ultrakill:InitializeData(self)
	
	if self.menuMusic then
		self.menuMusic:Stop(-1)
	end
end

function Ultrakill:LoadMenu(self)
	local scene = "ULTRAKILL"
	
	for actor in MovableMan.Actors do
		actor.MissionCritical = false
		actor.ToDelete = true
	end
	
	MovableMan:PurgeAllMOs()
	self.musicPlayer.Stop()
	
	print("EXITING PREVIOUS SCENE! -- "..SceneMan.Scene.PresetName)
	print("LODAING NEW SCENE! -- "..scene)
	
	SceneMan:LoadScene(scene, true)
	
	self.currentLevelLogic = nil
	self.currentLevelLogicCreate = nil
	
	self.currentLevelName = "MENU"
	
	Ultrakill:MenuCreate(self)
	
	self.gameStageCurrent = self.gameStage.MENU;
end

function Ultrakill:StartActivity()
	print("START! -- Ultrakill:StartActivity()!");
	-- ultraunused
	self.Zone = SceneMan.Scene:GetArea("UltraArea");
	
	-- Style
	self.styleData = {
		UltrakillFall = {50, "FALL", true},
		UltrakillGibbed = {10, "GIBBED", true},
		UltrakillHeadshot = {25, "HEADSHOT", true},
		UltrakillLimb = {8, "LIMB HIT", false},
		UltrakillExploded = {15, "EXPLODED", true},
		UltrakillGroundSlammed = {25, "GROUND SLAM", true},
		UltrakillAirshot = {25, "AIRSHOT", true},
		UltrakillFireworks = {90, "FIREWORKS", true}
	}
	self.styleKills = {
		KILL = 30,
		DOUBLEKILL = 25,
		TRIPLEKILL = 50,
		MULTIKILL = 100,
		BIGKILL = 90
	}
	
	self.styleText = {}
	self.styleTextMaxLines = 11
	self.styleTextCleanTimer = Timer()
	self.styleTextCleanDelay = 10000
	self.styleBoxEffect = 0
	
	self.styleMultikill = 0
	self.styleMultikillTimer = Timer()
	
	self.styleRankScorePerRank = 160
	
	--- Setup
	self.DEBUG = false
	self.BuyMenuEnabled = false
	
	self.playerTeam = Activity.TEAM_1
	self.CPUTeam = Activity.TEAM_2
	
	local player = Activity.PLAYER_1
	self:GetBanner(GUIBanner.YELLOW, player):ClearText();
	self:GetBanner(GUIBanner.RED, player):ClearText();
	
	self.gameOverFrame = 0
	self.gameOverTimer = Timer()
	self.gameOverPlayerDeathSound = CreateSoundContainer("Game Over Player Death", "Ultrakill.rte")
	self.gameOverHahSound = CreateSoundContainer("Game Over Hah", "Ultrakill.rte")
	self.gameOverRestartTimer = Timer()
	
	-- Music Player
	self.musicPlayer = UltrakillMusicPlayer:CreateMusicPlayer()
	--
	
	-- Game Logic
	self.gameStage = {MENU = 0, GAMEPLAY = 1, FAILED = 2};
	self.gameStageCurrent = self.gameStage.MENU;
	--
	
	-- Level Logic
	self.levelStage = {INTRO = 0, GAMEPLAY = 1, CUTSCENE = 2, OUTRO = 3};
	self.levelStageCurrent = self.levelStage.INTRO;
	
	self.levelLogic = {
		Prelude0 = Prelude0,
		Prelude1 = LevelWorkInProgress,
		Prelude2 = LevelWorkInProgress,
		Prelude3 = LevelWorkInProgress
	}
	self.levelList = {
		self.levelLogic.Prelude0,
		self.levelLogic.Prelude1,
		self.levelLogic.Prelude2,
		self.levelLogic.Prelude3
	}
	self.levelListNames = {
		"Prelude0",
		"Prelude1",
		"Prelude2",
		"Prelude3"
	}
	
	-- Load level logic
	self.currentLevelLogicCreate = false
	self.currentLevelLogic = nil
	
	-- Zones
	self.debugZoneSizes = {}
	self.basicZones = {}
	self.levelZones = {}
	--
	
	---
	
	 -- Default settings
	self.settings = {
		menuTheme = 0,
		musicVolume = 1,
		easyMode = false
	}
	
	local filepath = "Ultrakill.rte/Activities/Saves/Settings.save"
	if UltrakillFileManager:FileExists(filepath) then
		self.settings = UltrakillFileManager:ReadFileAsTable(filepath)
	else
		UltrakillFileManager:WriteTableToFile(filepath, self.settings)
	end
	
	
	-- Init
	Ultrakill:LoadMenu(self)
	--
end

function Ultrakill:OnPieMenu(pieActor)
	--Remove unnecessary pie slices
	self:RemovePieMenuSlice("Form Squad", "");
	self:RemovePieMenuSlice("Brain Hunt AI Mode", "");
	self:RemovePieMenuSlice("Patrol AI Mode", "");
	self:RemovePieMenuSlice("Gold Dig AI Mode", "");
	self:RemovePieMenuSlice("Go-To AI Mode", "");
	self:RemovePieMenuSlice("Sentry AI Mode", "");
	
	self:RemovePieMenuSlice("Reload", "");
	self:RemovePieMenuSlice("Not holding anything!", "");
	
	if IsAHuman(pieActor) and ToAHuman(pieActor).EquippedItem then
		self:RemovePieMenuSlice("Drop "..ToAHuman(pieActor).EquippedItem.PresetName, "")
	end
	
	local weapons = {
		"Marksman Revolver",
		"Charge Shotgun"
	}
	for i, weapon in pairs(weapons) do
		self:RemovePieMenuSlice("Drop "..weapon, "");
	end
end

-----------------------------------------------------------------------------------------
-- Pause Activity
-----------------------------------------------------------------------------------------
function Ultrakill:PauseActivity(pause)
    print("PAUSE! -- Ultrakill:PauseActivity()!");
end
-----------------------------------------------------------------------------------------
-- End Activity
-----------------------------------------------------------------------------------------
function Ultrakill:EndActivity()
	print("END! -- Ultrakill:EndActivity()!");
end

-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------
function Ultrakill:UpdateActivity()
	TimerMan.TimeScale = math.min(TimerMan.TimeScale + TimerMan.DeltaTimeSecs * 4, 1)
	
	--print(self.musicPlayer.Tracks[1].Volume)
	--print(self.musicPlayer.Tracks[2].Volume)
	if self.gameStageCurrent == self.gameStage.MENU then
		-- do the epic
		Ultrakill:MenuUpdate(self)
	elseif self.gameStageCurrent == self.gameStage.GAMEPLAY then
		Ultrakill:HandleEnemyWaves(self)
		Ultrakill:UpdateEnemyList(self)
		
		if not self.currentLevelLogic then return end -- We fucked up, let's not make it worse
		
		if self.heroActorUID then
			if not MovableMan:FindObjectByUniqueID(self.heroActorUID) then
				self.heroActor = nil
			end
		else
			self.heroActorUID = nil
		end
		
		if self.levelStageCurrent == self.levelStage.INTRO then
			local camPos = SceneMan:MovePointToGround(self.basicZones.HeroSpawn:GetCenterPoint(), 0, 0) + Vector(0, -30)
			self.musicPlayer.Stop()
			
			if self.heroActor then
				self.heroActor:SetNumberValue("DisableHUD", 1)
				self.heroActor:SetNumberValue("IgnoreInput", 1)
				
				local disableStates = {
					Controller.MOVE_RIGHT,
					Controller.MOVE_LEFT,
					Controller.MOVE_RIGHT,
					Controller.BODY_CROUCH,
					Controller.WEAPON_FIRE,
					Controller.AIM_SHARP,
					Controller.BODY_JUMP,
					Controller.BODY_JUMPSTART
				}
				for key, state in pairs(disableStates) do
					self.heroActor:GetController():SetState(state, false)
				end
				
				self.heroActor.ViewPoint = camPos
				SceneMan:SetScrollTarget(camPos, 0.1, false, 0)
				
				
				if self.heroActor.Pos.Y > camPos.Y or math.abs(self.heroActor.Pos.Y - camPos.Y) < 10 then
					self.levelStageCurrent = self.levelStage.GAMEPLAY
					self.heroActor:SetNumberValue("DisableHUD", 0)
					self.heroActor:SetNumberValue("IgnoreInput", 0)
					
					self.levelPlaytimeTimer:Reset()
					
					TimerMan.TimeScale = 0.4
				end
			else
				print("ERROR! -- hero actor shouldn't be dead during INTRO!")
				return
			end
		elseif self.levelStageCurrent == self.levelStage.OUTRO then
			local player = Activity.PLAYER_1
			self:GetBanner(GUIBanner.YELLOW, player):ClearText();
			self:GetBanner(GUIBanner.RED, player):ClearText();
			
			Ultrakill:ShowScoreboard(self)
			
			if self.levelPlaytime < 1 then
				self.levelPlaytime = self.levelPlaytimeTimer.ElapsedRealTimeMS 
			end
			
			if self.musicPlayer.TracksMix and #self.musicPlayer.TracksMix > 0 then
				for i = 1, #self.musicPlayer.TracksMix do
					self.musicPlayer.TracksMix[i] = math.max(self.musicPlayer.TracksMix[i] - TimerMan.DeltaTimeSecs * 0.2, 0)
				end
			end
			
			if self.heroActor then
				self.heroActor:SetNumberValue("DisableHUD", 1)
				self.heroActor:SetNumberValue("IgnoreInput", 1)
				
				local states = {
					Controller.MOVE_RIGHT,
					Controller.MOVE_LEFT,
					Controller.MOVE_RIGHT,
					Controller.BODY_CROUCH,
					Controller.WEAPON_FIRE,
					Controller.BODY_JUMP,
					Controller.BODY_JUMPSTART
				}
				local anyKey = false
				for key, state in pairs(states) do
					if self.heroActor:GetController() and self.heroActor:GetController():IsState(state) then
						anyKey = true
						break
					end
				end
				
				self.heroActor.ToDelete = false
				self.heroActor.Health = 100
				self.heroActor.MissionCritical = true
				
				if self.toNextLevel then
					if self.toNextLevelTimer:IsPastSimMS(2000) then
						-- TODO: LOAD NEXT LEVEL
						self.heroActor.MissionCritical = false
						self.heroActor.ToDelete = true
						Ultrakill:LoadMenu(self)
					end
				elseif self.scoreBoardAnimationRank > 3 and anyKey then
					self.toNextLevel = true
					self.toNextLevelTimer:Reset()
					self.scoreBoardOutroFactor = 0
				end
				
				if not self.actorLastPos then
					self.actorLastPos = Vector(self.heroActor.Pos.X, self.heroActor.Pos.Y)
				end
				if self.heroActor.Pos.Y > (SceneMan.SceneHeight - 150) then
					self.heroActor.Pos = self.basicZones.HeroSpawn:GetCenterPoint() + Vector(0, 10)--Vector(self.heroActor.Pos.X, SceneMan.SceneHeight - 60)
					self.heroActor.Vel = Vector(0, 0)
					
					if not self.makeAllDarkPlease then
						for i = 1, 4 do
							SceneMan:MakeAllUnseen(Vector(40, 40), i - 1)
						end
						self.makeAllDarkPlease = true
					end
				else
					if not self.makeAllDarkPlease and self.makeAllDarkTimer:IsPastSimMS(100) then
						self.makeAllDarkTimer:Reset()
						Ultrakill:FadeInFOG(self)
					end
				end
			else
				if self.makeAllDarkPlease then -- Doublechech
					for i = 1, 4 do
						SceneMan:MakeAllUnseen(Vector(40, 40), i - 1)
					end
					self.makeAllDarkPlease = false
				end
			end
			
			local player = Activity.PLAYER_1
			if self.actorLastPos then
				local pos = self.actorLastPos
				self:SetActorSelectCursor(pos, player)
				self:SetObservationTarget(pos, player);
				SceneMan:SetScrollTarget(pos, 0.1, false, 0)
				
				self.actorLastPos = Vector(self.actorLastPos.X, math.min(self.actorLastPos.Y + TimerMan.DeltaTimeSecs * 30, SceneMan.SceneHeight))
			end

			
			
		elseif self.levelStageCurrent == self.levelStage.GAMEPLAY then
			UltrakillStyle:UpdateStyleSystem(self)
			
			if self.ActivityState ~= Activity.OVER then
				--self.enemyDeaths = self.enemyDeaths + self:GetTeamDeathCount(self.CPUTeam) - self.lastDeathCountCPU;
				
				
				local player = Activity.PLAYER_1
				local actor = self.heroActor
				if actor and actor.Health > 0 then
					--local camPos = SceneMan:MovePointToGround(actor.Pos, 0, 0) + Vector(0, -200)
					--SceneMan:SetScrollTarget(camPos, 0.05, false, 0)
					
					self:SetActorSelectCursor(actor.Pos, player)
					
					self:SetPlayerBrain(actor, player);
					--self:SwitchToActor(actor, player, actor);
					self:SetObservationTarget(actor.Pos, player);
					
					self:GetBanner(GUIBanner.YELLOW, player):ClearText();
					self:GetBanner(GUIBanner.RED, player):ClearText();
					
					if self.basicZones.LevelEnd:IsInside(actor.Pos) then
						self.levelStageCurrent = self.levelStage.OUTRO
						
						Ultrakill:InitializeScoreboard(self)
					end
				else
					FrameMan:ClearScreenText(player)
					--ActivityMan:EndActivity()
					self.gameStageCurrent = self.gameStage.FAILED
					
					self.gameOverTimer:Reset()
					self.gameOverPlayerDeathSound:Play(-1)
					self.gameOverRestartTimer:Reset()
				end
				
			end
			--self.lastDeathCountCPU = self:GetTeamDeathCount(self.CPUTeam);
		end
		
		if self.levelStageCurrent ~= self.levelStage.INTRO and self.levelStageCurrent ~= self.levelStage.OUTRO then
			if self.currentLevelLogicCreate then
				self.currentLevelLogic.Create(self)
				self.currentLevelLogicCreate = false
			end
			self.currentLevelLogic.Update(self)
		end
		
		-- Debug
		if self.DEBUG then
			Ultrakill:DebugZones(self)
		end
		--
	elseif self.gameStageCurrent == self.gameStage.FAILED then
		Ultrakill:UpdateEnemyList(self)
		
		local player = Activity.PLAYER_1
		if self.heroActor and self.heroActor.Health <= 0 then
			SceneMan:SetScrollTarget(self.heroActor.Pos, 0.7, false, 0)
			
			self.actorLastPos = Vector(self.heroActor.Pos.X, self.heroActor.Pos.Y)
		elseif self.actorLastPos then
			local pos = self.actorLastPos
			self:SetActorSelectCursor(pos, player)
			self:SetObservationTarget(pos, player);
			SceneMan:SetScrollTarget(pos, 0.1, false, 0)
		end
		
		if not self.gameOverSprite then
			self.gameOverSprite = CreateMOSRotating("Game Over Skull Sprite", "Ultrakill.rte")
		end
		
		local screenPos = SceneMan:GetOffset(player) + Vector(FrameMan.PlayerScreenWidth * 0.5, FrameMan.PlayerScreenHeight * 0.5)
		
		if self.gameOverTimer:IsPastSimMS(1100) then
			self.gameOverTimer:Reset()
			
			self.gameOverHahSound:Play(-1)
		end
		if not self.gameOverTimer:IsPastSimMS(400) then
			self.gameOverFrame = 1
		else
			self.gameOverFrame = 0
		end
		
		PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), screenPos, self.gameOverSprite, 0, self.gameOverFrame);
		
		local restartTime = 1100 * 5.5
		if self.gameOverRestartTimer:IsPastSimMS(restartTime - 100) then
			self.musicPlayer.Stop()
		end
		if self.gameOverRestartTimer:IsPastSimMS(restartTime) then
			self.musicPlayer.Stop()
			Ultrakill:LoadLevel(self, SceneMan.Scene.PresetName)
		end
	end
	
	self.musicPlayer.Update()
end