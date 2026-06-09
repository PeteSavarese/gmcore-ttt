function Damagelog:DiscordMessage() end -- Remove if discord is added

AddCSLuaFile(Damagelog.ModulePath .. "shared/defines.lua")
AddCSLuaFile(Damagelog.ModulePath .. "config/config.lua")
AddCSLuaFile(Damagelog.ModulePath .. "shared/lang.lua")
AddCSLuaFile(Damagelog.ModulePath .. "shared/von.lua")
AddCSLuaFile(Damagelog.ModulePath .. "shared/notify.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/info_label.lua")
AddCSLuaFile(Damagelog.ModulePath .. "shared/sync.lua")
AddCSLuaFile(Damagelog.ModulePath .. "shared/events.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/weapon_names.lua")
AddCSLuaFile(Damagelog.ModulePath .. "shared/privileges.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/tabs/damagetab.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/tabs/rdm_manager.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/tabs/shoots.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/tabs/old_logs.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/tabs/chat_logs.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/colors.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/filters.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/drawcircle.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/listview.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/recording.lua")
AddCSLuaFile(Damagelog.ModulePath .. "client/settings.lua")
include(Damagelog.ModulePath .. "shared/defines.lua")
include(Damagelog.ModulePath .. "config/config.lua")
include(Damagelog.ModulePath .. "config/mysqloo.lua")
include(Damagelog.ModulePath .. "shared/von.lua")
--Grab the configs as soon as possible since other code depends on it.
Damagelog:loadMySQLConfig()

include(Damagelog.ModulePath .. "server/sqlite.lua")
include(Damagelog.ModulePath .. "shared/lang.lua")
include(Damagelog.ModulePath .. "server/oldlogs.lua")
include(Damagelog.ModulePath .. "shared/notify.lua")
include(Damagelog.ModulePath .. "shared/sync.lua")
include(Damagelog.ModulePath .. "shared/events.lua")
include(Damagelog.ModulePath .. "shared/privileges.lua")
include(Damagelog.ModulePath .. "server/damageinfos.lua")
include(Damagelog.ModulePath .. "server/recording.lua")
-- include(Damagelog.ModulePath .. "server/discord.lua")
include(Damagelog.ModulePath .. "server/chat_logs.lua")

-- Building error reporting
-- Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "connection error")
---@param file string Source file path where the error occurred
---@param line number Line number in the source file
---@param strg string Error message describing the issue
function Damagelog:Error(file, line, strg)
	print("Damagelogs: ERROR - " .. file .. " (" .. line .. ") - " .. strg)
end

if Damagelog.RDM_Manager_Enabled then
	AddCSLuaFile(Damagelog.ModulePath .. "client/rdm_manager.lua")
	AddCSLuaFile(Damagelog.ModulePath .. "client/chat.lua")
	AddCSLuaFile(Damagelog.ModulePath .. "shared/rdm_manager.lua")
	AddCSLuaFile(Damagelog.ModulePath .. "shared/chat.lua")

	include(Damagelog.ModulePath .. "server/rdm_manager.lua")
	include(Damagelog.ModulePath .. "server/chat.lua")
	include(Damagelog.ModulePath .. "shared/rdm_manager.lua")
	include(Damagelog.ModulePath .. "shared/chat.lua")
end

-- Including Net Messages
util.AddNetworkString("DL_AskDamagelog")
util.AddNetworkString("DL_SendDamagelog")
util.AddNetworkString("DL_RefreshDamagelog")
util.AddNetworkString("DL_InformSuperAdmins")
util.AddNetworkString("DL_Ded")
util.AddNetworkString("DL_SendLang")
util.AddNetworkString("DL_SendConfig")
Damagelog.DamageTable = Damagelog.DamageTable or {}
Damagelog.OldTables = Damagelog.OldTables or {}
Damagelog.ShootTables = Damagelog.ShootTables or {}
Damagelog.Roles = Damagelog.Roles or {}
Damagelog.SceneRounds = Damagelog.SceneRounds or {}

net.Receive("DL_SendLang", function(_, ply)
	ply.DMGLogLang = net.ReadString()
end)

local Player = FindMetaTable("Player")

---@return number id The player's damage log role entry ID, or -1 if unset
function Player:GetDamagelogID()
	return self.DamagelogID or -1
end

