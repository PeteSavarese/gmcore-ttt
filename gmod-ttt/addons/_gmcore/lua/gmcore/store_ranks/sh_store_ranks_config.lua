---@class gmcore
---@field StoreRank gmcore.StoreRank Store rank system

---@class gmcore.StoreRank
---@field Ranks table<number, StoreRankInfo> Store rank definitions indexed by priority
---@field StorageFormat string Storage method for rank data (default: "pdata")
---@field SetStoreRankStatus fun(self: gmcore.StoreRank, ply: Player, newRankIndex: number) Set player's store rank
gmcore.StoreRank = gmcore.StoreRank or {}

---@class StoreRankInfo
---@field name string Display name of rank
---@field color Color Rank color
---@field vcount number Vote count multiplier for mapvote
---@field voiceBattery number Voice battery bonus

gmcore.StoreRank.Ranks = {}

gmcore.StoreRank.StorageFormat = "pdata" -- Forum rank sync will apply our rank on other servers along with CRON check for expiration. No need to setup another table for this

---Rank information. Index key is important as it also shows priority and is used for searching if the player is a certain rank or higher.
---@type table<number, StoreRankInfo>
gmcore.StoreRank.Ranks = {
	[1] = {name = "Supporter", color = Color(255, 255, 0), vcount = 2, voiceBattery = 0},
	[2] = {name = "VIP", color = Color(255, 0, 255), vcount = 2, voiceBattery = 0},
	[3] = {name = "VIP+", color = Color(0, 255, 0), vcount = 2, voiceBattery = 0},
	[4] = {name = "Elite", color = Color(70, 130, 180), vcount = 2, voiceBattery = 0},
	[5] = {name = "Legendary", color = Color(250, 128, 114), vcount = 4, voiceBattery = 0}
}


gmcore.print("Loaded store ranks config")
