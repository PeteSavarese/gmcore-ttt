util.AddNetworkString("gmcore.Deathcard.HandleDeath")
util.AddNetworkString("gmcore.Deathcard.UpdateCardPanelState")

gmcore.Deathcard = {}

---@class DeathcardDmgEntry
---@field dmg number Total damage dealt to the victim
---@field hits number Number of hits landed on the victim
---@field wep Entity Weapon entity used to deal the damage
---@field time number CurTime() of the most recent hit

--[[
	Table structure:
		Key: attacker SteamID64
		Vals:
			[1] Victim SteamID64 that they damaged
				dmg: Damage attacker inflicted
				hits: How many shots attacker hit victim with
]]
---@type table<Entity, table<Entity, DeathcardDmgEntry>>
gmcore.Deathcard.DamageHistory = {}

--[[
	Table structure:
		Key: DNA finder SteamID64
		Vals:
			[1] DNA owner SteamID64
]]
---@type table<string, string[]>
gmcore.Deathcard.DNAHistory = {}

--[[
	Keeps track of when a player has a deathcard active or not. Used exiting the deathcard early

	Key: Player ent
	Value: Bool state of panel
]]
---@type table<Player, boolean>
gmcore.Deathcard.PanelStates = {}

--[[
	Keeps track of damage dealt and hits given when player takes damage

	victim: Player entity who receives the dmg
	dmg: CDamageInfo of the damage inflicted
]]
---@param victim Player Player who received the damage
---@param dmg CTakeDamageInfo Damage information for the hit
function gmcore.Deathcard.HandleEntityDamage(victim, dmg)
	if GetRoundState() ~= ROUND_ACTIVE or ROUND_POST ~= ROUND_POST then return end
	if not victim:IsPlayer() then return end
	if dmg:GetDamage() <= 0 then return end

	local attacker = dmg:GetAttacker()

	gmcore.Deathcard.DamageHistory[attacker] = gmcore.Deathcard.DamageHistory[attacker] or {}
	gmcore.Deathcard.DamageHistory[attacker][victim] = gmcore.Deathcard.DamageHistory[attacker][victim] or {}

	local dmgAmount = math.Round(dmg:GetDamage())
	local newDmg = gmcore.Deathcard.DamageHistory[attacker][victim].dmg and gmcore.Deathcard.DamageHistory[attacker][victim].dmg + dmgAmount or dmgAmount
	local newHits = gmcore.Deathcard.DamageHistory[attacker][victim].hits and gmcore.Deathcard.DamageHistory[attacker][victim].hits + 1 or 1

	gmcore.Deathcard.DamageHistory[attacker][victim] = {
		dmg = newDmg,
		hits = newHits,
		wep = dmg:GetInflictor(),
		time = CurTime()
	}
end

---@param victim Player Player who died
---@param weapon Entity Weapon or inflictor entity used to kill the victim
---@param attacker Player Entity responsible for the kill
function gmcore.Deathcard.HandlePlayerDeath(victim, weapon, attacker)
	if not IsValid(victim) then return end
	if not attacker then return end

	local damageHistory = {}

	if victim ~= attacker and gmcore.Deathcard.DamageHistory[attacker] and gmcore.Deathcard.DamageHistory[attacker][victim] then
		damageHistory.AttackerDmg = gmcore.Deathcard.DamageHistory[attacker][victim]
	else
		damageHistory.AttackerDmg = {}
	end

	if victim ~= attacker and gmcore.Deathcard.DamageHistory[victim] and gmcore.Deathcard.DamageHistory[victim][attacker] then
		damageHistory.VictimDamage = victim ~= attacker and gmcore.Deathcard.DamageHistory[victim][attacker] or {}
	else
		damageHistory.VictimDamage = {}
	end

	damageHistory.DeathPos = victim:GetPos()

	if damageHistory.AttackerDmg.wep and damageHistory.AttackerDmg.wep:IsPlayer() then
		damageHistory.AttackerDmg.wep = damageHistory.AttackerDmg.wep:GetActiveWeapon()
	end

	local dnaFound = false

	if attacker:IsPlayer() and gmcore.Deathcard.DNAHistory[attacker:SteamID64()] and table.HasValue(gmcore.Deathcard.DNAHistory[attacker:SteamID64()], victim:SteamID64()) then
		dnaFound = true
	end

	net.Start("gmcore.Deathcard.HandleDeath")
	net.WriteEntity(attacker)
	net.WriteInt(attacker:IsPlayer() and attacker:GetRole() or 0, 8)
	net.WriteTable(damageHistory)
	net.WriteBool(dnaFound)
	net.Send(victim)

	-- Now clear attack info from attacker
	if not gmcore.Deathcard.DamageHistory[attacker] then return end

	gmcore.Deathcard.DamageHistory[attacker][victim] = nil

	if #gmcore.Deathcard.DamageHistory[attacker] <= 0 then
		gmcore.Deathcard.DamageHistory[attacker] = nil
	end
end

---@param plyFinder Player Player who found the DNA sample
---@param plyOwner Player Player whose DNA was found
---@param ent Entity Entity the DNA sample was collected from
function gmcore.Deathcard.HandleDNAFound(plyFinder, plyOwner, ent)
	if plyOwner:IsActive() and plyOwner:Alive() and plyFinder:GetRole() ~= ROLE_TRAITOR then
		if not gmcore.Deathcard.DNAHistory[plyFinder:SteamID64()] then
			gmcore.Deathcard.DNAHistory[plyFinder:SteamID64()] = {}
		end

		table.insert(gmcore.Deathcard.DNAHistory[plyFinder:SteamID64()], plyOwner:SteamID64())
	end
end

--[[
	Loops through all damage dealt stored in gmcore.Deathcard.DamageHistory and removes damage history > 30 seconds ago
]]
function gmcore.Deathcard:CheckExpiredDamage()
	for plyAttacker, v in pairs(self.DamageHistory) do
		if not IsValid(plyAttacker) then continue end
		if type(v) ~= "table" then continue end

		local dmgHistoryRemoveQueue = {}
		for plyVictim, dmg in pairs(v) do
			if not dmg or not dmg.time then continue end
			if CurTime() - dmg.time > 30 then
				table.insert(dmgHistoryRemoveQueue, plyVictim)
			end
		end

		for _, plyVictim in ipairs(dmgHistoryRemoveQueue) do
			self.DamageHistory[plyAttacker][plyVictim] = nil
		end

		if self.DamageHistory[plyAttacker] and next(self.DamageHistory[plyAttacker]) == nil then
			self.DamageHistory[plyAttacker] = nil
		end
	end
end

--[[
	Client sends the state of their deathcard panel everytime it opens and closes
]]
net.Receive("gmcore.Deathcard.UpdateCardPanelState", function(len, ply)
	gmcore.Deathcard.PanelStates[ply] = net.ReadBool()
end)

timer.Create("gmcore.Deathcard.CheckExpiredDamage", 1, 0, function() gmcore.Deathcard:CheckExpiredDamage() end)

hook.Add("EntityTakeDamage", "gmcore.Deathcard.DamageCounter", gmcore.Deathcard.HandleEntityDamage)
hook.Add("PlayerDeath", "gmcore.Deathcard.PlayerDeath", gmcore.Deathcard.HandlePlayerDeath)
hook.Add("TTTFoundDNA", "gmcore.Deathcard.DNAHistory", gmcore.Deathcard.HandleDNAFound)
hook.Add("TTTBeginRound", "gmcore.Deathcard.CleanupHistory", function()
	gmcore.Deathcard.DamageHistory = {}
	gmcore.Deathcard.DNAHistory = {}
end)