---@param id number Damage log role entry ID to assign to the player
function Player:SetDamagelogID(id)
	self.DamagelogID = id
end

---@param joinedAfterRoundStart? boolean
function Player:AddToDamagelogRoles(joinedAfterRoundStart)
	local id = table.insert(Damagelog.Roles[#Damagelog.Roles], {
		role = (joinedAfterRoundStart and DAMAGELOG_ROLE_JOINAFTERROUNDSTART)
			or (self:IsSpec() and DAMAGELOG_ROLE_SPECTATOR)
			or self:GetRole(),
		steamid64 = self:SteamID64(),
		nick = self:Nick()
	})

	self:SetDamagelogID(id)
end

---@return Player|nil pusher The player who pushed this player within the last 4 seconds, or nil
function Player:GetPlayerThatRecentlyPushedMe()
	local pushInfo = self.was_pushed
	if pushInfo == nil then return nil end

	-- player.was_pushed is never reset. We must always check the time on the push event.
	-- Copied from TTT: Only consider pushes in the last 4 seconds
	local pushTime = math.max(pushInfo.t or 0, pushInfo.hurt or 0)
	if pushTime < CurTime() - 4 then return nil end

	return pushInfo.att
end


function Damagelog:TTTBeginRound()
	self.Time = 0

	if not timer.Exists("Damagelog_Timer") then
		timer.Create("Damagelog_Timer", 1, 0, function()
			self.Time = self.Time + 1
		end)
	end

	if IsValid(self:GetSyncEnt()) then
		local rounds = self:GetSyncEnt():GetPlayedRounds()
		self:GetSyncEnt():SetPlayedRounds(rounds + 1)

		if self.add_old then
			self.OldTables[rounds] = table.Copy(self.DamageTable)
		else
			self.add_old = true
		end

		self.ShootTables[rounds + 1] = {}
		self.Roles[rounds + 1] = {}

		for _, v in player.Iterator() do
			v:AddToDamagelogRoles(false)
		end

		self.CurrentRound = rounds + 1
	end

	table.Empty(self.DamageTable)
end

hook.Add("TTTBeginRound", "TTTBeginRound_Damagelog", function()
	Damagelog:TTTBeginRound()
end)

