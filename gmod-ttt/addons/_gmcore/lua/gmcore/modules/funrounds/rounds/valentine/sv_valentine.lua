util.AddNetworkString("sgm.funround.valentine.SendTeams")
util.AddNetworkString("sgm.funround.valentine.SendEnemyTeams")

---@class ValentineEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field SetRandomTeamEnemy fun(self: ValentineEvent)
---@field GetTeamPlys fun(self: ValentineEvent, iTeam: number): Player[]
---@field GetEnemyPlys fun(self: ValentineEvent, iTeam: number): Player[]
---@field OverrideRoles fun(self: ValentineEvent): boolean
---@field PreventWepPickup fun(self: ValentineEvent, ply: Player, wep: Weapon): boolean
---@field PlayerDeath fun(self: ValentineEvent, victim: Player, wep: Weapon, attacker: Player)
---@field EntityTakeDamage fun(self: ValentineEvent, target: Entity, dmginfo: CTakeDamageInfo): boolean

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Valentine"] or {}
---@cast EVENT ValentineEvent
EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale

local DAMAGE_TAKEN_REWARD = 0.25 -- When team shoots their enemy, how much of the damage the inflict will they gain

local teams = {} -- This is filled with members of each team. The index (integer) identifies the team and the value contains player ents of the team
local teamToEnemys = {} -- Index is the team and value is their enemy team. This is filled in EVENT:SetRandomTeamEnemy

