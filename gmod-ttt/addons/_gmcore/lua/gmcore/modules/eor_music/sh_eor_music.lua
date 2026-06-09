local MUSIC_CATALOG_DIR = "gmcore/config/eor_music/"
local MUSIC_CATALOG_FILE = "music_default.json"
local forcedNextSong = nil

---End of round music system. Plays a random song from a catalog on round end.
---@class EorSongEntry
---@field [1] string URL of the song
---@field [2] string Display name of the song

gmcore.EorMusic = gmcore.EorMusic or {}
---@type table<number, EorSongEntry[]>
gmcore.EorMusic.SoundUrls = util.JSONToTable(file.Read(MUSIC_CATALOG_DIR .. MUSIC_CATALOG_FILE, "DATA") or "[]") or {} -- Holds list of songs to be played
---@type string[]
gmcore.EorMusic.PrevPlayedSongs = {} -- Once a song is played it is inserted into here. Then checked if this table has song

if #gmcore.EorMusic.SoundUrls <= 0 then
	gmcore.DebugPrint("EoR Music: No songs found in catalog file or file not found!")
else
	local totalSongs = 0

	for _, songs in pairs(gmcore.EorMusic.SoundUrls) do
		totalSongs = totalSongs + #songs
	end

	gmcore.DebugPrint("EoR Music: Loaded " .. tostring(totalSongs) .. " songs from catalog.")
end

