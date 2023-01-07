UltrakillMusicPlayer = {}

function UltrakillMusicPlayer:CreateMusicPlayer()
	local musicPlayer
	
	-- Music Player
	musicPlayer = {}
	musicPlayer.Modes = {INACTIVE = 0, SINGLE = 1, LOOP = 2}
	musicPlayer.ModeCurrent = musicPlayer.Modes.INACTIVE
	musicPlayer.TracksMix = {}
	musicPlayer.Tracks = {}
	musicPlayer.Stop = function()
			for i = 1, #musicPlayer.Tracks do
				local track = musicPlayer.Tracks[i]
				track:Stop(-1)
			end
			musicPlayer.Tracks = {}
			musicPlayer.TracksMix = {}
		end
	musicPlayer.Play = function(tracks, mode)
			 -- Stop previous tracks
			musicPlayer.Stop()
			
			if type(tracks) == "table" then -- Many tracks
				musicPlayer.Tracks = tracks
				musicPlayer.TracksMix = {}
				for i = 1, #tracks do
					local volume = i == 1 and 1 or 0
					musicPlayer.TracksMix[i] = volume--math.max(2 - i, 0)
				end
			else -- One Track
				musicPlayer.Tracks = {tracks}
				musicPlayer.TracksMix = {1}
			end
			
			for i = 1, #musicPlayer.Tracks do
				local track = musicPlayer.Tracks[i]
				local mix = musicPlayer.TracksMix[i]
				
				if musicPlayer.ModeCurrent == musicPlayer.Modes.LOOP then
					track.LoopSetting = -1
				else
					track.LoopSetting = 0
				end
				track.Volume = 1.07--mix
				track.AffectedByGlobalPitch = false
				track.Priority = -1
				track:Play(-1)
			end
			
			musicPlayer.ModeCurrent = mode
		end
	musicPlayer.Update = function()
			
			AudioMan:ClearMusicQueue();
			AudioMan:StopMusic();
			
			-- Debug
			if self.DEBUG and self.heroActor then
				local maxi = #musicPlayer.Tracks
				for i = 1, maxi do
					local track = musicPlayer.Tracks[i]
					local mix = musicPlayer.TracksMix[i]
					
					local colors = {111, 218, 46, 145, 85}
					local color = colors[((i - 1) % #colors) + 1]
					
					local factor = ((i / maxi) - 0.5) * 2.0
					
					local pos = self.heroActor.Pos + Vector(60, -20) + Vector(0, 20) * factor
					
					PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(-10, -5), pos + Vector(-10 + 90 * mix, 5), color)
					PrimitiveMan:DrawBoxPrimitive(pos + Vector(-10, -5), pos + Vector(-10 + 90, 5), color)
					PrimitiveMan:DrawTextPrimitive(pos + Vector(-5, -5), track.PresetName, true, 0)
				end
			end
			
			
			if musicPlayer.ModeCurrent ~= musicPlayer.Modes.INACTIVE then
				for i = 1, #musicPlayer.Tracks do
					local track = musicPlayer.Tracks[i]
					local mix = musicPlayer.TracksMix[i]
					
					track.Volume = mix * 1.61 * (1.5 * (self.settingMusicVolume and self.settingMusicVolume or 0.66))
				end
					
				if musicPlayer.ModeCurrent == musicPlayer.Modes.SINGLE then
					local allstoppin = 0
					for i = 1, #musicPlayer.Tracks do
						local track = musicPlayer.Tracks[i]
						allstoppin = allstoppin + (track:IsBeingPlayed() and 0 or 1)
					end
					
					if allstoppin == #musicPlayer.Tracks then
						musicPlayer.Tracks = {}
						musicPlayer.TracksMix = {}
						musicPlayer.ModeCurrent = musicPlayer.Modes.INACTIVE 
					end
				elseif musicPlayer.ModeCurrent == musicPlayer.Modes.LOOP then
					for i = 1, #musicPlayer.Tracks do
						local track = musicPlayer.Tracks[i]
						local mix = musicPlayer.TracksMix[i]
						
						if not track:IsBeingPlayed() then
							track:Play(-1)
						end
					end
					
				end
			end
		end
	
	return musicPlayer
end