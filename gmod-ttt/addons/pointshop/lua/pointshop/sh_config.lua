---@class PSConfig
---@field DataProvider string Data provider name ("ttt")
---@field ShopKey string Key to open the shop ("F1"-"F4" or blank)
---@field ShopCommand string Console command to open shop (blank to disable)
---@field ShopChatCommand string Chat command to open shop (blank to disable)
---@field NotifyOnJoin boolean Notify players about the shop on spawn
---@field PointsOverTime boolean Award points over time
---@field PointsOverTimeDelay number Minutes between point awards
---@field PointsOverTimeAmount number Points awarded each interval
---@field AdminCanAccessAdminTab boolean Admins can access the admin tab
---@field SuperAdminCanAccessAdminTab boolean SuperAdmins can access the admin tab
---@field CanPlayersGivePoints boolean Allow players to send points to others
---@field PointsName string Display name for points
---@field WebUiBaseUrl string Base URL for the pointshop web UI (ex: "https://website.com")
---@field WebUiVersion string URL version segment for the web UI release (ex: "2026-02-19")
---@field CalculateBuyPrice fun(ply: Player, item: PSItem): number Calculate buy price for an item
---@field CalculateUpgradePrice fun(ply: Player, item: PSItem): number Calculate upgrade price for an item
---@field CalculateSellPrice fun(ply: Player, item: PSItem): number Calculate sell price for an item
---@type PSConfig
PS.Config = {}

-- Edit below

PS.Config.DataProvider = "ttt"

PS.Config.ShopKey = "F3" -- F1, F2, F3 or F4, or blank to disable
PS.Config.ShopCommand = "" -- Console command to open the shop, set to blank to disable
PS.Config.ShopChatCommand = "" -- Chat command to open the shop, set to blank to disable

PS.Config.NotifyOnJoin = true -- Should players be notified about opening the shop when they spawn?

PS.Config.PointsOverTime = true -- Should players be given points over time?
PS.Config.PointsOverTimeDelay = 2 -- If so, how many minutes apart?
PS.Config.PointsOverTimeAmount = 20 -- And if so, how many points to give after the time?

PS.Config.AdminCanAccessAdminTab = true -- Can Admins access the Admin tab?
PS.Config.SuperAdminCanAccessAdminTab = true -- Can SuperAdmins access the Admin tab?

PS.Config.CanPlayersGivePoints = true -- Can players give points away to other players?

PS.Config.PointsName = "Points" -- What are the points called?

-- Web UI settings (served from website, versioned by URL path). Use WebUiVersion "dev" for local dev.
-- For local testing, build with vite using version "dev" and set WebUiVersion to "dev". Don't forget
-- to bump to new version when done.
-- Builds: <base>/pointshop/<version>/index.html
-- Example:
-- PS.Config.WebUiBaseUrl = "https://website.com"
-- PS.Config.WebUiVersion = "1.0.3"
PS.Config.WebUiBaseUrl = GetGlobalString("gmcore.ForumsBaseUrl", "") or "https://website.com"
PS.Config.WebUiVersion = "1.0.0"

-- Edit below if you know what you"re doing

---Calculates the buy price of an item, factoring in store rank discounts.
---@param ply Player The player buying the item
---@param item PSItem The item being purchased
---@return number The final buy price after store rank discounts
PS.Config.CalculateBuyPrice = function(ply, item)
	-- You can do different calculations here to return how much an item should cost to buy.
	-- There are a few examples below, uncomment them to use them.

	-- Everything half price for admins:
	-- if ply:IsAdmin() then return math.Round(item.Price * 0.5) end

	if ply:GetStoreRank() == 1 then return math.Round(item.Price * 0.75) end -- 25% off
	if ply:GetStoreRank() == 2 then return math.Round(item.Price * 0.50) end -- 50% off
	if ply:GetStoreRank() == 5 then return math.Round(item.Price * 0.30) end -- 70% off

	return item.Price
end

---Calculates the upgrade price of an item based on current upgrade level and store rank.
---@param ply Player The player upgrading the item
---@param item PSItem The item being upgraded
---@return number The final upgrade price after store rank discounts
PS.Config.CalculateUpgradePrice = function(ply, item)
	local level = ply:PS_GetUpgradeLevel(item.ID)
	local price = item.UpgradeList[level + 1]

	if ply:GetStoreRank() == 1 then return math.Round(price * 0.90) end -- 10% off
	if ply:GetStoreRank() == 2 then return math.Round(price * 0.75) end -- 25% off
	if ply:GetStoreRank() == 5 then return math.Round(price * 0.60) end -- 40% off

	return price
end

---Calculates the sell price of an item (75% of buy price, modified by store rank).
---@param ply Player The player selling the item
---@param item PSItem The item being sold
---@return number The sell price (75% of buy price, adjusted by store rank)
PS.Config.CalculateSellPrice = function(ply, item)
	if ply:GetStoreRank() == 1 then return math.Round(item.Price * 0.75 * 0.75) end
	if ply:GetStoreRank() == 2 then return math.Round(item.Price * 0.5 * 0.75) end
	if ply:GetStoreRank() == 3 or ply:GetStoreRank() == 4 or ply:GetStoreRank() == 5 then return math.Round(item.Price * 0.30 * 0.75) end

	return math.Round(item.Price * 0.75) -- 75% or 3/4 (rounded) of the original item price
end
