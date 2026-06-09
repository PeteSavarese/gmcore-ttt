---@class BombRushEvent : FunRound
---@field GetTargetBombCount fun(self: BombRushEvent): number
---@field HandleBombDisbursement fun(self: BombRushEvent)
---@field OverrideWin fun(self: BombRushEvent): number
---@field OverrideRoles fun(self: BombRushEvent): boolean
---@field PreventWepPickup fun(self: BombRushEvent, ply: Player, wep: Weapon): boolean
---@field PreventFallDamage fun(self: BombRushEvent, ent: Entity, dmginfo: CTakeDamageInfo): boolean
---@field PlayerDeath fun(self: BombRushEvent, victim: Player, wep: Weapon, attacker: Player)

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Bomb Rush"] or {}
---@cast EVENT BombRushEvent

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale
local m_End = EVENT.End or nil


function EVENT:Prepare()
	m_Begin(self)

	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
end

--[[
	Checks how many bombs are in rotation and disburses the amount of bombs given plys alive
]]
function EVENT:GetTargetBombCount()
	local pc = #self:GetPlayers()
	if pc == 1 then return 0 end -- only 1 left, round end
	local c = 1
	if pc > 20 then
		c = pc / 5
	elseif pc > 7 then
		c = pc / 4
	else
		c = pc / 3
	end

	return math.max(1, math.floor(c))
end

function EVENT:HandleBombDisbursement()
	local numBombsInRotation = 0 -- Holds how many people currently have a bomb equipped
	local plysWithoutBombs = {}

	for _, ply in ipairs(self:GetPlayers(true)) do
		if ply:HasWeapon("gmcore_funround_bomb") then
			numBombsInRotation = numBombsInRotation + 1
		else
			table.insert(plysWithoutBombs, ply)
		end
	end

	local numBombs = self:GetTargetBombCount()

	if numBombs > 0 and (numBombs - numBombsInRotation) > 0 then
		for i = 1, (numBombs - numBombsInRotation) do
			-- Pick a random player without a bomb and give them one
			local randomIndex = #plysWithoutBombs
			plysWithoutBombs[randomIndex]:Give("gmcore_funround_bomb")
			table.remove(plysWithoutBombs, randomIndex)
		end
	end
end

function EVENT:Begin()
	self:AddHook("PlayerDeath", self.PlayerDeath) -- Add hook on round begin so pre-round deaths don't hand out bombs
	self:AddHook("EntityTakeDamage", self.PreventFallDamage)
	self:HandleBombDisbursement()

	-- This timer acts as a backup just in case PlayerDeath doesn't trigger bomb disbursement
	timer.Create("gmcore.FunRounds.BombDisbursement", 20, 0, function()
		EVENT:HandleBombDisbursement()
	end)
end

function EVENT:End()
	m_End(self)

	for _, ply in pairs(player.GetAll()) do
		ply:SetWalkSpeed(220) -- make sure all players are reset to normal speed.
	end
end

-- Make everyone an innocent
function EVENT:OverrideWin()
	local iPlyCount = 0

	for _, ply in pairs(player.GetAll()) do
		if ply:IsTerror() and ply:Alive() then
			iPlyCount = iPlyCount + 1
		end
	end

	return iPlyCount > 1 and WIN_NONE or WIN_TRAITOR
end

-- Make everyone an innocent
function EVENT:OverrideRoles()
	for _, ply in pairs(self:GetPlayers()) do
		ply:SetRole(ROLE_INNOCENT)
	end

	return true
end

function EVENT:PreventWepPickup(ply, wep)
	return wep:GetClass() == "gmcore_funround_bomb"
end

--[[
	Prevent fall damage
]]
function EVENT:PreventFallDamage(ent, dmginfo)
	if ! ent:IsPlayer() then return end

	if dmginfo:IsDamageType(DMG_FALL) then
		dmginfo:ScaleDamage(0)

		return true
	end
end

--[[
	Trigger for bomb disbursement
]]
function EVENT:PlayerDeath(victim, wep, attacker)
	if ! IsValid(attacker) then return end
	if ! IsValid(victim) then return end
	if wep:GetClass() != "gmcore_funround_bomb" then
		self:HandleBombDisbursement() -- prob caused by suicide, run bomb check incase they had a bomb

		return
	end

	if victim.GMCoreFunRoundLastDeath and victim.GMCoreFunRoundLastDeath == CurTime() then return end
	victim.GMCoreFunRoundLastDeath = CurTime() -- Sometiems this runs multiple times on same tick. Prevents that from happening

	gmcore.chatprintAll(Color(30, 90, 150), victim:Nick(), color_white, " has exploded!")

	self:HandleBombDisbursement()
end

function EVENT:ComputeRewards()
	timer.Remove("gmcore.FunRounds.BombDisbursement")

	local plyLastAlive = nil

	for _, v in pairs(self:GetPlayers()) do
		if v:Alive() and ! v:IsSpec() and v:IsTerror() then
			plyLastAlive = v

			plyLastAlive:PS_GivePointsBoostable(self.Rewards.lastStanding)
			rewardMessageToPly("Last Living!", self.Rewards.lastStanding, true, plyLastAlive)
		end
	end


	local tToSendWinners = {
		plyLastAlive = plyLastAlive or nil,
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

gmcore.FunRounds:RegisterFunRound("Bomb Rush", EVENT)
