--[[
	pointshop/sv_init.lua
	first file included serverside.
]]--

include "sh_init.lua"
include "sv_player_extension.lua"
include "sv_manifest.lua"
include "sv_ttt_extension.lua"

-- GL Custom
include("sv_lottery.lua")

-- net hooks

net.Receive("PS_BuyItem", function(length, ply)
	ply:PS_BuyItem(net.ReadString())
end)

net.Receive("PS_UpgradeItem", function(length, ply)
	ply:PS_UpgradeItem(net.ReadString())
end)

net.Receive("PS_SellItem", function(length, ply)
	ply:PS_SellItem(net.ReadString())
end)

net.Receive("PS_EquipItem", function(length, ply)
	ply:PS_EquipItem(net.ReadString())
end)

net.Receive("PS_HolsterItem", function(length, ply)
	ply:PS_HolsterItem(net.ReadString())
end)

net.Receive("PS_ModifyItem", function(length, ply)
	ply:PS_ModifyItem(net.ReadString(), net.ReadTable())
end)

net.Receive("PS_ClientAddModel", function(length, ply)
	ply:PS_AddClientsideModel(net.ReadString())
end)

net.Receive("PS_ClientRemoveModel", function(length, ply)
	ply:PS_RemoveClientsideModel(net.ReadString())
end)

-- player to player

net.Receive("PS_SendPoints", function(length, ply)
	local other = net.ReadEntity()
	local points = math.Clamp(net.ReadInt(32), 0, 1000000)

	if not PS.Config.CanPlayersGivePoints then return end
	if not points or points == 0 then return end
	if not other or not IsValid(other) or not other:IsPlayer() then return end
	if not ply or not IsValid(ply) or not ply:IsPlayer() then return end
	if not ply:PS_HasPoints(points) then
		ply:PS_Notify("You can't afford to give away ", points, " of your ", PS.Config.PointsName, ".")
		return
	end

	ply.PS_LastGavePoints = ply.PS_LastGavePoints or 0
	if ply.PS_LastGavePoints + 5 > CurTime() then
		ply:PS_Notify("Slow down! You can't give away points that fast.")
		return
	end

	local pts = points == 1 and "point" or "points"
	local giveMsg   = string.format("You have given %d %s to %s.",     points, pts, other:Nick())
	local receiveMsg = string.format("You have received %d %s from %s.", points, pts, ply:Nick())

	ply:PS_TakePoints(points)
	gmcore.NotifyPly(ply, giveMsg, gmcore.NotifyType.POINTSHOP, 5, "gmcore/ui/points_send.mp3")
	gmcore.ChatPrint(ply, "You have given ", Color(46, 204, 113), tostring(points), color_white, " ", pts, " to ", Color(52, 152, 219), other:Nick(), color_white, ".")

	other:PS_GivePoints(points)
	gmcore.NotifyPly(other, receiveMsg, gmcore.NotifyType.POINTSHOP, 5, "gmcore/ui/points_receive.mp3")
	gmcore.ChatPrint(other, "You have received ", Color(46, 204, 113), tostring(points), color_white, " ", pts, " from ", Color(52, 152, 219), ply:Nick(), color_white, ".")

	ply.PS_LastGavePoints = CurTime()
end)

-- admin points

net.Receive("PS_GivePoints", function(length, ply)
	local other = net.ReadEntity()
	local points = net.ReadInt(32)

	if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

	local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
	local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()

	if (admin_allowed or super_admin_allowed) and other and points and IsValid(other) and other:IsPlayer() then
		local pts = points == 1 and "point" or "points"
		local msg = string.format("You have received %d %s from %s.", points, pts, ply:Nick())
		other:PS_GivePoints(points)
		gmcore.NotifyPly(other, msg, gmcore.NotifyType.POINTSHOP, 5, "gmcore/ui/points_receive.mp3")
		gmcore.ChatPrint(other, "You have received ", Color(46, 204, 113), tostring(points), color_white, " ", pts, " from ", Color(52, 152, 219), ply:Nick(), color_white, ".")
	end
end)

net.Receive("PS_TakePoints", function(length, ply)
	local other = net.ReadEntity()
	local points = net.ReadInt(32)

	if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

	local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
	local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()

	if (admin_allowed or super_admin_allowed) and other and points and IsValid(other) and other:IsPlayer() then
		local pts = points == 1 and "point" or "points"
		local msg = string.format("%s has taken %d %s from you.", ply:Nick(), points, pts)
		other:PS_TakePoints(points)
		gmcore.NotifyPly(other, msg, gmcore.NotifyType.POINTSHOP, 5, "gmcore/ui/points_take.mp3")
		gmcore.ChatPrint(other, Color(52, 152, 219), ply:Nick(), color_white, " has taken ", Color(46, 204, 113), tostring(points), color_white, " ", pts, " from you.")
	end
end)