--[[
0* Given a table with index of an integer, it will pick a random key in an ordered table
0--]]
local function randomKeyFromTable(tbl)
		local tKeys = {} -- Keys from the table

		for k, _ in pairs(tbl) do
			table.insert(tKeys, k)
		end

		return tKeys[math.random(1, #tKeys)]
end

function EVENT:Prepare()
	m_Begin(self)

	self.KillsThisRound = {} -- For counting how many kills each player has

	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("CanPlayerSuicide", self.PreventSuicide) -- This would screw over their partner and have them die. Prevent minging
	self:AddHook("TTTBeginRound", self.SetupLovers)
	self:AddHook("PlayerHurt", self.PlayerHurt)
	self:AddHook("EntityTakeDamage", self.PreventTeamDamage)
	self:AddHook("PlayerDeath", self.PlayerDeath)
end

-- Make everyone an innocent
function EVENT:OverrideWin()
	if GetConVar("ttt_debug_preventwin"):GetInt() == 1 then return WIN_NONE end -- Allow for debug testing

	local iTeamsAlive = 0

	for teamId, team in ipairs(teams) do
		for _, ply in ipairs(team.players) do
			-- we just need to check if one player is alive
			if IsValid(ply) and ply:Alive() then
				iTeamsAlive = iTeamsAlive + 1

				break; -- break since if one is alive, all are alive
			end
		end
	end

	return iTeamsAlive > 1 and WIN_NONE or WIN_TRAITOR
end

-- Make everyone an innocent
function EVENT:OverrideRoles()
	for _, ply in pairs(self:GetPlayers(true)) do -- Pass true to GetPlayers to shuffle playerlist
		ply:SetRole(ROLE_INNOCENT)
	end

	return true
end

function EVENT:PreventSuicide()
	return false -- No
end

-- When round starts, give each person a random lover.
function EVENT:SetupLovers()
	local availablePlayers = self:GetPlayers() -- This is filled with a list of all alive players

	-- Begin looping through all available players to pair with another player (their lover)
	-- All of the print funcs are for massive debugging. Uncomment them if you need them
	for k, ply in ipairs(availablePlayers) do
		-- print("---START---")
		-- print("Cur Aval Ply", ply:Nick())
		local bIsInTriple = false -- Set to true if the random player we picked == ply.
		local bPlyAlreadyInTeam = false -- In following loop, if our current ply is in a team, we skip to the next ply

		ply:StripWeapon("weapon_zm_carry") -- No magneto stick

		for l, team in ipairs(teams) do
			if table.HasValue(team.players, ply) then
				bPlyAlreadyInTeam = true
				break;
			end
		end

		if bPlyAlreadyInTeam then
			-- print("continue next\n---END---\n")
			continue
		end

		local iRandomTeam -- Set outside of the if check for use when adding player to team table

		-- This is the last player. Well add them to another team to be a team of 3
		if !availablePlayers[k + 1] then
			-- print("last playuer")
			iRandomTeam = math.random(1, #teams)
			bIsInTriple = true
		end

		if !bIsInTriple then
			local bAlreadyFoundRandomPly = false -- If set to true after finding our random ply, the loop for availablePlayers will break and stop looping
			local randomPly

			for l, plyRandom in ipairs(availablePlayers) do
				if plyRandom == ply then continue end -- Dont add us to a team with ourselves

				-- If we already have a team, we need to check if our random player is apart of the team
				if #teams > 0 then
					-- print("checking", plyRandom:Nick())
					local bAlreadyInTeam = false

					for teamId, team in ipairs(teams) do
						if table.HasValue(team.players, plyRandom) then
							bAlreadyInTeam = true
							-- print(plyRandom:Nick(), "already in team " .. teamId)

							break;
						end
					end


					if !bAlreadyInTeam then
						randomPly = plyRandom
						bAlreadyFoundRandomPly = true
						-- print("found ply", randomPly:Nick())
						break; -- No longer need to loop through teams
					else
						continue
					end
				else
					randomPly = availablePlayers[l + 1] -- We dont have teams, just use next person in table
					break; -- No goto statement since we only have one loop here.
				end

				if bAlreadyFoundRandomPly then break; end
			end

			local iOurTeamId = #teams + 1
			-- Insert team index and inside a table of all players in the team and their kills tracker
			teams[iOurTeamId] = {
				players = {ply, randomPly}, --
				iKills = 0
			}

			ply.ValentineTeamId = iOurTeamId
			randomPly.ValentineTeamId = iOurTeamId

			-- print("added", ply:Nick(), "to team with", randomPly:Nick())
		else
			table.insert(teams[iRandomTeam].players, ply)
			ply.ValentineTeamId = iRandomTeam
		end

		-- print("---END---\n")
	end

	PrintTable(teams)

	-- Do I like using net msgs in fun round? No but whatever
	net.Start("sgm.funround.valentine.SendTeams")
	net.WriteTable(teams)
	net.Broadcast()

	-- Set the teams enemy teams
	for teamId, team in ipairs(teams) do
		self:SetRandomTeamEnemy(teamId, team)
	end
end

-- team and teamId argument is the team that will have their enemy team set
function EVENT:SetRandomTeamEnemy(teamId, team)
	local teamCountTargetted = {} -- key is teamId, value is how many times they are targetted

	-- Clear our current target if we already have one
	if teamToEnemys[teamId] then
		teamToEnemys[teamId] = nil
	end

	for _, ply in ipairs(team.players) do
		print("\nBEGIN SETTING NEW ENEMY FOR TEAM", teamId, ply:Nick())
	end

	for teamSearchId, teamSearch in ipairs(teams) do
		if teamSearchId == teamId then continue end -- Dont add ourselves to the list

		local bTeamIsAlive = true -- If false this team has already died. Loop to next team

		for _, ply in ipairs(teamSearch.players) do
			if !ply:Alive() then
				bTeamIsAlive = false
			end
		end

		if !bTeamIsAlive then continue end

		teamCountTargetted[teamSearchId] = 0

		for teamAttacker, teamVictim in pairs(teamToEnemys) do
			if teamVictim == teamSearchId then
				teamCountTargetted[teamSearchId] = teamCountTargetted[teamSearchId] + 1
			end
		end
	end

	local bFoundTeamToAssignTo = false -- Set to true if we dont have to double team a team

	for teamSearchId, iTargetCount in pairs(teamCountTargetted) do
		-- If we can find a team that isnt currently being targetted then assign us to them
		if iTargetCount == 0 then
			print("Assigned", teamId, "to enemy", teamSearchId)
			teamToEnemys[teamId] = teamSearchId

			bFoundTeamToAssignTo = true
			break; -- Already assigned target. Stop running
		end
	end

	-- If false, then welp we gotta have a team doubleteamed
	if !bFoundTeamToAssignTo then
		print("no team found")
		local temp = randomKeyFromTable(teamCountTargetted)
		if temp == nil then print("nil temp random team id") return end

				print("assigned to team", temp)

		teamToEnemys[teamId] = temp
	end

	-- TODO: This is dev testing. Remove this loop or have it integrate into SGMs chat print prefix func
	for _, ply in ipairs(team.players) do
		ply:ChatPrint("New enemy team assigned")
	end

	net.Start("sgm.funround.valentine.SendEnemyTeams")
	net.WriteTable(teamToEnemys)
	net.Send(team.players)
end

-- Handle death of a player. If the one player dies, find their linked lover and have them die as well
function EVENT:PlayerHurt(victim, attacker, iNewHealth, iDmgTaken)
	if victim == attacker then return end
	if !IsValid(attacker) then return end
	if !attacker:IsPlayer() then return end

	local attackerTeamPlys = teams[attacker.ValentineTeamId].players

	for iTeamId, ply in ipairs(attackerTeamPlys) do
		if !IsValid(ply) then continue end
		if !ply:Alive() then continue end

		ply:SetHealth(math.Clamp(attacker:Health() + iDmgTaken * DAMAGE_TAKEN_REWARD, 0, ply:GetMaxHealth()))
	end

	local linkedPlys = teams[victim.ValentineTeamId].players

	for iTeamId, ply in ipairs(linkedPlys) do
		if !IsValid(ply) then continue end

		ply:SetHealth(iNewHealth)

		-- For some reason even if our health drops below 0, the linked player wont die. This is a fix
		if ply:Health() <= 0 then
			ply:Kill()
		end
	end
end

function EVENT:PreventTeamDamage(victim, CDamageInfo)
	local attacker = CDamageInfo:GetAttacker()

	if !IsValid(victim) then return end
	if !victim:IsPlayer() then return end
	if !IsValid(attacker) then return end
	if !attacker:IsPlayer() then return end

	if victim == attacker then return end
	if !victim.ValentineTeamId or !attacker.ValentineTeamId then return end
	if victim.ValentineTeamId == attacker.ValentineTeamId then return CDamageInfo:ScaleDamage(0) end

	-- Now we begin after all our checks
	local iVictimTeamId = victim.ValentineTeamId
	local iAttackerTeamId = attacker.ValentineTeamId
	local iAttackerEnemyTeamId = teamToEnemys[iAttackerTeamId]

	if iAttackerEnemyTeamId != iVictimTeamId then return CDamageInfo:ScaleDamage(0) end
end

function EVENT:PlayerDeath(victim, _, attacker)
	if !IsValid(victim) then return end
	if !IsValid(attacker) then return end
	if victim == attacker then return end
	if !attacker:IsPlayer() then return end

	local iAttackerTeamId = attacker.ValentineTeamId
	teams[iAttackerTeamId].iKills = teams[iAttackerTeamId].iKills + 1

	-- Check if all players on team are dead. If so we must reassign their attacking team to a new team

	for lAttackerTeamId, lVictimTeamId in ipairs(teamToEnemys) do
		if lVictimTeamId == victim.ValentineTeamId then
			attackerTeamId = lAttackerTeamId

			break; -- Weve found our team. No longer need to loop
		end
	end

	local iCountVictimTeamDeaths = 0

	-- Now loop through the team to see if all players are dead
	-- TODO: When a player leaves the server, they dont increment into the iCountVictimTeamDeaths. Get this to work
	for _, ply in ipairs(teams[victim.ValentineTeamId].players) do
		if IsValid(ply) and !ply:Alive()  then
			iCountVictimTeamDeaths = iCountVictimTeamDeaths + 1
		end
	end

	if iCountVictimTeamDeaths == #teams[victim.ValentineTeamId].players then
		-- Remove their enemy team so their enemy team can be queued for targetting in SetRandomTeamEnemy
		teamToEnemys[victim.ValentineTeamId] = 0

		net.Start("sgm.funround.valentine.SendEnemyTeams")
		net.WriteTable(teamToEnemys)
		net.Send(teams[victim.ValentineTeamId].players)

		local teamsAttackingThisTeam = {}

		for attackingTeamId, victimTeamId in pairs(teamToEnemys) do
			if victimTeamId == victim.ValentineTeamId then
				table.insert(teamsAttackingThisTeam, attackingTeamId)
			end
		end

		print("\n---=== victimteamid ===---")
		print(victim.ValentineTeamId)

		print("\n---=== teamToEnemys ===---")
		PrintTable(teamToEnemys)

		print("\n---=== teamsAttackingThisTeam ===---")
		PrintTable(teamsAttackingThisTeam)

		for _, attackingTeamId in pairs(teamsAttackingThisTeam) do
			self:SetRandomTeamEnemy(attackingTeamId, teams[attackingTeamId]) -- Give the teams attacking enemy a new team since everyone is dead.
		end
	end
end

function EVENT:ComputeRewards()
	local iLastTeamStandingTeamId
	local iMostKillsTeamCount, iMostKillsTeamId = 0

	for teamId, team in ipairs(teams) do
		for _, ply in ipairs(team.players) do
			-- we just need to check if one player is alive
			if ply:Alive() then
				iLastTeamStandingTeamId = teamId

				break; -- break since if this team has a player that is alive, this is the only team that won
			end
		end
	end

	for teamId, team in ipairs(teams) do
		if team.iKills > iMostKillsTeamCount then
			iMostKillsTeamCount = team.iKills
			iMostKillsTeamId = teamId
		end
	end

	for _, ply in pairs(teams[iLastTeamStandingTeamId].players) do
		ply:PS_GivePointsBoostable(self.Rewards.iLastStandingTeam)
		rewardMessageToPly("Apart of Last Team Standing!", self.Rewards.iLastStandingTeam, true, ply)
	end

	for _, ply in pairs(teams[iMostKillsTeamId].players) do
		ply:PS_GivePointsBoostable(self.Rewards.iLastStandingTeam)
		rewardMessageToPly("Team with Most Kills!", self.Rewards.iMostKills, true, ply)
	end

	local tToSendWinners = {
		lastTeamStanding = teams[iLastTeamStandingTeamId] or nil,
		teamMostKills = teams[iMostKillsTeamId],
		iMostKillsCount = iMostKillsTeamCount
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

gmcore.FunRounds:RegisterFunRound("Valentine", EVENT)
