
AddCSLuaFile("cl_funrounds_alert.lua")
AddCSLuaFile("cl_funrounds_radar.lua")

include("sv_funrounds_radar.lua")
include("sv_funrounds_role_reveal.lua")

util.AddNetworkString("gmcore.FunRounds.ActivateFunRound")
util.AddNetworkString("gmcore.FunRounds.SendWinners")

---@type boolean
gmcore.FunRounds.FunRoundThisMap = false
---@type string
gmcore.FunRounds.ChosenFunRound = ""
---@type boolean
gmcore.FunRounds.ActiveRound = false -- Is the current round an active fun round?
---@type boolean
gmcore.FunRounds.DecrementedCD = false
---@type boolean
gmcore.FunRounds.FunRoundULXQueued = false -- If true, will force FR even if < 8 plys
---@type number
gmcore.FunRounds.RoundToActivate = gmcore.FunRounds.RoundToActivate or 0

---Creates a file that holds a number representing the amount of maps left until a fun
---round will be dealt, if it doesn't already exist.
local function initializeFunRoundCD()
	if !file.Exists("gmcore/", "DATA") then
		file.CreateDir("gmcore")
	end

	if !file.Exists("gmcore/funround_countdown.txt", "DATA") then
		file.Write("gmcore/funround_countdown.txt", tostring(math.random(gmcore.FunRounds.Config.mapIntervalMin, gmcore.FunRounds.Config.mapIntervalMax)))
	end
end

---Update the countdown number within the funround_countdown.txt file.
---@param countdown number Current funround countdown value to decrement
---@return number countdown The possibly decremented countdown value
local function updateFRCountdown(countdown)
	if !gmcore.FunRounds.DecrementedCD then
		countdown = countdown - 1
		gmcore.FunRounds.DecrementedCD = true

		return countdown
	end

	return countdown
end

---Determine if a fun round should occur.
---@return boolean shouldStart True if the countdown has reached zero and a fun round should occur
local function checkFunRoundFile()
	initializeFunRoundCD() -- Make sure files exist.

	local curFunRoundCD = tonumber(file.Read("gmcore/funround_countdown.txt", "DATA"))

	if curFunRoundCD > 0 then
		curFunRoundCD = updateFRCountdown(curFunRoundCD)
		file.Write("gmcore/funround_countdown.txt", tostring(curFunRoundCD))

		return false
	end

	if curFunRoundCD == 0 then
		file.Write("gmcore/funround_countdown.txt", tostring(math.random(gmcore.FunRounds.Config.mapIntervalMin, gmcore.FunRounds.Config.mapIntervalMax))) -- Reset the timer.

		return true
	end
end

---Forces the fun round countdown to trigger on the next map.
local function delayFRToNextMap()
	initializeFunRoundCD() -- Make sure files exist.
	file.Write("gmcore/funround_countdown.txt", 0) -- Delays FR to next map.
end

---Checks percentage/override settings to decide if a fun round should trigger this map.
local function checkFunRoundPerc()
	if gmcore.FunRounds.Config.bOverrideForDebug then
		gmcore.FunRounds.FunRoundThisMap = true
		gmcore.FunRounds.RoundToActivate = 1
		gmcore.FunRounds.ChosenFunRound = gmcore.FunRounds.Config.sOverrideRound

		return
	end

	if checkFunRoundFile() then
		gmcore.FunRounds.FunRoundThisMap = true
		gmcore.FunRounds.RoundToActivate = math.random(1, 4) -- 0
		gmcore.FunRounds.ChosenFunRound = table.Random(gmcore.FunRounds.Active)
	end
end

initializeFunRoundCD()

hook.Add("TTTPrepareRound", "gmcore.FunRounds.RoundPrepareFunRound", function()
	local iRoundNum = GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left", 6) -- Determine what round # we are on, not how many rounds are left

	if gmcore.FunRounds.Config.bOverrideForDebug then
		gmcore.FunRounds.FunRoundThisMap = true
		gmcore.FunRounds.RoundToActivate = iRoundNum
		gmcore.FunRounds.ChosenFunRound = gmcore.FunRounds.Config.sOverrideRound
	end

	if !gmcore.FunRounds.FunRoundThisMap then return end
	if gmcore.FunRounds.RoundToActivate != iRoundNum then return end

	if #player.GetAll() < 8 and !gmcore.FunRounds.Config.bOverrideForDebug and !gmcore.FunRounds.FunRoundULXQueued then
		delayFRToNextMap()

		return
	end

	local tFunRound = gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound]
	tFunRound:Prepare()

	net.Start("gmcore.FunRounds.ActivateFunRound")
	net.WriteString(gmcore.FunRounds.ChosenFunRound)
	net.Broadcast()

	gmcore.FunRounds.ActiveRound = true
end)