if SERVER then
	---@param winType number TTT win type constant (WIN_INNOCENT, WIN_TRAITOR, etc.)
	---@return EorSongEntry|false song A random unplayed song entry for the win type, or false if none available
	local function pickRandomSong(winType)
		if forcedNextSong then
			local song = forcedNextSong
			forcedNextSong = nil

			return song
		end

		local availableSongs = gmcore.EorMusic.SoundUrls[winType]
		if not availableSongs or #availableSongs == 0 then return false end

		local unplayedSongs = {}

		for _, song in ipairs(availableSongs) do
			if not table.HasValue(gmcore.EorMusic.PrevPlayedSongs, song[1]) then
				table.insert(unplayedSongs, song)
			end
		end

		-- If no unplayed songs remain, reset the played list and use all songs
		if #unplayedSongs == 0 then
			gmcore.EorMusic.PrevPlayedSongs = {}
			unplayedSongs = availableSongs
		end

		local selectedSong = unplayedSongs[math.random(#unplayedSongs)]
		table.insert(gmcore.EorMusic.PrevPlayedSongs, selectedSong[1])

		-- Catalog stores paths relative to the configured forum URL; resolve here before broadcast.
		local base = ((gmcore.ForumsBaseUrl or ""):gsub("/+$", ""))

		return { base .. selectedSong[1], selectedSong[2] }
	end

	util.AddNetworkString("TTT_PlayMusic")
	util.AddNetworkString("ChatCommand")

	hook.Add("TTTEndRound", "PlayEndRoundMusic", function(winType)
		local tRandomSong = pickRandomSong(winType)
		if not tRandomSong then return end
		net.Start("TTT_PlayMusic")
		net.WriteTable(tRandomSong)
		net.Broadcast()
	end)

	hook.Add("PlayerSay", "gmcore.Modules.EoRMusicStopChat", function(ply, text)
		if text == "!stop" then
			net.Start("ChatCommand")
			net.Send(ply)

			return true
		end
	end)

	---Helper function to get all songs from all categories
	---@return {[1]: string, [2]: string, [3]: number}[]
	local function getAllSongs()
		local allSongs = {}
		for winType, songs in pairs(gmcore.EorMusic.SoundUrls) do
			for _, song in ipairs(songs) do
				table.insert(allSongs, {song[1], song[2], winType})
			end
		end

		return allSongs
	end

	concommand.Add("gmcore_list_songs", function(ply, cmd, args)
		local winTypeNames = {
			[WIN_INNOCENT] = "Innocent",
			[WIN_TRAITOR] = "Traitor",
			[WIN_TIMELIMIT] = "Timelimit"
		}

		for winType, songs in pairs(gmcore.EorMusic.SoundUrls) do
			local typeName = winTypeNames[winType] or "Unknown"
			ply:PrintMessage(HUD_PRINTCONSOLE, "=== " .. typeName .. " Songs ===")
			for _, song in ipairs(songs) do
				ply:PrintMessage(HUD_PRINTCONSOLE, "  " .. song[2])
			end
			ply:PrintMessage(HUD_PRINTCONSOLE, "")
		end
	end)
else
	local cvarEnabled = CreateClientConVar("gmcore_music_enabled", "1", true, false)
	local cvarAltTab = CreateClientConVar("gmcore_music_alttab", "1", true, false)
	local cvarVolume = CreateClientConVar("gmcore_music_volume", ".50", true, false)
	local enabled = cvarEnabled:GetBool()
	local playUnFocused = cvarAltTab:GetBool()
	local volume = cvarVolume:GetFloat()
	local soundObject

	-- Shared vars for music panel
	local songStartTime, songDuration, sEndSongText, iTextW, iTextH, iEoRSongBoxX, iEoRSongBoxY

	---Smoothly fades out the currently playing end-of-round music
	local function lerpSoundClose()
		if not soundObject or not IsValid(soundObject) or soundObject == nil then return end
		local fLerpSound = volume
		local panelAlpha = 255

		hook.Add("Think", "gmcore.SmoothEoRVolume", function()
			fLerpSound = Lerp(2 * FrameTime(), fLerpSound, 0)
			panelAlpha = Lerp(3 * FrameTime(), panelAlpha, 0)
			soundObject:SetVolume(fLerpSound)

			if fLerpSound < 0.003 then
				soundObject:Stop()
				hook.Remove("Think", "gmcore.SmoothEoRVolume")
				timer.Simple(0.5, function()
					hook.Remove("HUDPaint", "gmcore.EoRSongPanel")
					hook.Remove("HUDPaint", "gmcore.EoRSongPanelFade")
				end)
			end
		end)

		hook.Remove("HUDPaint", "gmcore.EoRSongPanel")
		hook.Add("HUDPaint", "gmcore.EoRSongPanelFade", function()
			local currentAlpha = math.max(0, panelAlpha)

			if currentAlpha > 5 then
				local timeElapsed = CurTime() - songStartTime
				local progress = math.Clamp(timeElapsed / songDuration, 0, 1)
				local remainingWidth = math.max(0, (iTextW + 16) * (1 - progress))

				surface.SetDrawColor(FRAME_BACKGROUND_COLOR.r, FRAME_BACKGROUND_COLOR.g, FRAME_BACKGROUND_COLOR.b, currentAlpha * 0.94)
				surface.DrawRect(iEoRSongBoxX, iEoRSongBoxY, iTextW + 16, iTextH + 16)

				surface.SetDrawColor(COMMUNITY_PRIMARY_COLOR.r, COMMUNITY_PRIMARY_COLOR.g, COMMUNITY_PRIMARY_COLOR.b, currentAlpha)
				surface.DrawRect(iEoRSongBoxX, iEoRSongBoxY, remainingWidth, 6)

				surface.SetFont("Trebuchet24")
				surface.SetTextColor(255, 255, 255, currentAlpha)
				surface.SetTextPos(iEoRSongBoxX + 8, iEoRSongBoxY + 10)
				surface.DrawText(sEndSongText)
			else
				hook.Remove("HUDPaint", "gmcore.EoRSongPanelFade")
			end
		end)
	end

	---Sets instantly end of round music object sound volume if correct, else nil
	---@param iNewVol number Volume to set
	function gmcore:ChangeEoRVolume(iNewVol)
		if not IsValid(soundObject) or soundObject == nil then return end

		soundObject:SetVolume(iNewVol)
	end

	cvars.AddChangeCallback("gmcore_music_enabled", function(_, old, new)
		enabled = tobool(new)
	end)

	cvars.AddChangeCallback("gmcore_music_alttab", function(_, old, new)
		playUnFocused = tobool(new)
	end)

	cvars.AddChangeCallback("gmcore_music_volume", function(_, old, new)
		volume = tonumber(new)
	end)

	net.Receive("TTT_PlayMusic", function()
		local song_url = net.ReadTable()
		if not enabled then return end

		songStartTime = CurTime()
		songDuration = 180
		local panelShowTime = CurTime()

		sound.PlayURL(song_url[1], "", function(retValue)
			soundObject = retValue

			if IsValid(soundObject) then
				if not playUnFocused and not system.HasFocus() then
					soundObject:SetVolume(0)
				else
					soundObject:SetVolume(volume)
				end

				soundObject:Play()

				timer.Simple(0.1, function()
					if not IsValid(soundObject) then return end

					local roundsLeft = GetGlobalInt("ttt_rounds_left", 6)
					local postRoundTime = GetConVar("ttt_posttime_seconds"):GetInt() or 30
					local actualSongLength = soundObject:GetLength() or 180

					songDuration = (roundsLeft <= 0) and actualSongLength or postRoundTime
				end)
			end
		end)

		surface.SetFont("Trebuchet24")
		sEndSongText = "♫ " .. song_url[2]
		iTextW, iTextH = surface.GetTextSize(sEndSongText)
		iEoRSongBoxX = ScrW() / 2 - iTextW / 2
		iEoRSongBoxY = ScrH() * 0.035

		hook.Add("HUDPaint", "gmcore.EoRSongPanel", function()
			local fadeInTime = 0.5
			local timeSinceShow = CurTime() - panelShowTime
			local fadeInAlpha = math.Clamp(timeSinceShow / fadeInTime, 0, 1) * 255

			local timeElapsed = CurTime() - songStartTime
			local progress = math.Clamp(timeElapsed / songDuration, 0, 1)
			local remainingWidth = math.max(0, (iTextW + 16) * (1 - progress))

			surface.SetDrawColor(FRAME_BACKGROUND_COLOR.r, FRAME_BACKGROUND_COLOR.g, FRAME_BACKGROUND_COLOR.b, fadeInAlpha * 0.94)
			surface.DrawRect(iEoRSongBoxX, iEoRSongBoxY, iTextW + 16, iTextH + 16)

			surface.SetDrawColor(COMMUNITY_PRIMARY_COLOR.r, COMMUNITY_PRIMARY_COLOR.g, COMMUNITY_PRIMARY_COLOR.b, fadeInAlpha)
			surface.DrawRect(iEoRSongBoxX, iEoRSongBoxY, remainingWidth, 6)

			surface.SetFont("Trebuchet24")
			surface.SetTextColor(255, 255, 255, fadeInAlpha)
			surface.SetTextPos(iEoRSongBoxX + 8, iEoRSongBoxY + 10)
			surface.DrawText(sEndSongText)
		end)
	end)

	hook.Add("TTTPrepareRound", "StopSounds", function()
		lerpSoundClose()
	end)

	hook.Add("TTTSettingsTabs", "TTT_EndRoundMusicSettings", function(dtabs)
		local padding = dtabs:GetPadding() * 2
		local dsettings = vgui.Create("DPanelList", dtabs)
		dsettings:StretchToParent(0, 0, padding, 0)
		dsettings:EnableVerticalScrollbar(true)
		dsettings:SetPadding(10)
		dsettings:SetSpacing(15)

		-- Music Settings Section
		local dplay = vgui.Create("DForm", dsettings)
		dplay:SetLabel("Music Settings")

		local enabledCheckbox = dplay:CheckBox("Enable End of Round Music", "gmcore_music_enabled")
		enabledCheckbox:SetValue(enabled)

		local altTabCheckbox = dplay:CheckBox("Play When Alt+Tabbed", "gmcore_music_alttab")
		altTabCheckbox:SetValue(playUnFocused)
		altTabCheckbox:SetEnabled(enabled)

		local volumeSlider = dplay:NumSlider("Volume", "gmcore_music_volume", 0, 1, 2)
		volumeSlider:SetValue(volume)
		volumeSlider:SetEnabled(enabled)

		local stopButton = dplay:Button("Stop Currently Playing Music")
		stopButton:SetEnabled(enabled)
		stopButton.DoClick = function()
			lerpSoundClose()
		end

		-- Update enabled state when checkbox changes
		enabledCheckbox.OnChange = function(self, val)
			local isEnabled = tobool(val)
			altTabCheckbox:SetEnabled(isEnabled)
			volumeSlider:SetEnabled(isEnabled)
			stopButton:SetEnabled(isEnabled)
		end

		dsettings:AddItem(dplay)

		-- Chat Settings Section
		local dChatSettings = vgui.Create("DForm", dsettings)
		dChatSettings:SetLabel("Chat Settings")
		dChatSettings:NumSlider("Announcment Delay (Seconds)", "gmcore_chatannouncement_interval", 25, 120, 0):SetValue(GetConVar("gmcore_chatannouncement_interval"):GetFloat())
		dsettings:AddItem(dChatSettings)

		-- Misc Settings Section
		local dPointMiscSettings = vgui.Create("DForm", dsettings)
		dPointMiscSettings:SetLabel("Misc. Settings")
		dsettings:AddItem(dPointMiscSettings)

		dtabs:AddSheet("Extra Settings", dsettings, "icon16/wrench_orange.png", false, false, "General settings")
	end)

	hook.Add("PostCleanupMap", "gmcore.PostCleanUpSound", function()
		if not soundObject or not IsValid(soundObject) or soundObject == nil then return end
		if not GetConVar("gmcore_music_alttab"):GetBool() and not system.HasFocus() then return end

		if soundObject:GetState() == GMOD_CHANNEL_STOPPED or soundObject:GetState() == GMOD_CHANNEL_PAUSED then
			soundObject:Play()
		end
	end)
end
