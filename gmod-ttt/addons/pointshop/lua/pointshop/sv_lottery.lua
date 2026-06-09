util.AddNetworkString("gmcore.Pointshop.BuyTickets")

---@type table[]|nil List of unclaimed lottery winnings from database
PS.UnclaimedLotteryWinnings = nil -- List of tickets from lottery_history table that have been unclaimed.
---@type table<string, number[]> Maps SteamID64 to indices in UnclaimedLotteryWinnings
PS.UnclaimedLotteryWinningsMapping = {} -- Key is steamid and value is array with indicies of their winnings row in PS.UnclaimedLotteryWinningsMapping

--[[
	Queries database to load all lottery history and insert unclaimed winnings into Ps.UnclaimedLotteryWinnings, then calls PS:CheckUnclaimedWinning

	@initialPly First initial ply to spawn whos entity is then passed to PS:CheckUnclaimedWinning.
]]
---Queries the database for all lottery history and caches unclaimed winnings, then checks for the initial player.
---@param initialPly Player First player to spawn, used for initial unclaimed check
function PS:FetchTicketHistory(initialPly)
	local ticketHistoryQuery = gmcore.Database:query("SELECT * FROM lottery_history")

	function ticketHistoryQuery:onSuccess(data)
		if not data then return end

		PS.UnclaimedLotteryWinnings = {} -- Now that we have data, we can set to a table

		for _, winning in ipairs(data) do
			if winning["is_claimed"] == 0 then -- MySQL doesn't support bools. Column is tinyint where 0 is false and 1 is true.
				table.insert(PS.UnclaimedLotteryWinnings, winning)

				if not PS.UnclaimedLotteryWinningsMapping[winning["steamid"]] then
					PS.UnclaimedLotteryWinningsMapping[winning["steamid"]] = {}
				end

				table.insert(PS.UnclaimedLotteryWinningsMapping[winning["steamid"]], #PS.UnclaimedLotteryWinnings) -- #PS.UnclaimedLotteryWinnings is our current index
			end
		end

		PS:CheckUnclaimedWinnings(initialPly)
	end

	ticketHistoryQuery:start()
end

net.Receive("gmcore.Pointshop.BuyTickets", function(len, ply)
	local numTickets = net.ReadInt(16)

	if numTickets < 1 then
		ply:PS_Notify("The amount of tickets you want to purchase is invalid.")

		return
	end

	if not ply:PS_HasPoints(numTickets * 100) then return end

	local ticketQuery = gmcore.Database:prepare("INSERT INTO lottery_entries (steamid, player_name, tickets) VALUES(?, ?, ?) ON DUPLICATE KEY UPDATE player_name = ?, tickets = tickets + ?")

	function ticketQuery:onSuccess(data)
		-- Tell ply to refresh to view their new purchase
		ply:PS_TakePoints(numTickets * 100)

		net.Start("gmcore.Pointshop.BuyTickets")
		net.Send(ply)
	end

	function ticketQuery:onError(err)
		gmcore.print("[PS Lottery] BuyTickets error: " .. err)
	end

	ticketQuery:setString(1, ply:SteamID64())
	ticketQuery:setString(2, ply:Nick())
	ticketQuery:setNumber(3, numTickets)
	ticketQuery:setString(4, ply:Nick())
	ticketQuery:setNumber(5, numTickets)
	ticketQuery:start()
end)

---@type table<string, number> Tracks retry count per SteamID64 for unclaimed winnings check
local loadChecks = {} -- Tracks how many times we've had to rerun CheckUnclaimedWinning since PS data hasn't init for ply yet

---Checks and awards any unclaimed lottery winnings for a player. Retries up to 5 times if data isn't loaded.
---@param ply Player The player to check for unclaimed winnings
function PS:CheckUnclaimedWinnings(ply)
	if not IsValid(ply) then return end

	if not ply.PS_HasLoadedData then
		timer.Simple(1, function()
			if not IsValid(ply) then return end

			if not loadChecks[ply:SteamID64()] then
				loadChecks[ply:SteamID64()] = 0
			end

			loadChecks[ply:SteamID64()] = loadChecks[ply:SteamID64()] + 1

			if loadChecks[ply:SteamID64()] > 5 then
				gmcore.print(string.format("[PS Lottery] Failed to load %s (%s) items after 5 attempts", ply:Nick(), ply:SteamID64()))

				return
			end -- After 5 attempts we're no longer going to try

			self:CheckUnclaimedWinnings(ply)
		end)

		return
	end

	if self.UnclaimedLotteryWinningsMapping[ply:SteamID64()] then
		for _, winningMapping in pairs(self.UnclaimedLotteryWinningsMapping[ply:SteamID64()]) do
			if not self.UnclaimedLotteryWinnings[winningMapping] then continue end

			local winningTable = self.UnclaimedLotteryWinnings[winningMapping]

			local updateClaimedQuery = gmcore.Database:prepare("UPDATE lottery_history SET is_claimed = 1 WHERE id = ?")

			function updateClaimedQuery:onSuccess()
				ply:PS_GivePoints(tonumber(winningTable["jackpot_won"]))
				table.remove(PS.UnclaimedLotteryWinnings, winningMapping)

				gmcore.chatprintAll(Color(0, 255, 0), ply:Nick(), Color(255, 255, 255), " won ", Color(0, 255, 0), string.Comma(winningTable["jackpot_won"]), Color(255, 255, 255), " points from the lottery on ", Color(0, 255, 0), os.date("%m/%d/%Y", winningTable["date_won"]), Color(255, 255, 255), "!")
				BroadcastLua([[surface.PlaySound("garrysmod/save_load1.wav")]])
			end

			updateClaimedQuery:setNumber(1, winningTable["id"])
			updateClaimedQuery:start()
		end
	end
end

hook.Add("PlayerInitialSpawn", "gmcore.Pointshop.FetchTicketHistory", function(ply)
	if not PS.UnclaimedLotteryWinnings then
		PS:FetchTicketHistory(ply) -- Since this is only run once on mapchange, it'll call CheckUnclaimedWinning func

		return
	end

	PS:CheckUnclaimedWinnings(ply)
end)

local forumsBaseUrl = gmcore.Config:GetForumsBaseUrl()
local baseUrl = forumsBaseUrl or "localhost:8080"
SetGlobalString("gmcore.Pointshop.LotteryBaseUrl", baseUrl)