net.Receive("PS_SetPoints", function(length, ply)
	local other = net.ReadEntity()
	local points = net.ReadInt(32)

	if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

	local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
	local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()

	if (admin_allowed or super_admin_allowed) and other and points and IsValid(other) and other:IsPlayer() then
		local pts = points == 1 and "point" or "points"
		local msg = string.format("Your points have been set to %d by %s.", points, ply:Nick())
		other:PS_SetPoints(points)
		gmcore.NotifyPly(other, msg, gmcore.NotifyType.POINTSHOP, 5, "gmcore/ui/points_set.mp3")
		gmcore.ChatPrint(other, "Your points have been set to ", Color(46, 204, 113), tostring(points), color_white, " by ", Color(52, 152, 219), ply:Nick(), color_white, ".")
	end
end)

-- admin items

net.Receive("PS_GiveItem", function(length, ply)
	local other = net.ReadEntity()
	local item_id = net.ReadString()

	if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

	local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
	local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()

	if (admin_allowed or super_admin_allowed) and other and item_id and PS.Items[item_id] and IsValid(other) and other:IsPlayer() and not other:PS_HasItem(item_id) then
		other:PS_GiveItem(item_id)
	end
end)

net.Receive("PS_TakeItem", function(length, ply)
	local other = net.ReadEntity()
	local item_id = net.ReadString()

	if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

	local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
	local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()

	if (admin_allowed or super_admin_allowed) and other and item_id and PS.Items[item_id] and IsValid(other) and other:IsPlayer() and other:PS_HasItem(item_id) then
		-- holster it first without notificaiton
		other.PS_Items[item_id].Equipped = false

		local ITEM = PS.Items[item_id]
		ITEM:OnHolster(other)
		other:PS_TakeItem(item_id)
	end
end)

net.Receive("PS_RequestEventPlaytime", function(length, ply)
	local eventId = net.ReadString()

	if not eventId or eventId == "" then return end

	-- Check cached value (loaded on spawn + updated by tick timer)
	if ply.GL_GetEventPlaytimeMins then
		local mins = ply:GL_GetEventPlaytimeMins(eventId)
		if mins >= 0 then
			net.Start("PS_SendEventPlaytime")
			net.WriteString(eventId)
			net.WriteUInt(math.max(0, math.floor(mins)), 32)
			net.Send(ply)
			return
		end

		-- Not loaded yet... load then respond
		if ply.GL_LoadEventPlaytime then
			ply:GL_LoadEventPlaytime(eventId, function(loadedMins)
				if not IsValid(ply) then return end
				net.Start("PS_SendEventPlaytime")
				net.WriteString(eventId)
				net.WriteUInt(math.max(0, math.floor(loadedMins or 0)), 32)
				net.Send(ply)
			end)

			return
		end
	end

	-- Fallback if we fail :()
	ply:GMCoreGetPData("gmcore.EventPlayTime_" .. eventId, 0, function(playtimeMins)
		if not IsValid(ply) then return end

		net.Start("PS_SendEventPlaytime")
		net.WriteString(eventId)
		net.WriteUInt(math.max(0, math.floor(playtimeMins or 0)), 32)
		net.Send(ply)
	end)
end)

-- hooks

local KeyToHook = {
	F1 = "ShowHelp",
	F2 = "ShowTeam",
	F3 = "ShowSpare1",
	F4 = "ShowSpare2",
	None = "ThisHookDoesNotExist"
}

hook.Add(KeyToHook[PS.Config.ShopKey], "PS_ShopKey", function(ply)
	ply:PS_ToggleMenu()
end)

hook.Add("PlayerSpawn", "PS_PlayerSpawn", function(ply) ply:PS_PlayerSpawn() end)
hook.Add("PlayerDeath", "PS_PlayerDeath", function(ply) ply:PS_PlayerDeath() end)
hook.Add("PlayerInitialSpawn", "PS_PlayerInitialSpawn", function(ply) ply:PS_PlayerInitialSpawn() end)
hook.Add("PlayerDisconnected", "PS_PlayerDisconnected", function(ply) ply:PS_PlayerDisconnected() end)

hook.Add("PlayerSay", "PS_PlayerSay", function(ply, text)
	if string.len(PS.Config.ShopChatCommand) > 0 then
		if string.sub(text, 0, string.len(PS.Config.ShopChatCommand)) == PS.Config.ShopChatCommand then
			ply:PS_ToggleMenu()
			return ""
		end
	end
end)

