---@class gmcore
---@field PrintStats fun() Print current stats tables to console

if not SERVER then return end

-- Constants
---Entity classes that count as force kills (physics pushes, explosions, etc.)
---@type table<string, boolean>
local FORCE_KILL_ENTITIES = {
	["ttt_physhammer"] = true,
	["func_physbox"] = true,
	["env_explosion"] = true,
	["func_door"] = true
}

---Stat category names tracked per-map session
---@type string[]
local STAT_CATEGORIES = {
	"General Kills",
	"Weapon Kills",
	"Headshots",
	"Weapon Headshots",
	"Prop Kills",
	"Force Kills",
	"Traitor Contribution",
	"Current Round T Score",
	"Current Round I Score",
	"Innocent Contribution",
	"Highest Kills on Innos",
	"Highest Kills on Ts",

	-- Role-based kill tracking
	"Traitor on Traitor Kills",
	"Traitor on Innocent Kills",
	"Traitor on Detective Kills",
	"Innocent on Traitor Kills",
	"Innocent on Innocent Kills",
	"Innocent on Detective Kills",
	"Detective on Traitor Kills",
	"Detective on Innocent Kills",
	"Detective on Detective Kills",

	-- Death tracking
	"Deaths",
	"Suicides",
	"Traitor Deaths",
	"Innocent Deaths",
	"Detective Deaths",

	-- Round tracking
	"Innocent Rounds",
	"Innocent Wins",
	"Innocent Losses",
	"Innocent Rounds Survived",
	"Detective Rounds",
	"Detective Wins",
	"Detective Losses",
	"Detective Rounds Survived",
	"Traitor Rounds",
	"Traitor Wins",
	"Traitor Losses",
	"Traitor Rounds Survived"
}

---@class ServerStats
---@field PlayerList table<string, Player> Active players keyed by SteamID64
---@field RoundRoles? table<string, number> Player roles for current round keyed by SteamID64
local serverStats = {
	PlayerList = {}
}

---Per-category stat storage: category -> steamid64 -> value
---@type table<string, table<string, number>>
local mainStats = {}

-- Initialize stat categories
for _, category in ipairs(STAT_CATEGORIES) do
	mainStats[category] = {}
end

-- Utility functions

---Check if entity is a valid player
---@param ply any Entity to check
---@return boolean isValid True if the entity is valid and is a player
local function isValidPlayer(ply)
	return IsValid(ply) and ply:IsPlayer()
end

---Check if the current round is active and not a fun round
---@return boolean isActive True if the round is active and no fun round is running
local function isRoundActive()
	return GetRoundState() == ROUND_ACTIVE and not gmcore.FunRounds.ActiveRound
end

---Check if a kill is a team kill
---@param victim Player Victim player
---@param attacker Player Attacker player
---@return boolean isTK True if the victim and attacker are on the same team
local function isTeamKill(victim, attacker)
	return victim:IsPlayer() and attacker:IsPlayer() and Damagelog:IsTeamkill(victim:GetRole(), attacker:GetRole())
end

---Extract model filename from a full model path
---@param modelPath? string Full model path
---@return string? name Extracted model name
local function extractModelName(modelPath)
	if not modelPath or type(modelPath) ~= "string" then return modelPath end

	if string.find(modelPath, "model") or string.find(modelPath, "/") then
		local slashIndex = string.find(modelPath, "/[^/]*$")

		if slashIndex then return string.sub(modelPath, slashIndex + 1) end
	end

	return modelPath
end

-- Core stat tracking functions

---Increment or set a player's stat in a category
---@param category string Stat category name
---@param ply Player Player to update
---@param value? number Explicit value to set (increments by 1 if nil)
local function updatePlayerStat(category, ply, value)
	if not mainStats[category] then
		gmcore.print("Error: Invalid stat category - " .. tostring(category))

		return
	end

	local steamId = ply:SteamID64()

	if not mainStats[category][steamId] then
		mainStats[category][steamId] = 0
	end

	if value then
		mainStats[category][steamId] = value
	else
		mainStats[category][steamId] = mainStats[category][steamId] + 1
	end
