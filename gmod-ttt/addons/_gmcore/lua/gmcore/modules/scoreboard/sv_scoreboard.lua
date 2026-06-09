---Staff traitor reveal: shows traitor roles to dead/spectating staff members.

---Sends a role list net message to specified plys or broadcasts it.
---@param role integer TTT role constant (e.g. ROLE_TRAITOR)
---@param role_ids integer[] Array of entity indices for players with this role
---@param ply_or_rf Player|Player[]|nil Target player(s) or nil for broadcast
local function SendRoleListMessage(role, role_ids, ply_or_rf)
	net.Start("TTT_RoleList")
			net.WriteUInt(role, 2)

			-- list contents
			local num_ids = #role_ids
			net.WriteUInt(num_ids, 8)
			for i=1, num_ids do
				net.WriteUInt(role_ids[i] - 1, 7)
			end

	if ply_or_rf then net.Send(ply_or_rf)
	else net.Broadcast() end
end

---Sends traitor list to all dead/spectating staff members.
local function SendTList()
	local traitor_ids = {}
	local staff = {}
	local send = false
	for k, v in ipairs(player.GetAll()) do
		if v:HasStaffPerms() and (not v:Alive() or not v:IsTerror()) then
			table.insert(staff, v)
			send = true
		end
		if v:IsRole(ROLE_TRAITOR) then
			table.insert(traitor_ids, v:EntIndex())
		end
	end

	if(send) then
		SendRoleListMessage(ROLE_TRAITOR, traitor_ids, staff)
	end
end

hook.Add("TTTBeginRound", "BeginRound_SendStaffTraitors", function()
	timer.Simple(1, SendTList)
	timer.Simple(12, SendTList) -- gets reset at about 10 seconds in for some reason, so reapply
end)

hook.Add("PlayerDeath", "PlayerDeath_SendStaffTraitors", function(victim, inflictor, attacker)
	if victim:HasStaffPerms() then
		local traitor_ids = {}
		for k, v in ipairs(player.GetAll()) do
			if v:IsRole(ROLE_TRAITOR) then
				table.insert(traitor_ids, v:EntIndex())
			end
		end

		SendRoleListMessage(ROLE_TRAITOR, traitor_ids, victim)
	end
end)