-- ugly networked strings

util.AddNetworkString("PS_Items")
util.AddNetworkString("PS_Points")
util.AddNetworkString("PS_BuyItem")
util.AddNetworkString("PS_UpgradeItem")
util.AddNetworkString("PS_SellItem")
util.AddNetworkString("PS_EquipItem")
util.AddNetworkString("PS_HolsterItem")
util.AddNetworkString("PS_ModifyItem")
util.AddNetworkString("PS_SendPoints")
util.AddNetworkString("PS_GivePoints")
util.AddNetworkString("PS_TakePoints")
util.AddNetworkString("PS_SetPoints")
util.AddNetworkString("PS_GiveItem")
util.AddNetworkString("PS_TakeItem")
util.AddNetworkString("PS_AddClientsideModel")
util.AddNetworkString("PS_RemoveClientsideModel")
util.AddNetworkString("PS_SendClientsideModels")
util.AddNetworkString("PS_SendNotification")
util.AddNetworkString("PS_ToggleMenu")
util.AddNetworkString("PS_ClientAddModel")
util.AddNetworkString("PS_ClientRemoveModel")
util.AddNetworkString("PS_RequestEventPlaytime")
util.AddNetworkString("PS_SendEventPlaytime")
util.AddNetworkString("PS_EventProgressDialog")

-- console commands

concommand.Add(PS.Config.ShopCommand, function(ply, cmd, args)
	ply:PS_ToggleMenu()
end)

-- version checker

PS.CurrentBuild = 0
PS.LatestBuild = 0

SetGlobalString("gmcore.Pointshop.WebUiBaseUrl", PS.Config.WebUiBaseUrl or "")
SetGlobalString("gmcore.Pointshop.WebUiVersion", PS.Config.WebUiVersion or "")

-- data providers

---Loads the configured data provider module from the providers directory.
function PS:LoadDataProvider()
	local path = "pointshop/providers/" .. self.Config.DataProvider .. ".lua"
	if not file.Exists(path, "LUA") then
		error("Pointshop data provider not found. " .. path)
	end

	PROVIDER = {}
	PROVIDER.__index = {}
	PROVIDER.ID = self.Config.DataProvider

	include(path)

	self.DataProvider = PROVIDER
	PROVIDER = nil
end

---Retrieves a player's points and items from the data provider.
---@param ply Player The player whose data to retrieve
---@param callback fun(points: number, items: table)
function PS:GetPlayerData(ply, callback)
	self.DataProvider:GetData(ply:SteamID64(), function(points, items)
		callback(PS:ValidatePoints(tonumber(points)), items)
	end)
end

---Sets a player's points via the data provider.
---@param ply Player The player whose points to set
---@param points number The exact point value to set
function PS:SetPlayerPoints(ply, points)
	self.DataProvider:SetPoints(ply, points)
end

---Adds points to a player via the data provider.
---@param ply Player The player to give points to
---@param points number The number of points to add
function PS:GivePlayerPoints(ply, points)
	self.DataProvider:UpdatePoints(ply:SteamID64(), points)
end

---Removes points from a player via the data provider.
---@param ply Player The player to take points from
---@param points number The number of points to remove
function PS:TakePlayerPoints(ply, points)
	self.DataProvider:UpdatePoints(ply:SteamID64(), -points)
end

---Saves an existing player item's data via the data provider.
---@param ply Player The player who owns the item
---@param itemId string The unique identifier of the item
---@param data table The item data to save
---@param fCallback? function
function PS:SavePlayerItem(ply, itemId, data, fCallback)
	self.DataProvider:SaveItem(ply:SteamID64(), itemId, data, fCallback)
end

---Gives a player a new item via the data provider.
---@param ply Player The player to give the item to
---@param itemId string The unique identifier of the item
---@param data table The item data to store
---@param fCallback? function
function PS:GivePlayerItem(ply, itemId, data, fCallback)
	-- 3rd parameter is item cost. Just set to 0
	self.DataProvider:BuyItem(ply:SteamID64(), itemId, 0, fCallback)
end

---Removes a player's item via the data provider.
---@param ply Player The player whose item to remove
---@param itemId string The unique identifier of the item to remove
---@param fCallback? function
function PS:TakePlayerItem(ply, itemId, fCallback)
	-- 3rd parameter is item reimbursement. Just set to 0
	self.DataProvider:SellItem(ply:SteamID64(), itemId, 0, fCallback)
end
