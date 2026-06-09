include("cl_funrounds_alert.lua")
include("cl_funrounds_radar.lua")

---@type boolean
gmcore.FunRounds.ActiveRound = false -- Is the current round an active fun round?
---@type string
gmcore.FunRounds.ChosenFunRound = ""

---Receives activation message for a fun round and prepares client state.
local function receiveFunRound()
	local sFunRoundChosen = net.ReadString()

	if !gmcore.FunRounds.RegisteredFunRounds[sFunRoundChosen] then
		error("[GMCore Fun Round] Attempted to set active round \"" .. sFunRoundChosen .. "\" which doesn't exist in on clientside registered fun rounds.")
	end

	gmcore.FunRounds.ActiveRound = true
	gmcore.FunRounds.ChosenFunRound = sFunRoundChosen
	gmcore.FunRounds.RegisteredFunRounds[sFunRoundChosen]:Prepare()
	gmcore.FunRounds:DrawActiveRoundInfo()
end

net.Receive("gmcore.FunRounds.ActivateFunRound", receiveFunRound)

---@type function|nil
local fOldReportView
hook.Add("TTTBeginRound", "gmcore.FunRounds.BeginRound", function()
	-- Override the ReportEvents func, so when we display winners the Round Report doesn't block
	if CLSCORE.ReportEvents ~= nil and !isfunction(fOldReportView) then
		fOldReportView = CLSCORE.ReportEvents
	end

	if gmcore.FunRounds.ActiveRound then
		gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound]:Begin()
		CLSCORE.ReportEvents = function() return end

		if gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound].bRadarEnabled then
			hook.Add("HUDPaint", "gmcore.FunRounds.FunRoundRadar", function()
				gmcore.FunRounds:DrawRadarTargets()
			end)
		end
	end
end)

hook.Add("TTTEndRound", "gmcore.FunRounds.RemoveScoreReport", function()
	if gmcore.FunRounds.ActiveRound and fOldReportView ~= nil then
		CLSCORE.ReportEvents = function() return end -- Set function to do nothing

		timer.Simple(1, function()
			CLSCORE.ReportEvents = fOldReportView -- Restore function to orignal state
		end)

		local tFunRound = gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound]
		tFunRound:End()

		if gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound].bRadarEnabled then
			hook.Remove("HUDPaint", "gmcore.FunRounds.FunRoundRadar")
		end

		gmcore.FunRounds.ActiveRound = false -- We are no longer active
	end
end)