end

---Increment or set a player's stat for a specific inflictor (weapon/prop)
---@param category string Stat category name
---@param inflictor string Inflictor identifier (weapon class or model path)
---@param ply Player Player to update
---@param value? number Explicit value to set (increments by 1 if nil)
local function updateInflictorStat(category, inflictor, ply, value)
	if not mainStats[category] then
		gmcore.print("Error: Invalid inflictor stat category - " .. tostring(category))

		return
	end

	if not mainStats[category][inflictor] then
		mainStats[category][inflictor] = {}
	end

	local steamId = ply:SteamID64()

	if not mainStats[category][inflictor][steamId] then
		mainStats[category][inflictor][steamId] = 0
	end

	if value then
		mainStats[category][inflictor][steamId] = value
	else
		mainStats[category][inflictor][steamId] = mainStats[category][inflictor][steamId] + 1
	end
end

---Update the high score stats for traitor/innocent contribution per round
local function updateContributionHighScores()
	-- Update highest traitor kills on innocents
	for steamId, score in pairs(mainStats["Current Round T Score"]) do
		local currentHigh = mainStats["Highest Kills on Innos"][steamId] or 0

		if score > currentHigh then
			mainStats["Highest Kills on Innos"][steamId] = score
		end
	end

	-- Update highest innocent kills on traitors
	for steamId, score in pairs(mainStats["Current Round I Score"]) do
		local currentHigh = mainStats["Highest Kills on Ts"][steamId] or 0

		if score > currentHigh then
			mainStats["Highest Kills on Ts"][steamId] = score
		end
	end
end

---Track round win/loss/survival stats for all players based on their role
---@param winType number TTT win type constant (WIN_TRAITOR, WIN_INNOCENT, etc.)
local function trackRoundStats(winType)
	for steamId, role in pairs(serverStats.RoundRoles) do
		local ply = serverStats.PlayerList[steamId]
		if not isValidPlayer(ply) then continue end

		local isAlive = ply:Alive()
		local won = false

		-- Determine if player won based on their role and win condition
		if role == ROLE_TRAITOR then
			won = (winType == WIN_TRAITOR)
			updatePlayerStat("Traitor Rounds", ply)
			if won then
				updatePlayerStat("Traitor Wins", ply)
			else
				updatePlayerStat("Traitor Losses", ply)
			end
			if isAlive then
				updatePlayerStat("Traitor Rounds Survived", ply)
			end
		elseif role == ROLE_DETECTIVE then
			won = (winType == WIN_INNOCENT)
			updatePlayerStat("Detective Rounds", ply)
			if won then
				updatePlayerStat("Detective Wins", ply)
			else
				updatePlayerStat("Detective Losses", ply)
			end
			if isAlive then
				updatePlayerStat("Detective Rounds Survived", ply)
			end
		elseif role == ROLE_INNOCENT then
			won = (winType == WIN_INNOCENT)
			updatePlayerStat("Innocent Rounds", ply)
			if won then
				updatePlayerStat("Innocent Wins", ply)
			else
				updatePlayerStat("Innocent Losses", ply)
			end
			if isAlive then
				updatePlayerStat("Innocent Rounds Survived", ply)
			end
		end
	end
end

