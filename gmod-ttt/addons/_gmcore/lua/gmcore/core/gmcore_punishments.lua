---@class gmcore
---@field AddPunishment fun(target: Player|string, type: string, reason: string, staffPunisher: Player|string) Log a punishment

require("mysqloo")

---Resolve admin display name from entity or string
---@param staff Player|string Staff member or name string
---@return string name Admin display name
local function setAdminNick(staff)
	if IsValid(staff) and staff:IsPlayer() then
		return staff:Nick()
	elseif isstring(staff) then
		return staff
	end

		return "Console"
end

---Log a punishment (kick, warn, etc.) to the database
---@param target Player|string Player entity or SteamID string
---@param type string Punishment type (e.g. "kick", "warn")
---@param reason string Reason for the punishment
---@param staffPunisher Player|string Staff member who issued the punishment
function gmcore.AddPunishment(target, type, reason, staffPunisher)
	local steamId = nil
	local staffNick = setAdminNick(staffPunisher)

	if isstring(target) and string.match(target, "^STEAM_%d:%d:%d+$") then
		steamId = target
	elseif IsValid(target) and target:IsPlayer() then
		steamId = target:SteamID()
	else
		gmcore.print("AddPunishment: Invalid target (must be player entity or steamid)")

		return
	end

	local addpunish = gmcore.Database:prepare("INSERT INTO punishments (`steamid`, `server`, `punishment`, `added`, `admin`, `reason`) VALUES(?, ?, ?, ?, ?, ?)")

	function addpunish:onSuccess(data)
		gmcore.print("Punishment added")
	end

	function addpunish:onError(err)
		gmcore.print("Punishment add error: ", err)
	end

	addpunish:setString(1, steamId)
	addpunish:setString(2, tostring(gmcore.ServerId))
	addpunish:setString(3, type)
	addpunish:setNumber(4, os.time())
	addpunish:setString(5, staffNick)
	addpunish:setString(6, reason)
	addpunish:start()
end

gmcore.print("Punishments Module Loaded Success")

hook.Add("Initialize", "gmcore.Punishments.AddKickHook", function()
	if not ULib then
		gmcore.print("ULib not found, cannot log kicks")

		return
	end

	hook.Add(ULib.HOOK_USER_KICKED, "gmcore.Punishments.HlogKick", function(steamId, reason, staff)
		gmcore.AddPunishment(steamId, "kick", reason, staff)
	end)
end)
