gmcore.Loadout = gmcore.Loadout or {}
gmcore.Loadout.localLoadout = gmcore.Loadout.localLoadout or {}

---Update local loadout selection for slot.
---@param slot string
---@param weapon string
function gmcore.Loadout.SetLocalLoadout(slot, weapon)
	gmcore.Loadout.localLoadout = gmcore.Loadout.localLoadout or {}
	gmcore.Loadout.localLoadout[slot] = gmcore.Loadout.NormalizeSelection(weapon)
end

---Check if weapon is selected in loadout slot.
---@param slot string
---@param weapon string
---@return boolean
function gmcore.Loadout.HasInLoadout(slot, weapon)
	if not gmcore.Loadout.localLoadout then return false end

	return gmcore.Loadout.localLoadout[slot] == gmcore.Loadout.NormalizeSelection(weapon)
end

---Send current loadout selection to the server to update.
---@return boolean
function gmcore.Loadout.UpdateLoadoutToServer()
	if not gmcore.Loadout.localLoadout then return false end

	net.Start("gmcore.Loadout.UpdateLoadout")
	net.WriteTable(gmcore.Loadout.localLoadout)
	net.SendToServer()

	return true
end

net.Receive("gmcore.Loadout.UpdateLoadout", function()
	local tLoadout = net.ReadTable()
	gmcore.Loadout.localLoadout = tLoadout

	local ply = LocalPlayer()
	if IsValid(ply) then
		ply.PS_Loadout = tLoadout
	end

	gmcore.Notify("Your loadout has been updated", 5, "pointshop")
	hook.Call("gmcore.Loadout.LocalUpdateReceived", nil, tLoadout)
end)

net.Receive("gmcore.Loadout.SendConfig", function()
	local snapshot = net.ReadTable()
	gmcore.Loadout.ApplyConfig(snapshot)
end)
