---@class ChristmasCheerEvent : FunRound
---@field RadarAutoScan fun(self: ChristmasCheerEvent, _: any)
---@field OverrideWin fun(self: ChristmasCheerEvent): number
---@field OverrideRoles fun(self: ChristmasCheerEvent): boolean
---@field PlayerDeath fun(self: ChristmasCheerEvent, victim: Player, wep: Weapon, attacker: Player)
---@field PreventWepPickup fun(self: ChristmasCheerEvent, ply: Player, wep: Weapon): boolean
---@field EntityTakeDamage fun(self: ChristmasCheerEvent, target: Entity, dmginfo: CTakeDamageInfo): boolean

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Christmas Cheer"] or {}
---@cast EVENT ChristmasCheerEvent

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil
local m_End = EVENT.End or nil

local sound_christmas = Sound("gmcore/ho_ho_ho_merry_xmas.mp3")
local elf_model = "models/santa_elf/elf.mdl"

---Returns true if Christmas Cheer is currently-active fun round.
---@return boolean isActiveRound True when fun round is active
local function isActive()
	return gmcore and gmcore.FunRounds and gmcore.FunRounds.ActiveRound and gmcore.FunRounds.ChosenFunRound == "Christmas Cheer"
end

---Returns true if player is currently on elf team
---@param ply Player Player to check
---@return boolean isElfPlayer True when player's role is traitor (elf team)
local function isElf(ply)
	return IsValid(ply) and ply:IsPlayer() and ply:GetRole() == ROLE_TRAITOR
end

function EVENT:RadarAutoScan(_)
	-- Always run radar scans for alive players, so both teams can track the other
	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if not ply:IsActive() then continue end
		local r = ply:GetRole()
		if r == ROLE_INNOCENT or r == ROLE_TRAITOR then
			ply:ConCommand("gmcore_funrounds_radar_scan")
		end
	end
end

function EVENT:RadarShouldIncludeTarget(viewer, target)
	-- Each team should only see the other team on radar (elves see innocents, innocents see elves)
	if not IsValid(viewer) or not viewer:IsPlayer() then return true end

	local viewerRole = viewer:GetRole()
	if viewerRole ~= ROLE_INNOCENT and viewerRole ~= ROLE_TRAITOR then
		return true
	end

	if not IsValid(target) or not target:IsPlayer() or not target:IsActive() then
		return false
	end

	local targetRole = target:GetRole()
	if viewerRole == ROLE_INNOCENT then
		return targetRole == ROLE_TRAITOR
	end

	return targetRole == ROLE_INNOCENT
end

function EVENT:GetScaledElfHealth()
	local n = tonumber(self.InitialElfCount) or 1
	n = math.max(1, n)

	local base = tonumber(self.ElfBaseHealth) or 350
	local minH = tonumber(self.ElfMinHealth) or 125

	local perElf = math.floor(base / n)
	return math.Clamp(perElf, minH, base)
end

