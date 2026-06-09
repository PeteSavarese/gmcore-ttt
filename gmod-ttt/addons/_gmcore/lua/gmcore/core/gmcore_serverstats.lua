---@class gmcore
---@field UpdateServerStats fun(self: gmcore) Update server stats in database

---Collect and push current server state (players, map, reports) to the database.\n---Called on a 60-second timer.
function gmcore:UpdateServerStats()
	local gmcore_playerarr, gmcore_playerjson, gmcore_playercount, gmcore_staffcount, gmcore_currentmap, current_reports, total_reports
	gmcore_playercount = 0
	gmcore_staffcount = 0
	gmcore_playerarr = {}
	current_reports = 0
	total_reports = 0

	for k, v in pairs(player.GetAll()) do
		if v:IsPlayer() and not v:IsBot() then
			local tempT = {}
			gmcore_playercount = gmcore_playercount + 1

			tempT["ingame_name"] = v:Nick()
			tempT["steamid"] = v:SteamID()
			tempT["score"] = v:Frags()
			tempT["spectator"] = v:GetForceSpec()
			tempT["donor_rank"] = v:IsStoreRank() and v:GetStoreRank() or 0
			tempT["staff_rank"] = v:StaffRank() or "not"

			table.insert(gmcore_playerarr, tempT)

			if v:StaffRank() then
				gmcore_staffcount = gmcore_staffcount + 1
			end
		end
	end

	gmcore_currentmap = game.GetMap()
	gmcore_playerjson = util.TableToJSON(gmcore_playerarr)
	for k, v in pairs(Damagelog.Reports.Previous) do
		total_reports = total_reports + 1
		if (v.status < 3) then
			current_reports = current_reports + 1
		end
	end
	for k, v in pairs(Damagelog.Reports.Current) do
		total_reports = total_reports + 1
		if (v.status < 3) then
			current_reports = current_reports + 1
		end
	end

	-- sql = 'UPDATE servers SET hostName = \'' .. gmcore.Database:Escape(GetHostName()) .. '\', serverAddr = \'' .. gmcore.Database:Escape(game.GetIPAddress()) .. '\', currentMap = \'' .. gmcore.Database:Escape(gmcore_currentmap) .. '\', playerCount = ' .. gmcore_playercount .. ', maxCount = ' .. game.MaxPlayers() .. ' ,staffCount = ' .. gmcore_staffcount .. ', playersJSON = \'' .. gmcore.Database:Escape(gmcore_playerjson) .. '\', lastUpdate = \'' .. os.time() .. '\' WHERE id = ' .. gmcore.ServerId

	local updSStats = gmcore.Database:prepare(
		"UPDATE servers SET hostname = ?, serverAddr = ?, currentMap = ?, playerCount = ?, maxCount = ?, staffCount = ?, total_reports = ?, active_reports = ?, playersJSON = ?, lastUpdate = ? WHERE id = ?")

	function updSStats:onSuccess(data)
		gmcore.DebugPrint("Server stats updated")
	end

	function updSStats:onError(err)
		gmcore.print("Server stats error: " .. err)
	end

	updSStats:setString(1, GetHostName())
	updSStats:setString(2, game.GetIPAddress())
	updSStats:setString(3, gmcore_currentmap)
	updSStats:setNumber(4, gmcore_playercount)
	updSStats:setNumber(5, game.MaxPlayers())
	updSStats:setNumber(6, gmcore_staffcount)
	updSStats:setNumber(7, total_reports)
	updSStats:setNumber(8, current_reports)
	updSStats:setString(9, gmcore_playerjson)
	updSStats:setNumber(10, os.time())
	updSStats:setNumber(11, gmcore.ServerId)
	updSStats:start()
end

timer.Create("gmcore.ServerStats.UpdateServerInfo", 60, 0, function()
	gmcore:UpdateServerStats()
end)

timer.Start("gmcore.ServerStats.UpdateServerInfo")

gmcore.print("Server Stats Module Loaded Success")