hook.Add("PlayerInitialSpawn", "PlayerInitialSpawn_Damagelog", function(ply)
	if GetRoundState() == ROUND_ACTIVE then
		local steamid64 = ply:SteamID64()
		local found = false
		if not Damagelog.Roles then return end

		for k, v in pairs(Damagelog.Roles[#Damagelog.Roles]) do
			if v.steamid64 == steamid64 then
				found = true
				ply:SetDamagelogID(k)
				break
			end
		end

		if not found then
			ply:AddToDamagelogRoles(true)
		end
	end
end)

local dmgStrings = {
	[DMG_BLAST] = "DMG_BLAST",
	[DMG_DIRECT] = "DMG_BURN",
	[DMG_BURN] = "DMG_BURN",
	[DMG_CRUSH] = "DMG_CRUSH",
	[DMG_FALL] = "DMG_CRUSH",
	[DMG_SLASH] = "DMG_SLASH",
	[DMG_CLUB] = "DMG_CLUB",
	[DMG_SHOCK] = "DMG_SHOCK",
	[DMG_ENERGYBEAM] = "DMG_ENERGYBEAM",
	[DMG_SONIC] = "DMG_SONIC",
	[DMG_PHYSGUN] = "DMG_PHYSGUN",
}

-- rip from TTT
-- this one will return a string
---@param dmg CTakeDamageInfo Damage info to extract the weapon class from
---@return string weaponName
function Damagelog:WeaponFromDmg(dmg)
	local inf = dmg:GetInflictor()
	local wep = nil
	local isWorldDamage = inf ~= nil and inf.IsWorld and inf:IsWorld()

	if IsValid(inf) or isWorldDamage then
		local damageType = dmg:GetDamageType()
		if inf:IsWeapon() or inf.Projectile then
			wep = inf
		elseif dmgStrings[damageType] then
			wep = dmgStrings[damageType]
		elseif inf:IsPlayer() then
			wep = inf:GetActiveWeapon()

			if not IsValid(wep) then
				wep = IsValid(inf.dying_wep) and inf.dying_wep
			end
		end
	end

	if not isstring(wep) then
		return IsValid(wep) and wep:GetClass()
	else
		return wep
	end
end

---@param ply Player Player requesting the damage log
---@param round number Round number to send logs for (-1 for previous map)
function Damagelog:SendDamagelog(ply, round)
	if self.MySQL_Error and not ply.DL_MySQL_Error then
		Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "mysql connection error")
		ply.DL_MySQL_Error = true
	end

	local damage_send = {}
	local roles = self.Roles[round]
	local current = false

	if round == -1 then
		if not self.last_round_map then
			return
		end

		if not Damagelog.PreviousMap then
			if Damagelog.Use_MySQL then
				local query = self.database:query("SELECT damagelog FROM damagelog_oldlogs_v3 WHERE date = " .. self.last_round_map .. ";")

				query.onSuccess = function(q)
					local data = q:getData()

					if data and data[1] then
						local encoded = data[1]["damagelog"]
						local decoded = util.JSONToTable(encoded)

						if not decoded then
							decoded = {
								Roles = {},
								ShootTables = {},
								DamageTable = {}
							}
						end

						self:TransferLogs(decoded.DamageTable, ply, round, decoded.Roles)
						Damagelog.PreviousMap = decoded
					end
				end

				query:start()
			else
				local query = Damagelog.SQLiteDatabase.QueryValue("SELECT damagelog FROM damagelog_oldlogs_v3 WHERE date = " .. self.last_round_map)

				if not query then
					return
				end

				local decoded = util.JSONToTable(query)

				if not decoded then
					decoded = {
						Roles = {},
						ShootTables = {},
						DamageTable = {}
					}
				end

				self:TransferLogs(decoded.DamageTable, ply, round, decoded.Roles)
				Damagelog.PreviousMap = decoded
			end
		else
			self:TransferLogs(Damagelog.PreviousMap.DamageTable, ply, round, Damagelog.PreviousMap.Roles)
		end
	else
		if round == self:GetSyncEnt():GetPlayedRounds() then
			if not ply:CanUseDamagelog() then
				return
			end

			damage_send = self.DamageTable
			current = true
		else
			damage_send = self.OldTables[round]
		end

		self:TransferLogs(damage_send, ply, round, roles, current)
	end
end

---@param damage_send table Compiled damage log entries to transmit
---@param ply Player Recipient player
---@param round number Round number the logs belong to
---@param roles table Role assignments for the round
---@param current boolean Whether the logs are from the currently active round
function Damagelog:TransferLogs(damage_send, ply, round, roles, current)
	local count = #damage_send
	net.Start("DL_SendDamagelog")
	net.WriteTable(roles or {})
	net.WriteUInt(count, 32)

	for _, v in ipairs(damage_send) do
		net.WriteTable(v)
	end

	net.Send(ply)

	if current and ply:IsActive() then
		net.Start("DL_InformSuperAdmins")
		net.WriteString(ply:Nick())

		if self.AbuseMessageMode == 1 then
			net.Send(player.GetHumans())
		else
			local superadmins = {}

			for _, v in ipairs(player.GetHumans()) do
				if v:IsSuperAdmin() then
					table.insert(superadmins, v)
				end
			end

			net.Send(superadmins)
		end
	end
end

net.Receive("DL_AskDamagelog", function(_, ply)
	local roundnumber = net.ReadInt(32)

	if roundnumber and roundnumber > -2 then
		Damagelog:SendDamagelog(ply, roundnumber)
	else
		Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "Roundnumber invalid or negative")
	end -- Because -1 is the last round from previous map
end)

hook.Add("PlayerDeath", "Damagelog_PlayerDeathLastLogs", function(ply)
	if GetRoundState() ~= ROUND_ACTIVE then return end
	if gmcore.FunRounds.ActiveRound and gmcore.FunRounds.DLogs_disabled[gmcore.FunRounds.ChosenFunRound] then return end

	local found_dmg = {}
	local count = #Damagelog.DamageTable

	for i = count, 1, -1 do
		local line = Damagelog.DamageTable[i]
		if not Damagelog.Time or line.time < Damagelog.Time - 10 then break end
		table.insert(found_dmg, line)
	end

	ply.DeathDmgLog = {
		logs = table.Reverse(found_dmg),
		roles = Damagelog.Roles[#Damagelog.Roles]
	}
end)
