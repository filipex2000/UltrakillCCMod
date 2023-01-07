

function Ultrakill:SpawnEnemy(self, position, presetName)
	local createFunctions = {
		["Filth"] = CreateAHuman,
		["Stray"] = CreateAHuman,
		["Schism"] = CreateAHuman,
		["Malicious Face"] = CreateACrab
	}
	local createFunction = createFunctions[presetName]
	
	local actor = createFunction(presetName, "Ultrakill.rte");
	actor.Pos = position --self.levelZones.IntroTrigger:GetCenterPoint().X + 
	actor.Team = self.CPUTeam
	actor.IgnoresTeamHits = true
	actor.HFlipped = math.random(0,1) < 1
	actor:SetNumberValue("Set Target", self.heroActorUID)
	--actor.Health = -100 -- For quick testing!
	if not self.DEBUG then
		actor.HUDVisible = false
	end
	MovableMan:AddActor(actor)
	
	local fx = CreateMOSRotating("Helleport Warp Effect", "Ultrakill.rte")
	fx.Pos = position
	MovableMan:AddParticle(fx)
	fx:GibThis()
	
	table.insert(self.enemies, actor.UniqueID)
	return actor
end


function Ultrakill:UpdateEnemyList(self)
	local player = Activity.PLAYER_1
	local screenPos = SceneMan:GetOffset(player)
	
	local kills = 0
	local killShow = true
	local airshot = false
	
	for i, data in ipairs(self.enemyBosses) do
		local uid = data[1]
		local name = data[2]
		local factorHealth = 0.0
		
		local boss = MovableMan:FindObjectByUniqueID(uid)
		if boss then
			boss = ToActor(boss)
			factorHealth = boss.Health / boss.MaxHealth
			if boss.Health < 0 then
				table.remove(self.enemyBosses, i)
				
				--UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * 2, "BIG KILL"})
				killShow = false
			end
		else
			table.remove(self.enemyBosses, i)
			
			UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * 2, "BIG KILL"})
			killShow = false
		end
		
		-- Draw
		local boxPos = screenPos + Vector(FrameMan.PlayerScreenWidth * 0.4, 30 + 40 * (i - 1))
		local boxWidth = FrameMan.PlayerScreenWidth * 0.6
		local boxHeight = 20 * 0.5
		
		
		PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 + 2 - 8, boxHeight * -1 - 8), boxPos + Vector(boxWidth * 0.5 - 2 + 8, boxHeight * 1 + 8), 242)
		PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 + 2 - 2, boxHeight * -1 - 2), boxPos + Vector(boxWidth * 0.5 - 2 + 2, boxHeight * 1 + 2), 7)
		factorHealth = (factorHealth - 0.5) * 2.0
		
		local colors = {244, 13, 13, 12}
		for i, color in ipairs(colors) do
			local factorA = (i-1) / #colors
			local factorB = (i) / #colors
			
			PrimitiveMan:DrawBoxFillPrimitive(boxPos + Vector(-boxWidth * 0.5 + 2, boxHeight * -1 + boxHeight * 2 * factorA), boxPos + Vector((boxWidth * 0.5 - 2) * factorHealth, boxHeight * -1 + boxHeight * 2 * factorB), color)
		end
		PrimitiveMan:DrawTextPrimitive(boxPos + Vector(0, -boxHeight * 0.66), name, false, 1)
	end
	
	local lastEnemyPositions = self.enemyPositions
	self.enemyPositions = {}
	
	for i, UID in ipairs(self.enemies) do
		local enemy = MovableMan:FindObjectByUniqueID(UID)
		if enemy then
			enemy = ToActor(enemy)
			-- Do something
			if enemy.Health > 0 then
				table.insert(self.enemyPositions, Vector(enemy.Pos.X, enemy.Pos.Y))
			else
				for style, data in pairs(self.styleData) do
					--actor:SetNumberValue("UltrakillHitscanned", actor.Age)
					if enemy:GetNumberValue(style) == 1 then
						local valid = true
						if style == "UltrakillHeadshot" or style == "UltrakillLimb" then
							if not (enemy:NumberValueExists("UltrakillHitscanned") and math.abs(enemy:GetNumberValue("UltrakillHitscanned") - enemy.Age) < 52) then
								valid = false
							end
						end
						if valid then
							UltrakillStyle:AddStyleScore(self, data)
							killShow = false
						end
						
					end
				end
				
				local enemyPos = enemy.Pos
				local groundPos = SceneMan:MovePointToGround(enemyPos, 0, 0)
				if (groundPos.Y - enemyPos.Y) > 40 then
					airshot = true
					killShow = false
				end
				
				local bigFistKill = false
				if (enemy:NumberValueExists("UltrakillPunched") and math.abs(enemy:GetNumberValue("UltrakillPunched") - enemy.Age) < 52) then
					if enemy:NumberValueExists("Big") then
						bigFistKill = true
						
						UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * 2 + 40, "BIG FISTKILL"})
					else
						UltrakillStyle:AddStyleScore(self, {10, "FISTKILL"})
					end
					
					killShow = false
				end
				
				if not bigFistKill and enemy:NumberValueExists("Big") then
					UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * 2, "BIG KILL"})
					killShow = false
				end
				
				table.remove(self.enemies, i)
				self.enemyDeaths = self.enemyDeaths + 1
				kills = kills + 1
			end
		else
			table.remove(self.enemies, i)
			self.enemyDeaths = self.enemyDeaths + 1
			kills = kills + 1
			
			
			-- TODO: add more variants
			if lastEnemyPositions[i] and lastEnemyPositions[i].Y > (SceneMan.Scene.Height - 40) then
				UltrakillStyle:AddStyleScore(self, self.styleData.UltrakillFall)
			else
				UltrakillStyle:AddStyleScore(self, self.styleData.UltrakillGibbed)
			end
			killShow = false
		end
	end
	
	if airshot then
		UltrakillStyle:AddStyleScore(self, self.styleData.UltrakillAirshot)
	end
	
	
	if kills > 0 then
		if kills == 1 then
			if killShow and self.styleMultikill == 0 then
				UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL, "KILL"})
			else
				UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL, ""})
			end
		else
			UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * kills, ""})
		end
		if self.styleMultikill < 1 then
			self.styleMultikillTimer:Reset()
		end
		self.styleMultikill = self.styleMultikill + kills
	end
	
	-- if kills > 0 then
		-- if kills == 1 then
			-- if killShow then
				-- UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL, "KILL"})
			-- else
				-- UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL, ""})
			-- end
		-- elseif kills > 3 then
			-- UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * kills + self.styleKills.MULTIKILL, "MULTIKILL x("..kills..")", true})
		-- elseif kills > 2 then
			-- UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * kills + self.styleKills.DOUBLEKILL, "TRIPLE KILL", true})
		-- elseif kills > 1 then
			-- UltrakillStyle:AddStyleScore(self, {self.styleKills.KILL * kills + self.styleKills.TRIPLEKILL, "DOUBLE KILL", true})
		-- end
	-- end