---Compile all tracked stats for a player into a flat table for database insertion
---@param steamId string Player's SteamID64
---@return table stats Compiled stats table
local function compilePlayerStats(steamId)
	return {
		kills = mainStats["General Kills"][steamId] or 0,

		-- Role based kill tracking
		traitor_kills_traitor = mainStats["Traitor on Traitor Kills"][steamId] or 0,
		traitor_kills_innocent = mainStats["Traitor on Innocent Kills"][steamId] or 0,
		traitor_kills_detective = mainStats["Traitor on Detective Kills"][steamId] or 0,
		innocent_kills_traitor = mainStats["Innocent on Traitor Kills"][steamId] or 0,
		innocent_kills_innocent = mainStats["Innocent on Innocent Kills"][steamId] or 0,
		innocent_kills_detective = mainStats["Innocent on Detective Kills"][steamId] or 0,
		detective_kills_traitor = mainStats["Detective on Traitor Kills"][steamId] or 0,
		detective_kills_innocent = mainStats["Detective on Innocent Kills"][steamId] or 0,
		detective_kills_detective = mainStats["Detective on Detective Kills"][steamId] or 0,

		-- Death tracking
		deaths = mainStats["Deaths"][steamId] or 0,
		suicides = mainStats["Suicides"][steamId] or 0,
		traitor_deaths = mainStats["Traitor Deaths"][steamId] or 0,
		innocent_deaths = mainStats["Innocent Deaths"][steamId] or 0,
		detective_deaths = mainStats["Detective Deaths"][steamId] or 0,

		-- Round tracking
		innocent_rounds = mainStats["Innocent Rounds"][steamId] or 0,
		innocent_wins = mainStats["Innocent Wins"][steamId] or 0,
		innocent_losses = mainStats["Innocent Losses"][steamId] or 0,
		innocent_rounds_survived = mainStats["Innocent Rounds Survived"][steamId] or 0,
		detective_rounds = mainStats["Detective Rounds"][steamId] or 0,
		detective_wins = mainStats["Detective Wins"][steamId] or 0,
		detective_losses = mainStats["Detective Losses"][steamId] or 0,
		detective_rounds_survived = mainStats["Detective Rounds Survived"][steamId] or 0,
		traitor_rounds = mainStats["Traitor Rounds"][steamId] or 0,
		traitor_wins = mainStats["Detective Wins"][steamId] or 0,
		traitor_losses = mainStats["Traitor Losses"][steamId] or 0,
		traitor_rounds_survived = mainStats["Traitor Rounds Survived"][steamId] or 0,

		-- General kill tracking
		prop_kills = mainStats["Prop Kills"][steamId] or 0,
		headshots = mainStats["Headshots"][steamId] or 0,
		force_kills = mainStats["Force Kills"][steamId] or 0,
		traitor_contribution = mainStats["Traitor Contribution"][steamId] or 0,
		innocent_contribution = mainStats["Innocent Contribution"][steamId] or 0,
		highest_kills_on_innos = mainStats["Highest Kills on Innos"][steamId] or 0,
		highest_kills_on_traitors = mainStats["Highest Kills on Ts"][steamId] or 0
	}
end

---Update weapon kill/headshot stats in player persistent data
---@param steamId string Player's SteamID64
---@param weapon string Weapon class or model name
---@param kills number Number of kills to add
---@param isHeadshot boolean Whether to track as headshot kills
local function updateWeaponPersistentData(steamId, weapon, kills, isHeadshot)
	local ply = serverStats.PlayerList[steamId]
	if not isValidPlayer(ply) or kills <= 0 then return end

	weapon = extractModelName(weapon)

	if type(weapon) ~= "string" then return end

	local dataKey = string.format("gmcore.%s.weaponTracking.%s.kills", gmcore.ServerTag, weapon)

	if isHeadshot then
		dataKey = dataKey .. ".headshots"
	end

	ply:GMCoreGetPData(dataKey, 0, function(currentValue)
		local newValue = currentValue + kills
		ply:GLSetPData(dataKey, newValue, function() end)
	end)
end

---Save all weapon kill and headshot stats to player persistent data
local function saveWeaponStatsToPersistentData()
	-- Regular weapon kills
	for weapon, playerData in pairs(mainStats["Weapon Kills"]) do
		if type(weapon) == "string" then
			for steamId, kills in pairs(playerData) do
				updateWeaponPersistentData(steamId, weapon, kills, false)
			end
		end
	end

	-- Prop kills
	for weapon, playerData in pairs(mainStats["Prop Kills"]) do
		if type(weapon) == "string" and string.find(weapon, "%.mdl") then
			for steamId, kills in pairs(playerData) do
				updateWeaponPersistentData(steamId, weapon, kills, false)
			end
		end
	end

	-- Weapon headshots
	for weapon, playerData in pairs(mainStats["Weapon Headshots"]) do
		if type(weapon) == "string" then
			for steamId, kills in pairs(playerData) do
				updateWeaponPersistentData(steamId, weapon, kills, true)
			end
		end
	end
