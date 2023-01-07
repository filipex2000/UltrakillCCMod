
function Ultrakill:SaveSettings(self)
	local filepath = "Ultrakill.rte/Activities/Saves/Settings.save"
	UltrakillFileManager:WriteTableToFile(filepath, self.settings)
end

function Ultrakill:LoadSettings(self)
	-- No need to load the settings again I guess? They are loaded at the start of the activity anyway
	
	self.menuStyle = self.settings.menuTheme
	self.settingMenuThemeText = {self.settingMenuThemeTexts[self.menuStyle+1]}
	
	self.settingMusicVolume = self.settings.musicVolume
	self.settingMusicVolumeText[1] = "Music Volume "..tostring(math.floor(self.settingMusicVolume * 100)).."%"
	self.menuMusic.Volume = 2 * self.settingMusicVolume
	
	self.settingEasy = self.settings.easyMode
	local t = {[true] = "Easy Mode Enabled", [false] = "Easy Mode Disabled"}
	self.settingEasyText[1] = t[self.settingEasy]
end

function Ultrakill:MenuDrawBox(self, posA, posB, selected)
	
	local arrorColor = 174
	
	if self.menuStyle == 0 then
		local colors = {220, 221, 227, 168, 206}
		
		if selected then
			colors = {221, 227, 206, 168, 206}
		end
		
		
		PrimitiveMan:DrawBoxFillPrimitive(posA, posB, colors[1])
		PrimitiveMan:DrawBoxPrimitive(posA, posB, colors[4])
		PrimitiveMan:DrawBoxPrimitive(posA + Vector(-1, -1), posB + Vector(1, 1), colors[3])
		PrimitiveMan:DrawBoxPrimitive(posA + Vector(-1, -1) * 2, posB + Vector(1, 1) * 2, colors[2])
		PrimitiveMan:DrawBoxPrimitive(posA + Vector(-1, -1) * 3, posB + Vector(1, 1) * 3, colors[4])
		
		PrimitiveMan:DrawBoxFillPrimitive(posA + Vector(-1, -1), posA + Vector(-2, -2), colors[5])
		PrimitiveMan:DrawBoxFillPrimitive(Vector(posB.X, posA.Y) + Vector(1, -1), Vector(posB.X, posA.Y) + Vector(2, -2), colors[5])
		
		PrimitiveMan:DrawBoxFillPrimitive(Vector(posA.X, posB.Y) + Vector(-1, 1), Vector(posA.X, posB.Y) + Vector(-2, 2), colors[5])
		PrimitiveMan:DrawBoxFillPrimitive(posB + Vector(1, 1), posB + Vector(2, 2), colors[5])
		
		arrorColor = 174
	elseif self.menuStyle == 1 then
		local colors = {11, 11, 11}
		
		self.menuStyleRedBox = self.menuStyleRedBox + 1
		
		if selected then
			colors = {13, 13, 13}
		end
		
		local maxi = 4
		for i = 1, maxi do
			local color = colors[(i > (maxi / 2) and 1 or 2)]
			
			local randomRange = 1 * i
			local randomValues = self.menuStyleRedRandomValues[self.menuStyleRedBox][i]
			
			local cornerLU = Vector(posA.X, posA.Y) + Vector(randomValues[1], randomValues[2]) * randomRange
			local cornerCU = Vector((posA.X + posB.X) * 0.5, posA.Y) + Vector(randomValues[3], randomValues[4]) * randomRange
			local cornerRU = Vector(posB.X, posA.Y) + Vector(randomValues[5], randomValues[6]) * randomRange
			
			local cornerLB = Vector(posA.X, posB.Y) + Vector(randomValues[7], randomValues[8]) * randomRange
			local cornerCB = Vector((posA.X + posB.X) * 0.5, posB.Y) + Vector(randomValues[9], randomValues[10]) * randomRange
			local cornerRB = Vector(posB.X, posB.Y) + Vector(randomValues[11], randomValues[12]) * randomRange
			
			if i == 1 then
				PrimitiveMan:DrawTriangleFillPrimitive(cornerLB, cornerLU, cornerCU, colors[3])
				PrimitiveMan:DrawTriangleFillPrimitive(cornerRB, cornerRU, cornerCU, colors[3])
				PrimitiveMan:DrawTriangleFillPrimitive(cornerLB, cornerCB, cornerCU, colors[3])
				PrimitiveMan:DrawTriangleFillPrimitive(cornerRB, cornerCB, cornerCU, colors[3])
			end
			
			PrimitiveMan:DrawLinePrimitive(cornerLU, cornerCU, color)
			PrimitiveMan:DrawLinePrimitive(cornerCU, cornerRU, color)
			
			PrimitiveMan:DrawLinePrimitive(cornerRU, cornerRB, color)
			
			PrimitiveMan:DrawLinePrimitive(cornerRB, cornerCB, color)
			PrimitiveMan:DrawLinePrimitive(cornerCB, cornerLB, color)
			
			PrimitiveMan:DrawLinePrimitive(cornerLB, cornerLU, color)
		end
		
		arrorColor = 13
	elseif self.menuStyle == 2 then
		local colors = {48, 47, 13, 12, 10}
		
		if selected then
			colors = {48, 47, 13, 12, 10}
		end
		
		
		PrimitiveMan:DrawBoxFillPrimitive(posA, posB + Vector(2,2), colors[5])
		
		PrimitiveMan:DrawBoxFillPrimitive(posA + Vector(0, -2), Vector(posB.X, posA.Y), colors[1])
		PrimitiveMan:DrawBoxFillPrimitive(posA + Vector(-2, -2), posA + Vector(0, 0), colors[2])
		
		PrimitiveMan:DrawBoxFillPrimitive(Vector(posB.X, posA.Y) + Vector(2, -2), Vector(posB.X, posA.Y) + Vector(0, 0), colors[2])
		PrimitiveMan:DrawBoxFillPrimitive(Vector(posB.X, posA.Y) + Vector(2, 0), Vector(posB.X, posA.Y) + Vector(0, 1), colors[3])
		PrimitiveMan:DrawBoxFillPrimitive(Vector(posB.X, posA.Y) + Vector(2, 1), Vector(posB.X, posA.Y) + Vector(0, 2), colors[4])
		
		PrimitiveMan:DrawBoxFillPrimitive(posA + Vector(-2, 0), Vector(posA.X, posB.Y) + Vector(0, -1), colors[3])
		PrimitiveMan:DrawBoxFillPrimitive(Vector(posA.X, posB.Y) + Vector(-2, -1), Vector(posA.X, posB.Y) + Vector(0, 0), colors[4])
		
		PrimitiveMan:DrawBoxFillPrimitive(posA, posB, colors[3])
		
		arrorColor = 48
	elseif self.menuStyle == 3 then
		
		if selected then
			PrimitiveMan:DrawBoxFillPrimitive(posA, posB, 168)
		end
		
		PrimitiveMan:DrawBoxPrimitive(posA + Vector(-1, -1), posB + Vector(1, 1), 4)
		PrimitiveMan:DrawBoxPrimitive(posA + Vector(-1, -1) * 2, posB + Vector(1, 1) * 2, 4)
		
		arrorColor = 4
	end
	
	if selected then
		local factor = math.sin(self.menuSelectAnimationFactor * math.pi * 0.5)
		
		local center = (posA.Y + posB.Y) * 0.5
		PrimitiveMan:DrawTriangleFillPrimitive(Vector(posA.X - 15 * factor, center - 5 * factor), Vector(posA.X - 15 * factor, center + 5 * factor), Vector(posA.X - 10 * factor, center), arrorColor)
		PrimitiveMan:DrawTriangleFillPrimitive(Vector(posB.X + 15 * factor, center - 5 * factor), Vector(posB.X + 15 * factor, center + 5 * factor), Vector(posB.X + 10 * factor, center), arrorColor)
	end
