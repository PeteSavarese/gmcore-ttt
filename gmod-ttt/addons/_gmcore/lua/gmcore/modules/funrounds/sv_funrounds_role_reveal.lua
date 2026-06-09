
---Sends a role list message to a player or all players.
---@param role number TTT role identifier (e.g. ROLE_TRAITOR)
---@param role_ids number[] Entity indices of players with this role
---@param ply_or_rf? Player|RecipientFilter
local function sendRoleListMessage(role, role_ids, ply_or_rf)
	net.Start("TTT_RoleList")
		net.WriteUInt(role, 2)

		local num_ids = #role_ids
		net.WriteUInt(num_ids, 8)
		for i = 1, num_ids do
			net.WriteUInt(role_ids[i] - 1, 7)
		end

	if ply_or_rf then
		net.Send(ply_or_rf)
	else
		net.Broadcast()
	end
end

---Collects entity indices for players matching a role.
---@param role number TTT role identifier to filter by
---@param aliveOnly boolean If true, only include living active players
---@return number[] entIndices Entity indices of players matching the specified role
local function collectRoleEntIndices(role, aliveOnly)
	local ids = {}
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		if aliveOnly and (not ply.IsActive or not ply:IsActive()) then continue end

		if ply.IsRole then
			if ply:IsRole(role) then
				table.insert(ids, ply:EntIndex())
			end
		else
			if ply:GetRole() == role then
				table.insert(ids, ply:EntIndex())
			end
		end
	end

	return ids
end

---Updates revealed roles for the current fun round.
function gmcore.FunRounds:UpdateRevealedRoles()
	if not self.ActiveRound then return end
	local round = self.RegisteredFunRounds and self.RegisteredFunRounds[self.ChosenFunRound] or nil
	if not round then return end

	local aliveOnly = round.bRevealRolesAliveOnly ~= false

	if round.bRevealAllRoles then
		sendRoleListMessage(ROLE_TRAITOR, collectRoleEntIndices(ROLE_TRAITOR, aliveOnly))
		sendRoleListMessage(ROLE_DETECTIVE, collectRoleEntIndices(ROLE_DETECTIVE, aliveOnly))
		sendRoleListMessage(ROLE_INNOCENT, collectRoleEntIndices(ROLE_INNOCENT, aliveOnly))

		return
	end

	if round.bRevealTraitors then
		sendRoleListMessage(ROLE_TRAITOR, collectRoleEntIndices(ROLE_TRAITOR, aliveOnly))
	end
end

---Starts the periodic role reveal timer for the current fun round.
function gmcore.FunRounds:StartRoleRevealTimer()
	if not self.ActiveRound then return end
	local round = self.RegisteredFunRounds and self.RegisteredFunRounds[self.ChosenFunRound] or nil
	if not round then return end
	if not round.bRevealTraitors and not round.bRevealAllRoles then return end

	-- The role list can be reset by the gamemode during early-round setup, so we resend periodically.
	self:UpdateRevealedRoles()

	timer.Create("gmcore.FunRounds.RoleReveal", 3, 0, function()
		if not gmcore or not gmcore.FunRounds or not gmcore.FunRounds.ActiveRound then return end
		gmcore.FunRounds:UpdateRevealedRoles()
	end)
end

---Stops the role reveal timer.
function gmcore.FunRounds:StopRoleRevealTimer()
	timer.Remove("gmcore.FunRounds.RoleReveal")
end