end

---Save compiled player stats to the players_stats database table
---@param steamId string Player's SteamID64
---@param stats table Compiled stats from compilePlayerStats
local function savePlayerStatsToDatabase(steamId, stats)
	if stats.kills == 0 and stats.deaths == 0 and stats.innocent_rounds == 0 and stats.detective_rounds == 0 and stats.traitor_rounds == 0 then return end

	local query = gmcore.Database:prepare([[
			INSERT INTO players_stats
			(serverid, date, steamid64, minutes, kills, deaths, suicides, traitor_deaths, innocent_deaths, detective_deaths,
			prop_kills, force_kills, headshots,
			traitor_contribution, innocent_contribution, highest_kills_on_innos, highest_kills_on_traitors,
			traitor_kills_traitor, traitor_kills_innocent, traitor_kills_detective,
			innocent_kills_traitor, innocent_kills_innocent, innocent_kills_detective,
			detective_kills_traitor, detective_kills_innocent, detective_kills_detective,
			innocent_rounds, innocent_wins, innocent_losses, innocent_rounds_survived,
			detective_rounds, detective_wins, detective_losses, detective_rounds_survived,
			traitor_rounds, traitor_wins, traitor_losses, traitor_rounds_survived)
			VALUES (?, UTC_DATE(), ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON DUPLICATE KEY UPDATE
					kills = kills + ?,
					deaths = deaths + ?,
					suicides = suicides + ?,
					traitor_deaths = traitor_deaths + ?,
					innocent_deaths = innocent_deaths + ?,
					detective_deaths = detective_deaths + ?,
					prop_kills = prop_kills + ?,
					force_kills = force_kills + ?,
					headshots = headshots + ?,
					traitor_contribution = traitor_contribution + ?,
					innocent_contribution = innocent_contribution + ?,
					highest_kills_on_innos = GREATEST(highest_kills_on_innos, ?),
					highest_kills_on_traitors = GREATEST(highest_kills_on_traitors, ?),
					traitor_kills_traitor = traitor_kills_traitor + ?,
					traitor_kills_innocent = traitor_kills_innocent + ?,
					traitor_kills_detective = traitor_kills_detective + ?,
					innocent_kills_traitor = innocent_kills_traitor + ?,
					innocent_kills_innocent = innocent_kills_innocent + ?,
					innocent_kills_detective = innocent_kills_detective + ?,
					detective_kills_traitor = detective_kills_traitor + ?,
					detective_kills_innocent = detective_kills_innocent + ?,
					detective_kills_detective = detective_kills_detective + ?,
					innocent_rounds = innocent_rounds + ?,
					innocent_wins = innocent_wins + ?,
					innocent_losses = innocent_losses + ?,
					innocent_rounds_survived = innocent_rounds_survived + ?,
					detective_rounds = detective_rounds + ?,
					detective_wins = detective_wins + ?,
					detective_losses = detective_losses + ?,
					detective_rounds_survived = detective_rounds_survived + ?,
					traitor_rounds = traitor_rounds + ?,
					traitor_wins = traitor_wins + ?,
					traitor_losses = traitor_losses + ?,
					traitor_rounds_survived = traitor_rounds_survived + ?
	]])

	function query:onSuccess()
		gmcore.DebugPrint(string.format("[Stats] Updated stats for player %s", steamId))
	end

	function query:onError(err)
		gmcore.print(string.format("[Stats] Database error for player %s: %s", steamId, err))
	end

	-- Insert values
	query:setNumber(1, gmcore.ServerId)
	query:setString(2, steamId)
	query:setNumber(3, stats.kills)
	query:setNumber(4, stats.deaths)
	query:setNumber(5, stats.suicides)
	query:setNumber(6, stats.traitor_deaths)
	query:setNumber(7, stats.innocent_deaths)
	query:setNumber(8, stats.detective_deaths)
	query:setNumber(9, stats.prop_kills)
	query:setNumber(10, stats.force_kills)
	query:setNumber(11, stats.headshots)
	query:setNumber(12, stats.traitor_contribution)
	query:setNumber(13, stats.innocent_contribution)
	query:setNumber(14, stats.highest_kills_on_innos)
	query:setNumber(15, stats.highest_kills_on_traitors)
	query:setNumber(16, stats.traitor_kills_traitor)
	query:setNumber(17, stats.traitor_kills_innocent)
	query:setNumber(18, stats.traitor_kills_detective)
	query:setNumber(19, stats.innocent_kills_traitor)
	query:setNumber(20, stats.innocent_kills_innocent)
	query:setNumber(21, stats.innocent_kills_detective)
	query:setNumber(22, stats.detective_kills_traitor)
	query:setNumber(23, stats.detective_kills_innocent)
	query:setNumber(24, stats.detective_kills_detective)
	query:setNumber(25, stats.innocent_rounds)
	query:setNumber(26, stats.innocent_wins)
	query:setNumber(27, stats.innocent_losses)
	query:setNumber(28, stats.innocent_rounds_survived)
	query:setNumber(29, stats.detective_rounds)
	query:setNumber(30, stats.detective_wins)
	query:setNumber(31, stats.detective_losses)
	query:setNumber(32, stats.detective_rounds_survived)
	query:setNumber(33, stats.traitor_rounds)
	query:setNumber(34, stats.traitor_wins)
	query:setNumber(35, stats.traitor_losses)
	query:setNumber(36, stats.traitor_rounds_survived)

	-- Update values (same order)
	query:setNumber(37, stats.kills)
	query:setNumber(38, stats.deaths)
	query:setNumber(39, stats.suicides)
	query:setNumber(40, stats.traitor_deaths)
	query:setNumber(41, stats.innocent_deaths)
	query:setNumber(42, stats.detective_deaths)
	query:setNumber(43, stats.prop_kills)
	query:setNumber(44, stats.force_kills)
	query:setNumber(45, stats.headshots)
	query:setNumber(46, stats.traitor_contribution)
	query:setNumber(47, stats.innocent_contribution)
	query:setNumber(48, stats.highest_kills_on_innos)
	query:setNumber(49, stats.highest_kills_on_traitors)
	query:setNumber(50, stats.traitor_kills_traitor)
	query:setNumber(51, stats.traitor_kills_innocent)
	query:setNumber(52, stats.traitor_kills_detective)
	query:setNumber(53, stats.innocent_kills_traitor)
	query:setNumber(54, stats.innocent_kills_innocent)
	query:setNumber(55, stats.innocent_kills_detective)
	query:setNumber(56, stats.detective_kills_traitor)
	query:setNumber(57, stats.detective_kills_innocent)
	query:setNumber(58, stats.detective_kills_detective)
	query:setNumber(59, stats.innocent_rounds)
	query:setNumber(60, stats.innocent_wins)
	query:setNumber(61, stats.innocent_losses)
	query:setNumber(62, stats.innocent_rounds_survived)
	query:setNumber(63, stats.detective_rounds)
	query:setNumber(64, stats.detective_wins)
	query:setNumber(65, stats.detective_losses)
	query:setNumber(66, stats.detective_rounds_survived)
	query:setNumber(67, stats.traitor_rounds)
	query:setNumber(68, stats.traitor_wins)
	query:setNumber(69, stats.traitor_losses)
	query:setNumber(70, stats.traitor_rounds_survived)
	query:start()
end

-- Track role kills, prop kills, and deaths
hook.Add("PlayerDeath", "gmcore.Stats.TrackStats", function(victim, inflictor, attacker)
	if not isValidPlayer(victim) then return end
	if not isRoundActive() then return end

	-- Track all deaths
	updatePlayerStat("Deaths", victim)

	-- Track role-based deaths
	local victimRole = victim:GetRole()
	if victimRole == ROLE_TRAITOR then
		updatePlayerStat("Traitor Deaths", victim)
	elseif victimRole == ROLE_INNOCENT then
		updatePlayerStat("Innocent Deaths", victim)
	elseif victimRole == ROLE_DETECTIVE then
		updatePlayerStat("Detective Deaths", victim)
	end

	-- Track suicides (when victim == attacker or no valid attacker)
	if not isValidPlayer(attacker) or victim == attacker then
		updatePlayerStat("Suicides", victim)

		return
	end

	-- Rest of the kill tracking logic (only if there's a valid attacker)
	if not IsValid(inflictor) then return end
	if attacker:GetClass() == "prop_physics" or attacker:GetClass() == "dynamic_prop" then return end

	local attackerRole = attacker:GetRole()

	-- Skip team kills for contribution tracking but still track role-based kills
	local isTeamKillEvent = isTeamKill(victim, attacker)

	updatePlayerStat("General Kills", attacker)

	-- Track headshot
	if victim:LastHitGroup() == HITGROUP_HEAD then
		updatePlayerStat("Headshots", attacker)
	end

	-- Track role-based kills
	local roleKillCategory = ""

	if attackerRole == ROLE_TRAITOR then
		if victimRole == ROLE_TRAITOR then
			roleKillCategory = "Traitor on Traitor Kills"
		elseif victimRole == ROLE_INNOCENT then
			roleKillCategory = "Traitor on Innocent Kills"
		elseif victimRole == ROLE_DETECTIVE then
			roleKillCategory = "Traitor on Detective Kills"
		end
	elseif attackerRole == ROLE_INNOCENT then
		if victimRole == ROLE_TRAITOR then
			roleKillCategory = "Innocent on Traitor Kills"
		elseif victimRole == ROLE_INNOCENT then
			roleKillCategory = "Innocent on Innocent Kills"
		elseif victimRole == ROLE_DETECTIVE then
			roleKillCategory = "Innocent on Detective Kills"
		end
	elseif attackerRole == ROLE_DETECTIVE then
		if victimRole == ROLE_TRAITOR then
			roleKillCategory = "Detective on Traitor Kills"
		elseif victimRole == ROLE_INNOCENT then
			roleKillCategory = "Detective on Innocent Kills"
		elseif victimRole == ROLE_DETECTIVE then
			roleKillCategory = "Detective on Detective Kills"
		end
	end

	-- Update role-based kill stat
	if roleKillCategory ~= "" then
		updatePlayerStat(roleKillCategory, attacker)
	end

	-- Track prop kills
	local inflictorClass = inflictor:GetClass()

	if inflictorClass == "dynamic_prop" or inflictorClass == "prop_physics" then
		updateInflictorStat("Prop Kills", inflictor:GetModel(), attacker)
		updatePlayerStat("Prop Kills", attacker)
	end

	-- Track role-based contributions (only for non-team kills)
	if not isTeamKillEvent then
		if attacker:GetRole() == ROLE_TRAITOR then
			updatePlayerStat("Traitor Contribution", attacker)
			updatePlayerStat("Current Round T Score", attacker)
		else
			updatePlayerStat("Innocent Contribution", attacker)
			updatePlayerStat("Current Round I Score", attacker)
		end
	end
end)

hook.Add("DoPlayerDeath", "gmcore.Stats.TrackWeaponStats", function(victim, attackEntity, damageInfo)
	local success, err = pcall(function()
		if not isRoundActive() or not isValidPlayer(victim) or not IsValid(attackEntity) then return end
		local attacker = damageInfo:GetAttacker()
		if not isValidPlayer(attacker) or victim == attacker or isTeamKill(victim, attacker) then return end
		local weapon = Damagelog:WeaponFromDmg(damageInfo)
		local inflictorClass = damageInfo:GetInflictor():GetClass()

		-- Track weapon kills
		if type(weapon) == "string" and (string.find(weapon, "weapon_") or string.find(weapon, "ttt_")) then
			updateInflictorStat("Weapon Kills", weapon, attacker)

			if victim:LastHitGroup() == HITGROUP_HEAD then
				updateInflictorStat("Weapon Headshots", weapon, attacker)
			end
		elseif damageInfo:GetInflictor().Projectile then
			updateInflictorStat("Weapon Kills", inflictorClass, attacker)
		end

		-- Track TTT entity kills
		if string.find(inflictorClass, "ttt_") and not damageInfo:GetInflictor().Projectile then
			updateInflictorStat("Weapon Kills", inflictorClass, attacker)
		end

		-- Track force kills
		if FORCE_KILL_ENTITIES[inflictorClass] and victim.was_pushed and victim.was_pushed.att then
			updatePlayerStat("Force Kills", victim.was_pushed.att)
			updateInflictorStat("Weapon Kills", inflictorClass, victim.was_pushed.att)
		end

		-- Track goomba stomps and fall damage
		if weapon == "falling or prop damage" then
			if inflictorClass == "player" or (attackEntity:IsPlayer() and inflictorClass ~= "prop_physics") then
				updatePlayerStat("Force Kills", attacker)
				updateInflictorStat("Weapon Kills", "Goomba_Stomp", attackEntity)
			end
		end

		-- Track pushed fall damage
		if not weapon and victim.was_pushed and damageInfo:GetDamageType() == DMG_FALL and victim.was_pushed.att then
			updatePlayerStat("Force Kills", attackEntity)
			updateInflictorStat("Weapon Kills", victim.was_pushed.wep, victim.was_pushed.att)
		end
	end)

	if not success then
		gmcore.print("[Stats] Error in DoPlayerDeath handler: " .. tostring(err))
	end
end)

hook.Add("TTTPrepareRound", "gmcore.Stats.ClearRoundStats", function()
	mainStats["Current Round T Score"] = {}
	mainStats["Current Round I Score"] = {}

	serverStats.RoundRoles = {}
end)

hook.Add("TTTBeginRound", "gmcore.Stats.UpdatePlayerList", function()
	-- Store player roles for this round
	for _, ply in ipairs(player.GetAll()) do
		if isValidPlayer(ply) and not ply:IsBot() and ply:IsAlive() then
			local steamId = ply:SteamID64()
			local role = ply:GetRole()

			if not serverStats.PlayerList[steamId] then
				serverStats.PlayerList[steamId] = ply
			end

			-- Store the role for round tracking
			serverStats.RoundRoles[steamId] = role
		end
	end
end)

hook.Add("TTTEndRound", "gmcore.Stats.SaveStats", function(winType)
	gmcore.DebugPrint("TTTEndRound triggered with winType: " .. tostring(winType))

	local roundsLeft = GetGlobalInt("ttt_rounds_left", 6) - 1
	updateContributionHighScores()

	-- Track round results
	trackRoundStats(winType)

	-- Only save stats on the last round of the map
	if roundsLeft > -1 then return end

	gmcore.DebugPrint("Saving player stats to database...")

	-- Save player stats to database
	for steamId, ply in pairs(serverStats.PlayerList) do
		gmcore.DebugPrint("Saving stats for player: " .. steamId)

		local stats = compilePlayerStats(steamId)
		savePlayerStatsToDatabase(steamId, stats)
	end

	-- Save weapon stats to persistent data
	saveWeaponStatsToPersistentData()
end)

---Print all current stat tables to server console for debugging
function gmcore.PrintStats()
	PrintTable(mainStats)
	PrintTable(serverStats)
end

gmcore.print("[Stats] tracker loaded successfully")