end

function Ultrakill:MenuOnMenuChange(self)
	self.menuCurrentButton = 0
	self.menuSoundMenuChange:Play(-1)
	self.menuShakeFactor = 1
end

function Ultrakill:MenuCreate(self)
	-- for i = 1, 4 do
		-- SceneMan:MakeAllUnseen(Vector(32, 32), i - 1)
	-- end
	
	self.menuActor = nil
	self.menuActorUID = nil
	
	self.menuStyle = 0
	self.menuStyles = 4
	
	self.menuStyleRedRandomValuesRandomizeTimer = Timer()
	self.menuStyleRedRandomValues = {}
	self.menuStyleRedBox = 0
	for x = 1, 32 do 
		self.menuStyleRedRandomValues[x] = {}
		for i = 1, 8 do
			self.menuStyleRedRandomValues[x][i] = {}
			
			for j = 1, 12 do
				self.menuStyleRedRandomValues[x][i][j] = RangeRand(-1,1)
			end
		end
	end
	
	self.menuCenter = Vector(SceneMan.SceneWidth, SceneMan.SceneHeight) * 0.5
	
	AudioMan:ClearMusicQueue();
	AudioMan:StopMusic();
	
	-- Cursor!
	local actor = CreateActor("Ultrakill Menu Cursor", "Ultrakill.rte");
	actor.Pos = self.menuCenter;
	actor.Team = self.playerTeam;
	actor.IgnoresTeamHits = true;
	actor.HUDVisible = false
	self:SwitchToActor(actor, 0, 0)
	MovableMan:AddActor(actor);
	
	self.lastInputVector = Vector(0, 0)
	self.lastInputPress = false
	
	self.menuSoundMenuChange = CreateSoundContainer("Main Menu Menu Change", "Ultrakill.rte");
	self.menuSoundMenuChange.Pitch = 0.5
	self.menuSoundSelect = CreateSoundContainer("Main Menu Select", "Ultrakill.rte");
	self.menuSoundMove = CreateSoundContainer("Main Menu Move", "Ultrakill.rte");
	self.menuSoundMove.Pitch = 2
	
	self.menuMusic = CreateSoundContainer("Menu Normal", "Ultrakill.rte");
	self.menuMusic.Volume = 2
	self.menuMusic:Play(-1)
	
	self.menuIntroFactor = 0
	self.menuOutroFactor = 0
	
	self.spawnCrabTimer = Timer()
	
	self.sceneToLoad = nil
	
	-- Actual settings (these are saved)
	
	-- Pointer hack settings
	-- PRO PROGRAMMER MOVE
	self.settingMusicVolumeText = {"Music Volume 100%"}
	self.settingMusicVolume = 1
	
	self.settingEasyText = {"Easy Mode"}
	self.settingEasy = false
	
	self.settingMenuThemeTexts = {"Menu Style CLASSIC", "Menu Style RED", "Menu Style ULTRA", "Menu Style Simple"}
	self.settingMenuThemeText = {self.settingMenuThemeTexts[self.menuStyle+1]}
	
	self.menuData = {
		Main = {
			Offset = Vector(0, 30),
			Mode = "Vertical",
			Buttons = {
				{
					Text = "Play",
					Hint = "Level selection screen.",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.LevelSelect
					end
				},
				{
					Text = "Settings",
					Hint = "Customize your experience.",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.Settings
					end
				},
				{
					Text = "About",
					Hint = "Information regarding the mod.",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.Info
					end
				},
				{
					Text = "Credits",
					Hint = "All the contributors, it might be about someone you might know or perhaps even you!",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.Credits
						self.menuCurrent.TextScrollTimer:Reset()
					end
				}
			}
		},
		Credits = {
			Offset = Vector(0, 190),
			Mode = "Horizontal",
			Text = {
				"-- Lead: --",
				"fil | filipe | filipex2000 - scripting, sprites, mapmaking, literally everything lmao",
				"",
				"-- Support: --",
				"pawnis | hoovy | elmannomagnifico - general support, number 1 motivation speaker, playtesting, epic sound-man mentor",
				"",
				"-- Original game design, sounds, textures and music: --",
				"Hakita | Arsi Patala | aka Heaven Pierce Her",
				"All other Ultrakill and New Blood Interactive devs",
				"",
				"-- Code bits shamelessly stolen from: --",
				"4zK (original Mario stomp and POW code for V1, 4Zombie activity used for research and educational purposes)",
				"Cave | CaveCricket48 (Fermat Spiral code for explosions)",
				"Weegee (Void Wardeners scripts used for research and educational purposes)",
				"",
				"-- Special thanks to: --",
				"All the folks from Cortex Command Center community",
				"All the epic open source contributors from Cortex Command Community Porject community",
				"All the CC modders",
				"Developers of Ultrakill and New Blood Interactive",
				"",
				"-- Personal thanks to: --",
				"Thank you pawnis, for being a great friend",
				"Thank you Gacyr, for all the help with code",
				"Thank you MyNameIsTrez, for all the help with Lua",
				"Thank you Gotcha, for all the help with mapmaking",
				"Thank you Just Alex, for being a great person and talented modder",
				"Thank you Khromosomeking, for being a good friend, may God be with you",
				"Thank you Data, for creating this incredible game",
				"Thank you Miro, for being a good friend",
				"Thank you mkster, for being a good friend and teaching me Lua",
				"Thank you RedCaptain, for being a good friend",
				"Thank you Gazyli, for being a good friend",
				"Thank you Kogha, for being a good friend",
				"Thank you Rysz, for being a good friend",
				"Thank you G3, for being a good friend",
				"Thank you Bumrush, for being a good friend",
				"Thank you Sizzlemoon, for being a good friend",
				"Thank you flameport, for being flameport",
				"Thank you asdi, for being asdi",
				"Special thanks to my friends and family, for all the support",
				"Especially to my dearest brother, whom I respect the most",
				"",
				"And finally YOU, yes YOU! for playing the mod!",
			},
			TextScroll = 0,
			TextScrollMaxLines = 10,
			TextScrollTimer = Timer(),
			Buttons = {
				{
					Text = "Go Back",
					Hint = "Use arrow keys (up | down) to scroll.", -- Hack
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.Main
					end
				}
			}
		},
		Info = {
			Offset = Vector(0, 190),
			Mode = "Vertical",
			Text = {
				"Welcome to the demo version of Ultrakill.rte mod!",
				"Please keep in mind that I do not hold any rights to original game, ULTRAKILL!",
				"Remember to check out the steam page and maybe even buy it or try it, there's a free demo!",
				"",
				"I've spent many months working on this project, it sure was fun!",
				"I hope you enjoyed it and thank you so much for playing!",
				"",
				"Stay tuned for further updates and new projects:",
				"filipe"
			},
			Buttons = {
				{
					Text = "Go Back",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.Main
					end
				}
			}
		},
		LevelSelect = {
			Offset = Vector(0, 190),
			Mode = "Horizontal",
			LevelIndex = -1,
			LevelCount = #self.levelList,
			Buttons = {
				{
					Text = "Go Back",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.Main
					end
				},
				{
					Text = "Equip Weapons",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.LoadoutSelect
					end
				}
			}
		},
		LoadoutSelect = {
			Offset = Vector(0, 190),
			Mode = "Horizontal",
			Buttons = {
				{
				Text = "Go Back",
				OnPress = function()
					Ultrakill:MenuOnMenuChange(self)
					self.menuCurrent = self.menuData.LevelSelect
				end
				}
			}
		},
		Settings = {
			Offset = Vector(0, 30),
			Mode = "Rows",
			ButtonsPerRow = 2,
			Buttons = {
				{
					Text = "Go Back",
					OnPress = function()
						Ultrakill:MenuOnMenuChange(self)
						self.menuCurrent = self.menuData.Main
					end
				},
				{
					Text = self.settingEasyText,
					Hint = "Easy mode enables respawns, each death lowers both your score and rank! CURRENTLY NOT AVAILABLE!",
					OnPress = function()
						-- Swap table elements
						self.settingEasy = not self.settingEasy
						local t = {[true] = "Easy Mode Enabled", [false] = "Easy Mode Disabled"}
						self.settingEasyText[1] = t[self.settingEasy]
						
						self.settings.easyMode = self.settingEasy
						Ultrakill:SaveSettings(self)
					end
				},
				{
					Text = self.settingMusicVolumeText,
					Hint = "Change music volume to your liking! (Setting the volume to 0% completely disables music and makes the game completely unenjoyable experience)",
					OnPress = function()
						self.settingMusicVolume = (self.settingMusicVolume - 0.1) % 1.1
						self.settingMusicVolumeText[1] = "Music Volume "..tostring(math.floor(self.settingMusicVolume * 100)).."%"
						
						self.menuMusic.Volume = 2 * self.settingMusicVolume
						
						self.settings.musicVolume = self.settingMusicVolume
						Ultrakill:SaveSettings(self)
					end
				},
				{
					Text = self.settingMenuThemeText,
					Hint = "Change the theme of main menu! Purely visual.",
					OnPress = function()
						self.menuStyle = (self.menuStyle+1) % (self.menuStyles)
						self.settingMenuThemeText[1] = self.settingMenuThemeTexts[self.menuStyle+1]
						
						self.settings.menuTheme = self.menuStyle
						Ultrakill:SaveSettings(self)
					end
				}
			}
		}
	}
	self.menuCurrent = self.menuData.Main
	self.menuCurrentButton = 0
	
	self.menuSelectAnimationFactor = 0
	self.menuShakeFactor = 0
	
	self.menuFlybyAnimation = 0
	
	local decorV1 = CreateAHuman("V1", "Ultrakill.rte");
	decorV1.Pos = self.menuCenter;
	decorV1.Team = 3;
	decorV1.IgnoresTeamHits = true;
	decorV1.HUDVisible = false
	decorV1:SetNumberValue("DisableHUD", 1)
	MovableMan:AddActor(decorV1);
	
	self.decorV1 = decorV1
	
	self.menuActor = actor
	self.menuActorUID = actor.UniqueID
	
	Ultrakill:LoadSettings(self)
