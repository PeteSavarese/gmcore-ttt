function ulx.SetStoreRank(calling_ply, target_ply, rank)
	target_ply:SetStoreRank(rank)

	if rank ~= 0 then
		local rankData = gmcore.StoreRank.Ranks[rank]
		gmcore.ChatPrintAll(rankData.color, target_ply:Nick(), Color(255, 255, 255), " has received their rank of ", rankData.color, rankData.name)
	end
end

local helptable = {}

for k, v in pairs(gmcore.StoreRank.Ranks) do
	table.insert(helptable, k .. " - " .. v.name .. "\n")
end

local SetStoreRank = ulx.command("GL Store", "ulx setstorerank", ulx.SetStoreRank, "!setstorerank")
SetStoreRank:addParam{ type=ULib.cmds.PlayerArg }
SetStoreRank:addParam{ type=ULib.cmds.NumArg, min=0, default=0, max = #gmcore.StoreRank.Ranks, hint="Store Rank Index #", ULib.cmds.optional, ULib.cmds.round }
SetStoreRank:defaultAccess( ULib.ACCESS_SUPERADMIN )
SetStoreRank:help("Use the values to set a user's store rank \n" .. string.Implode("",helptable))
