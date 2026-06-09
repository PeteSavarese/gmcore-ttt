local EVENT = gmcore.FunRounds.RegisteredFunRounds["Barrel Terror"]

surface.CreateFont("gmcore.FunRounds.HalloweenReaperHealth", {
	font = "Biko",
	size = 25,
	weight = 750
})


local m_Prepare = EVENT.Prepare or nil
local m_Begin = EVENT.Begin or nil
local pGrimReaper = nil -- Grim reaper
local bgmStation = nil -- Background music station
local bgmLoopTimer = "gmcore.FunRounds.HalloweenBGM"

function EVENT:Prepare()
	-- Sound Effect by DRAGON-STUDIO
	sound.PlayFile("sound/gmcore/music/grim_round_announce.mp3", "noplay", function(station, errCode, errStr)
			if IsValid(station) then
					station:Play()
			end
	end)

	m_Prepare(self)
end

local function playAmbientMusic()
	sound.PlayFile("sound/gmcore/music/grim_round_background.mp3", "noplay", function(station, errCode, errStr)
		if IsValid(station) then
			station:Play()
			bgmStation = station

			-- Set up timer to replay when finished
			-- I hate this as much as you do, but I am not editing a sound file
			-- with loop points to make it loop
			timer.Create(bgmLoopTimer, station:GetLength(), 1, function()
				if bgmStation and IsValid(bgmStation) then
					bgmStation:Stop()
					bgmStation = nil
				end

				playAmbientMusic()
			end)
		else
			print("Failed to play ambient music:", errCode, errStr)
		end
	end)
end

function EVENT:Begin()
	m_Begin(self)
	playAmbientMusic()

	self:AddHook("HUDPaint", self.HUDPaint)
end

net.Receive("gmcore.FunRounds.HalloweenSendTraitor", function()
	pGrimReaper = net.ReadEntity()

	if pGrimReaper == LocalPlayer() then
		surface.PlaySound("gmcore/halloween/Recording_10.mp4.wav") -- Memez lol
	end
end)

local iScrW, iScrH = ScrW(), ScrH()
local iHealthBarWidth = ScrW() * 0.15
local gradientDown = Material("vgui/gradient_down")
local grainMat = Material("pp/grain") -- built-in grain texture
local iMaxHealthReaper = nil

local function GetPlayers()
	local tPlys = {}

	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and !ply:IsSpec() then
			table.insert(tPlys, ply)
		end
	end

	return tPlys
end

local function drawEffectsToReaper(pGrimReaper)
	-- Dim and grainy effect based on distance to reaper
	local dist = 99999
	if IsValid(pGrimReaper) and IsValid(LocalPlayer()) then
		dist = LocalPlayer():GetPos():Distance(pGrimReaper:GetPos())
	end
	-- Effect parameters
	local maxDist = 1200 -- fully dark/grainy at this distance or less
	local minDist = 350 -- max effect at this distance or less
	local frac = 1 - math.Clamp((dist - minDist) / (maxDist - minDist), 0, 1)

	-- Always a little dark, more as reaper gets close
	local baseDark = 0.03
	local dark = baseDark + frac * 0.23 -- up to 0.3
	local grainStrength = 0.1 + frac * 0.5 -- up to 0.6

	DrawColorModify({
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = -dark,
		["$pp_colour_contrast"] = 1 - frac * 0.15,
		["$pp_colour_colour"] = 1 - frac * 0.25,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0
	})

	-- Grain overlay
	-- surface.SetDrawColor(255,255,255,math.floor(80 + 175 * grainStrength))
	-- surface.SetMaterial(grainMat)
	-- surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end

function EVENT:HUDPaint()
	if !pGrimReaper then return end

	if !iMaxHealthReaper then
		iMaxHealthReaper = #GetPlayers() * 1000
	end

	if pGrimReaper != LocalPlayer() then
		drawEffectsToReaper(pGrimReaper)
	end

	-- Health bar and text
	local iGrimReaperHealthPerc = pGrimReaper:Health() / iMaxHealthReaper

	surface.SetDrawColor(255, 110, 0)
	surface.DrawRect(iScrW / 2 - iHealthBarWidth / 2, 25, iHealthBarWidth, 50)

	surface.SetDrawColor(255, 160, 55)
	surface.SetMaterial(gradientDown)
	surface.DrawTexturedRect(iScrW / 2 - iHealthBarWidth / 2, 25, iHealthBarWidth, 50)

	surface.SetDrawColor(255, 0, 0)
	surface.DrawRect(iScrW / 2 - iHealthBarWidth / 2 + 2, 28, math.Clamp(iHealthBarWidth * iGrimReaperHealthPerc, 2, iHealthBarWidth) - 4, 44)

	surface.SetDrawColor(255, 80, 80)
	surface.SetMaterial(gradientDown)
	surface.DrawTexturedRect(iScrW / 2 - iHealthBarWidth / 2 + 2, 28, math.Clamp(iHealthBarWidth * iGrimReaperHealthPerc, 2, iHealthBarWidth) - 4, 44)

	surface.SetFont("gmcore.FunRounds.HalloweenReaperHealth")
	local sGrimReaperHealth = string.Comma(pGrimReaper:Health()) .. "/" .. string.Comma(iMaxHealthReaper)
	local iTextW, iTextH = surface.GetTextSize(sGrimReaperHealth)
	draw.DrawText(sGrimReaperHealth, "gmcore.FunRounds.HalloweenReaperHealth", ScrW() / 2, 50 - iTextH / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
end

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	local sImageOfTeam = tWinners.lastTeam == "T" and "vgui/ttt/icon_traitor.png" or "vgui/ttt/icon_inno.png"
	local sWinningTeamNick = tWinners.lastTeam == "T" and "Grim Reaper" or "The Innocents"

	-- (2) Create panels for each winner.
	---------------------------------------------------------
	local lastAlive = vgui.Create("GmcoreFunRoundWinner")
	lastAlive:SetWinner({
		text = string.format("Last Team Standing"),
		name = sWinningTeamNick,
		image = sImageOfTeam
	})
	table.insert(winners, lastAlive)
	---------------------------------------------------------

	return winners
end

function EVENT:RemoveWinners()
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end

	if bgmStation and IsValid(bgmStation) then
		bgmStation:Stop()
		bgmStation = nil
	end

	if timer.Exists(bgmLoopTimer) then
		timer.Remove(bgmLoopTimer)
	end
end

gmcore.FunRounds:RegisterFunRound(EVENT.sTitle, EVENT)