end

function Ultrakill:MenuUpdate(self)
	
	if self.menuStyle == 1 then
		self.menuStyleRedBox = 0
		if self.menuStyleRedRandomValuesRandomizeTimer:IsPastSimMS(100) then
			for x = 1, 32 do 
				self.menuStyleRedRandomValues[x] = {}
				for i = 1, 8 do
					self.menuStyleRedRandomValues[x][i] = {}
					
					for j = 1, 12 do
						self.menuStyleRedRandomValues[x][i][j] = RangeRand(-1,1)
					end
				end
			end
			self.menuStyleRedRandomValuesRandomizeTimer:Reset()
		end
	end
	
	if self.menuActorUID then
		if not MovableMan:FindObjectByUniqueID(self.menuActorUID) then
			self.menuActor = nil
		end
	else
		self.menuActorUID = nil
	end
	self.menuIntroFactor = math.min(self.menuIntroFactor + TimerMan.DeltaTimeSecs * 0.3, 1)
	self.menuFlybyAnimation = (self.menuFlybyAnimation - TimerMan.DeltaTimeSecs * 3) % 2
	
	self.menuShakeFactor = math.max(self.menuShakeFactor - TimerMan.DeltaTimeSecs * 4, 0)
	
	local menuPos = self.menuCenter + Vector(0, -FrameMan.PlayerScreenHeight * 1.1 * math.pow((1 - self.menuIntroFactor), 3)) + Vector(0, FrameMan.PlayerScreenHeight * 1.1 * math.pow(self.menuOutroFactor, 3))
	if self.menuActor then
		-- Crab
		if self.spawnCrabTimer:IsPastSimMS(30000 * RangeRand(0.2, 5)) then
			local actor = CreateACrab("Crab", "Base.rte");
			actor.Pos = self.menuCenter + Vector(FrameMan.PlayerScreenWidth * RangeRand(-0.35, 0.35), FrameMan.PlayerScreenHeight * 0.6)
			actor.Team = 4;
			actor.Vel = Vector(RangeRand(-1, 1) * 1, RangeRand(0.75,2.0) * -10)
			actor.RotAngle = RangeRand(-2, 2) * math.pi
			actor.AngularVel = RangeRand(-1, 1) * 25
			actor.GlobalAccScalar = 0.0
			actor.HitsMOs = false
			actor.GetsHitByMOs = false
			actor.IgnoresTeamHits = true;
			actor.HUDVisible = false
			MovableMan:AddActor(actor);
			
			for limb in actor.Attachables do
				limb.HitsMOs = false
				limb.GetsHitByMOs = false
			end
			
			self.spawnCrabTimer:Reset()
		end
		
		local randomFacA = math.sin(self.decorV1.Age / 1000) * 0.75 + math.cos(self.decorV1.Age / 2000 + 5) + math.cos(-self.decorV1.Age / 500 + 1) * 0.5 + math.sin(-self.decorV1.Age / 3000 + 15) * 2 + math.sin(self.decorV1.Age / 9000 + 99) * 2
		local randomFacB = math.sin(self.decorV1.Age / 1100 + 15) * 0.6 + math.cos(self.decorV1.Age / 1700 - 77) * 0.4 + math.cos(-self.decorV1.Age / 600 + 1) * 0.8 + math.sin(-self.decorV1.Age / 3500 + 66) * 1.5 + math.sin(-self.decorV1.Age / 8000 + 59) * 2
		local randomFacC = math.sin(self.decorV1.Age / 800 - 5) * 0.6 + math.sin(self.decorV1.Age / 1700 - 77) * 0.4 + math.cos(-self.decorV1.Age / 1300 + 55) * 0.7 + math.cos(-self.decorV1.Age / 600 + 5) * 1.1 + math.sin(-self.decorV1.Age / 8000 + 3) * 1.5
		
		if self.decorV1:IsPlayerControlled() then
			self:SwitchToActor(self.menuActor, 0, 0)
		end
		
		self.decorV1.Pos = self.menuCenter + Vector(0, -50) + Vector(randomFacA * 6, randomFacB * 3) + Vector(0, FrameMan.PlayerScreenHeight * 1.1 * math.pow(math.max((self.menuOutroFactor - 1) / 2, 0), 3))
		self.decorV1.RotAngle = math.rad(randomFacC * 7)
		self.decorV1.Vel = self.decorV1.Vel * 0.9
		
		if math.random() < 0.001 then
			self.decorV1.HFlipped = math.random() < 0.5 
		end
		
		-- Set Camera
		local player = Activity.PLAYER_1
		local pos = self.menuCenter
		self:SetActorSelectCursor(pos, player)
		self:SetObservationTarget(pos, player);
		SceneMan:SetScrollTarget(pos, 0.1, false, 0)
		
		-- Input
		local ctlr = self.menuActor:GetController()
		local inputPress = ctlr:IsState(Controller.WEAPON_FIRE)
		local inputVector = Vector((ctlr:IsState(Controller.MOVE_RIGHT) and 1 or 0) - (ctlr:IsState(Controller.MOVE_LEFT) and 1 or 0), (ctlr:IsState(Controller.BODY_CROUCH) and 1 or 0) - (ctlr:IsState(Controller.BODY_JUMP) and 1 or 0))
		
		local justPressed = false
		
		if self.sceneToLoad then
			self.menuOutroFactor = math.min(self.menuOutroFactor + TimerMan.DeltaTimeSecs, 3)
			if self.menuOutroFactor > 2.99 then
				Ultrakill:LoadLevel(self, self.sceneToLoad)
			end
		else
			-- Just pressed signal!
			if self.lastInputPress ~= inputPress then
				self.lastInputPress = inputPress
				if inputPress then
					justPressed = true
					self.menuSoundSelect:Play(-1)
					
					for i, button in ipairs(self.menuCurrent.Buttons) do
						if i == (self.menuCurrentButton+1) and button.OnPress then
							button.OnPress()
						end
					end
				end
			end
			
			if self.lastInputVector.X ~= inputVector.X or self.lastInputVector.Y ~= inputVector.Y then
				self.lastInputVector = Vector(inputVector.X, inputVector.Y)
				
				-- Special credits behaviour
				if self.menuCurrent == self.menuData.Credits then
					--if self.menuCurrent.TextScrollTimer:IsPastSimMS(1000) then
					self.menuCurrent.TextScrollTimer:Reset()
					self.menuCurrent.TextScroll = (self.menuCurrent.TextScroll + inputVector.Y) % #self.menuCurrent.Text
					--end
				end 
				
				-- Navigate around!
				if self.menuCurrent.Mode == "Vertical" then
					if inputVector.Y ~= 0 then
						self.menuSoundMove:Play(-1)
						
						self.menuCurrentButton = (self.menuCurrentButton + inputVector.Y) % (#self.menuCurrent.Buttons)
						self.menuSelectAnimationFactor = 0
					end
				elseif self.menuCurrent.Mode == "Horizontal" then
					
					if inputVector.Y ~= 0 and self.menuCurrent == self.menuData.LevelSelect then
						if self.menuData.LevelSelect.LevelIndex == -1 then
							self.menuData.LevelSelect.LevelIndex = (inputVector.Y) % (self.menuData.LevelSelect.LevelCount)
						else
							self.menuData.LevelSelect.LevelIndex = (self.menuData.LevelSelect.LevelIndex + inputVector.Y) % (self.menuData.LevelSelect.LevelCount)
						end
						
						self.menuSoundMove:Play(-1)
						self.menuCurrentButton = -1
					end
					
					if inputVector.X ~= 0 then
						self.menuSoundMove:Play(-1)
						
						self.menuData.LevelSelect.LevelIndex = -1
						
						self.menuCurrentButton = (self.menuCurrentButton + inputVector.X) % (#self.menuCurrent.Buttons)
						self.menuSelectAnimationFactor = 0
					end
				elseif self.menuCurrent.Mode == "Rows" then
					if inputVector.X ~= 0 or inputVector.Y ~= 0 then
						self.menuSoundMove:Play(-1)
						
						self.menuCurrentButton = (self.menuCurrentButton + inputVector.X + inputVector.Y * self.menuCurrent.ButtonsPerRow) % (#self.menuCurrent.Buttons)
						self.menuSelectAnimationFactor = 0
					end
				end
			end
		end
		
		
		if self.menuCurrent == self.menuData.Credits and self.menuCurrent.TextScrollTimer:IsPastSimMS(200) then
			self.menuCurrent.TextScrollTimer:Reset()
			self.menuCurrent.TextScroll = (self.menuCurrent.TextScroll + inputVector.Y) % #self.menuCurrent.Text
		end
		
		--- Draw
		self.menuSelectAnimationFactor = math.min(self.menuSelectAnimationFactor + TimerMan.DeltaTimeSecs * 5, 1)
		
		-- Flyby epicness
		local columnColors = {
			{240, 7, 239, 238},
			{239, 238, }
		}
		for column = 0, 1 do
			for i = -1, 1 do
				if i ~= 0 then
					local factor = (((self.menuFlybyAnimation + column * 0.5) % 1) - 0.5) * 2
					--local pos = menuPos + Vector(FrameMan.PlayerScreenWidth * i * 0.5, FrameMan.PlayerScreenHeight * factor * 0.8)
					local pos = self.decorV1.Pos + Vector(FrameMan.PlayerScreenWidth * i * 0.5, FrameMan.PlayerScreenHeight * factor * 0.8)
					
					
					local height = 70 * 0.5
					local width = 70
					
					--local colors = {8, 7, 6, 238}
					local colors = columnColors[column+1]
					for j = 1, #colors do
						local smearFactor = 1 + (1 - (j / #colors)) * 2
						PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-width * (smearFactor + 1) * 0.5, -height * smearFactor), pos + Vector(width * (smearFactor + 1) * 0.5, height * smearFactor), colors[#colors - j + 1])
					end
				end
			end
		end
		
		-- Logo
		if not self.logoSprite then
			self.logoSprite = CreateMOSRotating("ULTRAKILL Logo Sprite", "Ultrakill.rte")
		end
		PrimitiveMan:DrawBitmapPrimitive(ActivityMan:GetActivity():ScreenOfPlayer(player), menuPos + Vector(0, FrameMan.PlayerScreenHeight * -0.5 + 82), self.logoSprite, 0, 0);
		PrimitiveMan:DrawTextPrimitive(menuPos + Vector(0, FrameMan.PlayerScreenHeight * -0.5 + 82 + 41), "-- D E M O --", false, 1)
		
		local menuShake = Vector(RangeRand(-1,1), RangeRand(-1,1)) * math.pow(self.menuShakeFactor, 2) * 5
		
		--- Menu
		if self.menuCurrent then
			-- Menu buttons
			for i, button in ipairs(self.menuCurrent.Buttons) do
				local buttonText = (type(button.Text) == "table" and button.Text[1] or button.Text)
				
				local selected = i == (self.menuCurrentButton+1)
				local selectFactor = math.sin(math.sin(self.menuSelectAnimationFactor * math.pi * 0.5) * math.pi * 0.5) * 0.5
				
				local buttonHeight = 30
				local buttonWidth = 25 + 6 * 20
				--local buttonWidth = 25 + 6 * string.len(buttonText)
				
				local buttonPos = menuPos + self.menuCurrent.Offset + menuShake
				if self.menuCurrent.Mode == "Vertical" then
					buttonPos = buttonPos + Vector(0, (buttonHeight + 20) * (i - 1))
				elseif self.menuCurrent.Mode == "Horizontal" then
					buttonPos = buttonPos + Vector((buttonWidth * 1.25 + 20) * ((i - #self.menuCurrent.Buttons * 0.5) - 0.5), 0)
				elseif self.menuCurrent.Mode == "Rows" then
					local perRow = self.menuCurrent.ButtonsPerRow
					local row = math.floor(i / perRow + 0.5)
					local j = ((i-1) % (perRow)) - 0.5
					buttonPos = buttonPos + Vector((buttonWidth * 1.25 + 20) * j, (buttonHeight + 20) * row)
				end
				
				if selected then
					buttonWidth = buttonWidth * (1 + 0.5 * selectFactor)
				end
				
				Ultrakill:MenuDrawBox(self, buttonPos + Vector(buttonWidth * -0.5, buttonHeight * -0.5), buttonPos + Vector(buttonWidth * 0.5, buttonHeight * 0.5), selected)
				

				-- if selected then
					-- local letters = {}
					-- buttonText:gsub(".",function(c) table.insert(letters,c) end)
					-- for i, letter in ipairs(letters) do
						-- local factor = (i / #letters - 0.5) * 2.0
						-- PrimitiveMan:DrawTextPrimitive(buttonPos + Vector((3 + 2 * selectFactor) * (#letters * factor - #letters * 0.2), -8), letter, false, 1)
					-- end
				-- else
				PrimitiveMan:DrawTextPrimitive(buttonPos + Vector(0, -8), buttonText, false, 1)
				--end
				
				if selected and button.Hint then
					PrimitiveMan:DrawTextPrimitive(menuPos + Vector(0, FrameMan.PlayerScreenHeight * 0.5 - 30), button.Hint, true, 1)
				end
			end
		end
		
		if self.menuCurrent == self.menuData.LevelSelect then
			PrimitiveMan:DrawTextPrimitive(menuPos + Vector(0, -18), "P R E L U D E", false, 1)
			
			for i, level in ipairs(self.levelList) do
				local text = key
				if level then
					text = level.Name
				end
				
				local selected = i == (self.menuData.LevelSelect.LevelIndex+1)
				
				if not self.sceneToLoad and selected and justPressed then
					if level ~= LevelWorkInProgress then
						self.sceneToLoad = self.levelListNames[i]
						--Ultrakill:LoadLevel(self, self.levelListNames[i])
					end
				end
				
				if not self.rankIconSprite then
					self.rankIconSprite = CreateMOSRotating("Rank Icon Sprite", "Ultrakill.rte")
					self.rankIconBigSprite = CreateMOSRotating("Rank Icon Big Sprite", "Ultrakill.rte")
				end
				local labelPos = menuPos + Vector(0, 16 + 26 * (i - 1))
				
				Ultrakill:MenuDrawBox(self, labelPos + Vector(-65, -8), labelPos + Vector(65, 8), selected)
				
				PrimitiveMan:DrawTextPrimitive(labelPos + Vector(0, -7), text, false, 1)
			end
		else
			self.menuData.LevelSelect.LevelIndex = -1
		end
		
		
		if self.menuCurrent == self.menuData.Info then
			for i, line in ipairs(self.menuCurrent.Text) do
				PrimitiveMan:DrawTextPrimitive(menuPos + Vector(0, 15 + 14 * (i - 1)), line, false, 1)
			end
		end
		
		if self.menuCurrent == self.menuData.Credits then
			local lines = {}
			for i, line in ipairs(self.menuCurrent.Text) do
				--self.menuCurrent.TextScrollMaxLines
				if i > self.menuCurrent.TextScroll and #lines < self.menuCurrent.TextScrollMaxLines then
					table.insert(lines, line)
				end
				
			end
			
			for i, line in ipairs(lines) do
				PrimitiveMan:DrawTextPrimitive(menuPos + Vector(0, 15 + 14 * (i - 1)), line, false, 1)
			end
			
			-- if self.menuCurrent.TextScrollTimer:IsPastSimMS(1000) then
				-- self.menuCurrent.TextScrollTimer:Reset()
				-- self.menuCurrent.TextScroll = (self.menuCurrent.TextScroll + 1) % #self.menuCurrent.Text
			-- end
		end 
	end
	
end