hook.Add("TTTBeginRound", "gmcore.FunRounds.BeginRound", function()
	if !gmcore.FunRounds.ActiveRound then return end

	-- if gmcore.FunRounds.ActiveRound then
	gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound]:Begin()
	-- end

	if gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound].bRadarEnabled then
		timer.Create("gmcore.FunRounds.RadarScan", 3, 0, function()
			if !gmcore.FunRounds.ActiveRound then return end

			local tFunRound = gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound]

			local aliveCount = 0

			for _, v in ipairs(player.GetAll()) do
				if v:IsActive() then
					aliveCount = aliveCount + 1
				end
			end

			if tFunRound and isfunction(tFunRound.RadarAutoScan) then
				tFunRound:RadarAutoScan(aliveCount)

				return
			end

			if aliveCount <= 6 and gmcore.FunRounds.ChosenFunRound != "Infected" then
				for k, v in pairs(player.GetAll()) do
					if IsValid(v) then
						v:ConCommand("gmcore_funrounds_radar_scan")
					end
				end
			elseif gmcore.FunRounds.ChosenFunRound == "Infected" and infectedTimeLeft() < 40 then
				for k, v in pairs(player.GetAll()) do
					if IsValid(v) and v:GetRole() == ROLE_TRAITOR then
						v:ConCommand("gmcore_funrounds_radar_scan")
					end
				end
			end
		end)
	end

	if gmcore.FunRounds.StartRoleRevealTimer then
		gmcore.FunRounds:StartRoleRevealTimer()
	end
end)

hook.Add("TTTEndRound", "gmcore.FunRounds.RoundEndFunRounds", function()
	local iRoundNum = GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left", 6) -- Determine what round # we are on, not how many rounds are left

	if !gmcore.FunRounds.FunRoundThisMap or !gmcore.FunRounds.ActiveRound then return end
	if gmcore.FunRounds.RoundToActivate != iRoundNum - 1 then return end

	local tFunRound = gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound]
	tFunRound:End()

	if gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound].bRadarEnabled then
		timer.Remove("gmcore.FunRounds.RadarScan")
	end

	if gmcore.FunRounds.StopRoleRevealTimer then
		gmcore.FunRounds:StopRoleRevealTimer()
	end

	timer.Simple(0.1, function()
		gmcore.FunRounds.ActiveRound = false -- slight delay just to make sure end round stuff know it was a fun round before we remove tag
	end)
end)

hook.Add("TTTCheckForWin", "gmcore.FunRounds.CheckWin", function()
	return hook.Call("gmcore.FunRounds.OverrideWin", GAMEMODE)
end)

hook.Add("PlayerInitialSpawn", "gmcore.FunRounds.SendFunRoundSpawn", function(ply)
	if !gmcore.FunRounds.ActiveRound then return end

	net.Start("gmcore.FunRounds.ActivateFunRound")
	net.WriteString(gmcore.FunRounds.ChosenFunRound)
	net.Send(ply)
end)

---Multiple TTT function overrides for fun rounds
---TODO: Improve ApplyScore so instead of overriding the GM func, we add a hook to the func in GM code
---
---SelectRoles: Forces everyone to become a certain role
---
---CheckForWin: Will not allow round to end until condition is met, defined in the fun round code in its EVENT:OverrideWin
---
---ApplyScore: Prevetns score from being affected during funrounds
local function OverrideTTTStuff()
	local fOldSelectRoles = SelectRoles
	local fOldCheckForWin = CheckForWin
	local fOldApplyScore = SCORE and SCORE.ApplyEventLogScores

	if fOldSelectRoles then
		function SelectRoles()
			local bOverrideRoles = hook.Call("gmcore.FunRounds.OverrideRoles", GAMEMODE)

			if !bOverrideRoles then
				fOldSelectRoles()
			end
		end
	end

	if fOldCheckForWin then
		-- CheckForWin is called every second in a timer by the gamemode, not triggered by any in-game events like deaths
		function CheckForWin()
			return hook.Call("gmcore.FunRounds.OverrideWin", GAMEMODE) or fOldCheckForWin() -- Whether to end or not is computed in funround EVENT function
		end
	end

	if fOldApplyScore then
		function SCORE:ApplyEventLogScores(...)
			if gmcore.FunRounds.ActiveRound then return end

			return fOldApplyScore(self, ...)
		end
	end
end

-- TTT Events overrides normal gameplay so we want to be able to COMPLETELY override behavior
-- of some gameplay things (eg. selectroles). That's why we use the timer trick to make pretty sure
-- that we're the "topmost" hook
hook.Add("InitPostEntity", "gmcore.FunRounds.DirtyHooks", function()
	timer.Simple(5, OverrideTTTStuff)
end)

if gmcore.FunRounds.Config.bCheckOnMapStart then
	checkFunRoundPerc()
else
	local bAlreadyFunRound = false -- Set to true if a fun round has already happened for current map

	hook.Add("TTTEndRound", "gmcore.FunRounds.RollFunRoundChance", function()
		if bAlreadyFunRound then return end

		if checkFunRoundFile() then
			gmcore.FunRounds.FunRoundThisMap = true
			gmcore.FunRounds.RoundToActivate = GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left", 6) + 1 -- Cur round number + 1
			gmcore.FunRounds.ChosenFunRound = table.Random(gmcore.FunRounds.Active)
			bAlreadyFunRound = true
		end
	end)
end

timer.Simple(1, function()
	local plymeta = FindMetaTable( "Player" )
	if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end

	-- Forced specs and latejoin specs should not get points
	function plymeta:ShouldScore()
		if self:GetForceSpec() then
			return false
		elseif self:IsSpec() and self:Alive() then
			return false
		elseif gmcore.FunRounds.ActiveRound then
			return false
		else
			return true
		end
	end
end)
