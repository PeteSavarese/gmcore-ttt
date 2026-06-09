---RDM Manager (Damagelog) - Tracks damage, kills, and reports for TTT.
Damagelog = Damagelog or {}
Damagelog.ModulePath = "gmcore/modules/rdm_manager/"

if not file.Exists("damagelog", "DATA") then
		file.CreateDir("damagelog")
end

---@type table<string, boolean>
Damagelog.User_rights = Damagelog.User_rights or {}
---@type table<string, boolean>
Damagelog.RDM_Manager_Rights = Damagelog.RDM_Manager_Rights or {}

---@param user string User group name
---@param rights boolean Whether the group has damagelog access
---@param rdm_manager boolean Whether the group has RDM manager access
function Damagelog:AddUser(user, rights, rdm_manager)
		self.User_rights[user] = rights
		self.RDM_Manager_Rights[user] = rdm_manager
end

if SERVER then
		AddCSLuaFile(Damagelog.ModulePath .. "client/init.lua")
		include(Damagelog.ModulePath .. "server/init.lua")
else
		include(Damagelog.ModulePath .. "client/init.lua")
end
