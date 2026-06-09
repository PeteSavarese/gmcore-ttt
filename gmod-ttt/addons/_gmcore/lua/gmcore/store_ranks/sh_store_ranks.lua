if SERVER then
	AddCSLuaFile("gmcore/store_ranks/sh_store_ranks_config.lua")
	include("gmcore/store_ranks/sh_store_ranks_config.lua")
else
	include("gmcore/store_ranks/sh_store_ranks_config.lua")
end

hook.Add("GetScoreboardNameColor", "gmcore.StoreRank.ScoreboardDisplay", function(ply)
	if ply:IsStoreRank() then
		local iPlyRank = ply:GetStoreRank()

		return gmcore.StoreRank.Ranks[iPlyRank].color
	end
end)

---@class Player
local pMeta = FindMetaTable("Player")

---Check if the player has a store rank
---@return boolean hasRank True if the player has a store rank greater than 0
function pMeta:IsStoreRank()
	return tonumber(self:GetNWInt("gmcore.StoreRank")) > 0
end

---Return player's store rank index as seen in gmcore.StoreRank.Ranks
---@return number? rankIndex The player's current store rank index
function pMeta:GetStoreRank()
	return tonumber(self:GetNWInt("gmcore.StoreRank"))
end

if SERVER then
	util.AddNetworkString("gmcore.StoreRank.Changed")
end

if CLIENT then
	net.Receive("gmcore.StoreRank.Changed", function()
		local ply = net.ReadEntity()
		local newRank = net.ReadUInt(8)
		local oldRank = net.ReadUInt(8)

		-- Force NWInt total new values so that any code which calls ply:GetStoreRank()
		if IsValid(ply) then
			ply:SetNWInt("gmcore.StoreRank", newRank)
		end

		---@param ply Player The player whose rank changed.
		---@param newRank number The new store rank index.
		---@param oldRank number The previous store rank index.
		hook.Call("gmcore.StoreRank.Changed", nil, ply, newRank, oldRank)
	end)
end