---Ensures elf has boosted walk speed, while saving original walk speed for later restore
---@param self table Fun round EVENT table (used for config, e.g. ElfWalkSpeed)
---@param ply Player Elf player
local function applyElfWalkSpeed(self, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	self.OriginalWalkSpeeds = self.OriginalWalkSpeeds or {}

	local steamId64 = ply:SteamID64()
	if steamId64 and self.OriginalWalkSpeeds[steamId64] == nil then
		self.OriginalWalkSpeeds[steamId64] = ply:GetWalkSpeed()
	end

	local original = (steamId64 and self.OriginalWalkSpeeds[steamId64]) or ply:GetWalkSpeed()
	local boosted = self.ElfWalkSpeed or 320
	ply:SetWalkSpeed(math.max(original, boosted))
end

---Restores previously saved walk speed and clears from table.
---@param self table Fun round EVENT table (used to read/clear OriginalWalkSpeeds)
---@param ply Player Player whose walk speed should be restored
local function restorePreviousWalkSpeed(self, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not self.OriginalWalkSpeeds then return end

	local steamId64 = ply:SteamID64()
	local saved = steamId64 and self.OriginalWalkSpeeds[steamId64] or nil
	if saved == nil then return end

	ply:SetWalkSpeed(saved)
	self.OriginalWalkSpeeds[steamId64] = nil
end

---Clears per-round elf state on a player (network vars, freeze, scale)
---@param ply Player Player to reset
local function resetFromElf(ply)

	if not IsValid(ply) then return end
	ply:SetNWBool("gmcore.FR.ChristmasCheer.OriginalElf", false)
	ply:SetNWBool("gmcore.FR.ChristmasCheer.ElfActive", false)
	ply:SetNWInt("gmcore.FR.ChristmasCheer.FreezeCount", 0)
	ply:Freeze(false)
	ply:SetModelScale(1, 0)
end

---Saves player's current model in table to be reverted when the round ends
---@param self table Fun round EVENT table (used to store OriginalModels)
---@param ply Player Player whose model should be remembered
local function saveCurrentPlayerModel(self, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	self.OriginalModels = self.OriginalModels or {}

	local steamId64 = ply:SteamID64()
	if not steamId64 or self.OriginalModels[steamId64] then return end

	self.OriginalModels[steamId64] = ply:GetModel()
end

---Restores previously saved model and clears from table
---@param self table Fun round EVENT table (used to read/clear OriginalModels)
---@param ply Player Player whose model should be restored
local function restorePreviousPlayerModel(self, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local steamId64 = ply:SteamID64()
	local saved = steamId64 and self.OriginalModels and self.OriginalModels[steamId64] or nil
	if not saved or saved == "" then return end

	ply:SetModel(saved)
		self.OriginalModels[steamId64] = nil
end

---Gives candy cane weapon (if missing) and sets conversion duration
---@param ply Player Player to equip.
---@param convertDuration? number Seconds required to convert; if nil, duration is not modified.
local function giveAndSetCandyCane(ply, convertDuration)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply:StripWeapons()
	ply:Give("gmcore_funround_candycane")

	if not convertDuration then return end

	local wep = ply:GetWeapon("gmcore_funround_candycane")
	if not IsValid(wep) then return end

	---@class gmcoreFunRoundCandyCane : Weapon
---@field ConvertDuration number Seconds required to convert a player with the candy cane

	---@type GLFunRoundCandyCane
	local candy = wep

	candy.ConvertDuration = convertDuration

	if candy.SetDuration then
		candy:SetDuration(convertDuration)
	end
end

function EVENT:Prepare()
	m_Begin(self)

	self.ConversionsThisRound = {}
	self.OriginalModels = {}
	self.OriginalWalkSpeeds = {}

	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("PlayerCanPickupWeapon", self.PlayerCanPickupWeapon)
	self:AddHook("ScalePlayerDamage", self.ScalePlayerDamage)
	self:AddHook("EntityTakeDamage", self.PreventTeamDamage)
	self:AddHook("TTTBeginRound", self.BeginRoundSetup)
end

function EVENT:OverrideRoles()
	-- Let base TTT SelectRoles run normally (traitors become elves).
	return false
end

function EVENT:BeginRoundSetup()
	if not isActive() then return end

	-- Safety net: if a detective somehow exists, demote to innocent.
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and ply:GetRole() == ROLE_DETECTIVE then
			ply:SetRole(ROLE_INNOCENT)
			if ply.StripRoleWeapons then
				ply:StripRoleWeapons()
			end
		end
	end
	if SendFullStateUpdate then
		SendFullStateUpdate()
	end

	-- Count initial elves (TTT-selected traitors) for health scaling.
	local initialElves = 0
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and ply:GetRole() == ROLE_TRAITOR then
			initialElves = initialElves + 1
		end
	end
	self.InitialElfCount = math.max(1, initialElves)

	local elfHealth = self:GetScaledElfHealth()

	for _, ply in player.Iterator() do
		resetFromElf(ply)
		self.ConversionsThisRound[ply:SteamID()] = 0

		if isElf(ply) then
			ply:SetNWBool("gmcore.FR.ChristmasCheer.OriginalElf", true)
			ply:SetNWBool("gmcore.FR.ChristmasCheer.ElfActive", false)
			self:ConvertPlayer(ply, ply, true)
			ply:SetMaxHealth(elfHealth)
			ply:SetHealth(elfHealth)
			gmcore.chatprint(ply, "You are the Elf! Spread Christmas cheer with your Candy Cane.")
		else
			gmcore.chatprint(ply, "An elf has been revealed! Don't get converted!")
		end
	end
end

function EVENT:ScalePlayerDamage(_, _, dmginfo)
	if not isActive() then return end

	local att = dmginfo:GetAttacker()
	if IsValid(att) and att:IsPlayer() and isElf(att) then
		-- Elves can't deal damage
		dmginfo:ScaleDamage(0)
	end
end

function EVENT:PreventTeamDamage(victim, dmginfo)
	if not isActive() then return end
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if not dmginfo then return end

	local attacker = dmginfo:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if victim == attacker then return end

	local vRole = victim:GetRole()
	local aRole = attacker:GetRole()

	if (vRole == ROLE_TRAITOR and aRole == ROLE_TRAITOR) or (vRole == ROLE_INNOCENT and aRole == ROLE_INNOCENT) then
		dmginfo:ScaleDamage(0)

		return true
	end
end

function EVENT:PlayerCanPickupWeapon(ply, wep)
	if not isActive() then return end
	if not IsValid(ply) or not IsValid(wep) then return end


	if isElf(ply) then
		if ply:GetNWBool("gmcore.FR.ChristmasCheer.ElfActive", false) and GetRoundState() == ROUND_ACTIVE then
			return wep:GetClass() == "gmcore_funround_candycane"
		end

		-- Before activation, allow basic weapons, eventually stripped
		return true
	end

	-- Non-elves cannot pick up the candy cane.
	if wep:GetClass() == "gmcore_funround_candycane" then
		return false
	end
end

function EVENT:OverrideWin()
	if GetConVar("ttt_debug_preventwin") and GetConVar("ttt_debug_preventwin"):GetInt() == 1 then
		return WIN_NONE
	end

	local anyInnocent = false
	local anyElf = false

	for _, ply in player.Iterator() do
		if not ply:IsTerror() or not ply:Alive() or ply:GetForceSpec() then continue end

		if ply:GetRole() == ROLE_INNOCENT then
			anyInnocent = true
		elseif ply:GetRole() == ROLE_TRAITOR then
			anyElf = true
		end
	end

	-- If all elves are dead/absent, innocents win
	if not anyElf and anyInnocent then
		return WIN_INNOCENT
	end

	-- If everyone is converted and at least one elf, elves win
	if anyElf and not anyInnocent then
		return WIN_TRAITOR
	end

	return WIN_NONE
end

---Converts a player to an elf. Uses bInitial to skip elf checks for when first elf is picked from BeginRoundsSetup
---@param attacker Player Player who is converting
---@param victim Player Player who is being converted
---@param bInitial boolean True if this is the initial elf conversion. If so, confirm attacker and victim elf status.
function EVENT:ConvertPlayer(attacker, victim, bInitial)
	if not isActive() then return end
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if not IsValid(victim) or not victim:IsPlayer() then return end

	if not bInitial then
		if attacker == victim then return end
		if not isElf(attacker) then return end
		if isElf(victim) then return end
	end

	saveCurrentPlayerModel(self, victim)
	applyElfWalkSpeed(self, victim)

	victim:StripWeapons()
	victim:Give("gmcore_funround_candycane")
	victim:SetRole(ROLE_TRAITOR)
	victim:SetNWBool("gmcore.FR.ChristmasCheer.ElfActive", true)
	victim:SetModelScale(self.ElfScale or 0.85, 0)
	victim:SetModel(elf_model)
	victim:EmitSound(sound_christmas)

	local elfHealth = self:GetScaledElfHealth()
	victim:SetMaxHealth(elfHealth)
	victim:SetHealth(elfHealth)

	if gmcore and gmcore.FunRounds and gmcore.FunRounds.UpdateRevealedRoles then
		gmcore.FunRounds:UpdateRevealedRoles()
	end

	giveAndSetCandyCane(victim, self.ConvertDuration)

	if not bInitial then
		self.ConversionsThisRound[attacker:SteamID()] = (self.ConversionsThisRound[attacker:SteamID()] or 0) + 1
	end
end

function EVENT:ComputeRewards()
	local topPly
	local topCount = 0

	for steamId, count in pairs(self.ConversionsThisRound or {}) do
		local ply = player.GetBySteamID(steamId)
		if not IsValid(ply) then continue end

		if count > topCount then
			topPly = ply
			topCount = count
		end

		if count > 0 then
			local pts = count * (self.Rewards.iPerConversion or 10)
			ply:PS_GivePointsBoostable(pts)
			rewardMessageToPly(count .. " Conversions", pts, true, ply)
		end
	end

	local aliveInnocents = {}
	local aliveElves = {}

	for _, ply in player.Iterator() do
		if not ply:IsTerror() or not ply:Alive() or ply:GetForceSpec() then continue end

		if ply:GetRole() == ROLE_INNOCENT then
			table.insert(aliveInnocents, ply)
		elseif ply:GetRole() == ROLE_TRAITOR then
			table.insert(aliveElves, ply)
		end
	end

	local elvesWon = (#aliveElves > 0 and #aliveInnocents == 0)
	local innocentsWon = (#aliveElves == 0 and #aliveInnocents > 0)

	if elvesWon then
		for _, ply in ipairs(aliveElves) do
			ply:PS_GivePointsBoostable(self.Rewards.iLastStanding or 50)
			rewardMessageToPly("Last team standing", self.Rewards.iLastStanding or 50, true, ply)
		end
	elseif innocentsWon then
		for _, ply in ipairs(aliveInnocents) do
			ply:PS_GivePointsBoostable(self.Rewards.iLastStanding or 50)
			rewardMessageToPly("Last team standing", self.Rewards.iLastStanding or 50, true, ply)
		end
	end

	if topPly then
		topPly:PS_GivePointsBoostable(self.Rewards.iMostConversions or 75)
		rewardMessageToPly(topCount .. " | Most conversions!", self.Rewards.iMostConversions or 75, true, topPly)
	end

	local tToSendWinners = {
		eMostConversions = topPly or nil,
		iConversionCount = topCount or 0,
		bElvesWon = elvesWon
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

function EVENT:End()
	m_End(self)

	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:IsPlayer() then continue end

		ply:StopSound(sound_christmas)
		resetFromElf(ply)
		restorePreviousPlayerModel(self, ply)
		restorePreviousWalkSpeed(self, ply)
	end

	self.OriginalModels = {}
	self.OriginalWalkSpeeds = {}
end

-- Expose conversion API for the weapon.
function gmcore.FunRounds.ChristmasCheer_Convert(attacker, victim)
	local round = gmcore.FunRounds.RegisteredFunRounds["Christmas Cheer"]
	if not round or not isfunction(round.ConvertPlayer) then return end

	round:ConvertPlayer(attacker, victim)
end

gmcore.FunRounds:RegisterFunRound("Christmas Cheer", EVENT)