end

function Ultrakill:AddBoss(self, position, presetName, bossName)
	local newBoss = Ultrakill:SpawnEnemy(self, position, presetName)
	table.insert(self.enemyBosses, {newBoss.UniqueID, bossName})
	return newBoss.UniqueID
end

function Ultrakill:AddEnemyWave(self, enemies)
	--[[
		How to!:
		
		local enemies = {
			{position = Vector(100,200), presetName = "Crab"},
			{position = Vector(150,200), presetName = "Crab"},
			{position = Vector(200,200), presetName = "Crab"}
		}
		
		Ultrakill:AddEnemyWave(self, enemies)
	]]
	local waveID = 1
	for i = 1, (#self.enemyWaves+1) do
		if self.enemyWaves[i] == nil then
			waveID = i
			break
		end
	end
	-- Create wave data!
	local data = {}
	data.SpawnPositions = {}
	data.SpawnPresetNames = {}
	data.EnemyState = {} -- 0 = spawning, 1 = alive, 2 = dead
	data.EnemyUID = {}
	data.EnemyAmount = #enemies
	
	for i, enemy in ipairs(enemies) do 
		data.SpawnPositions[i] = Vector(enemy.position.X, enemy.position.Y)
		data.SpawnPresetNames[i] = enemy.presetName
		data.EnemyState[i] = 0
		data.EnemyUID[i] = -1
	end
	
	self.enemyWaves[waveID] = data
	
	return waveID
end


function Ultrakill:HandleEnemyWaves(self)
	
	--local enemySpawned = false
	
	for j, data in ipairs(self.enemyWaves) do
		if data ~= nil then
			--local data = self.enemyWaves[waveID]
			if data then
				for i = 1, data.EnemyAmount do
					if data.EnemyState[i] == 0 then
						-- Spawn em
						if self.enemyWaveSpawnEnemyTimer:IsPastSimMS(self.enemyWaveSpawnEnemyDelay) then
							local newEnemy = Ultrakill:SpawnEnemy(self, data.SpawnPositions[i], data.SpawnPresetNames[i])
							
							data.EnemyUID[i] = newEnemy.UniqueID
							data.EnemyState[i] = 1
							
							self.enemyWaveSpawnEnemyTimer:Reset()
							self.enemyWaveSpawnEnemyDelay = math.random(self.enemyWaveSpawnEnemyDelayMin, self.enemyWaveSpawnEnemyDelayMax)
						end
						
					elseif data.EnemyState[i] == 1 then
						local enemy = MovableMan:FindObjectByUniqueID(data.EnemyUID[i])
						if not (enemy and ToActor(enemy).Health > 0) then -- oi sorry mate your livin loicence has expired
							data.EnemyState[i] = 2
							data.EnemyUID[i] = -1
						end
					end
				end
			end
			
			Ultrakill:EnemyWaveIsDead(self, j) -- Automatically terminates when everybody is dead
		end
	end
	
end


function Ultrakill:EnemyWaveIsDead(self, waveID)
	local data = self.enemyWaves[waveID]
	if data ~= nil then
		local dead = 0
		for i = 1, data.EnemyAmount do
			dead = (data.EnemyState[i] == 2 and (dead + 1) or dead)
		end
		
		if dead >= data.EnemyAmount then
			self.enemyWaves[waveID] = nil
			return true
		end
		return false
	else
		return true
	end
end
