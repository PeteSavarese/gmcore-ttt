---@class gmcore.LoadoutCategory
---@field Rank number
---@field Items string[]
---@field Ammo number
---@field Exclude string[]

---@class gmcore.Loadout
---@field Categories table<string, gmcore.LoadoutCategory>
---@field localLoadout? table<string, string>
---@field GrenadeBaseItems string[]
gmcore.Loadout = gmcore.Loadout or {}

gmcore.Loadout.GrenadeBaseItems = {
	"weapon_ttt_confgrenade",
	"weapon_ttt_rev_confgrenade",
	"weapon_zm_molotov",
	"weapon_ttt_smokegrenade",
	"weapon_ttt_frag",
	-- "weapon_ttt_boogie_bomb"
}

gmcore.Loadout.Categories = {
	Primary = {
		Rank = 2,
		Items = {},
		Ammo = 3,
		Exclude = {"weapon_ttt_plogi", "weapon_ttt_sg550", "weapon_ttt_sl8_hack", "weapon_ttt_plogi_aa"}
	},
	Secondary = {
		Rank = 1,
		Items = {},
		Ammo = 2,
		Exclude = {}
	},
	Grenade = {
		Rank = 3,
		Items = {},
		Ammo = 0,
		Exclude = {}
	}
}

local function copyInto(dest, source)
	for i = 1, #source do
		dest[i] = source[i]
	end
end

---Reset category items to their defaults.
function gmcore.Loadout.ResetCategoryItems()
	gmcore.Loadout.Categories.Primary.Items = {}
	gmcore.Loadout.Categories.Secondary.Items = {}
	gmcore.Loadout.Categories.Grenade.Items = {}

	copyInto(gmcore.Loadout.Categories.Grenade.Items, gmcore.Loadout.GrenadeBaseItems)
end

---Normalize loadout selections.
---@param selection string
---@return string
function gmcore.Loadout.NormalizeSelection(selection)
	if not selection then return "" end
	if string.lower(selection) == "random" then
		return "random"
	end

	return selection
end

---Return a friendly label for a loadout slot given key.
---@param slot string Slot key (e.g. "Primary", "Secondary", "Grenade")
---@return string Friendly label for the slot (e.g. "Primary", "Secondary", "Grenade")
function gmcore.Loadout.GetSlotLabel(slot)
	if slot == "Primary" then return "Primary" end
	if slot == "Secondary" then return "Secondary" end
	if slot == "Grenade" then return "Grenade" end

	return string.upper(string.sub(slot, 1, 1)) .. string.sub(slot, 2)
end

---Adds random selection option if missing.
---@param items string[]
local function addRandomOption(items)
	for _, value in ipairs(items) do
		if string.lower(value) == "random" then
			return
		end
	end

	table.insert(items, 1, "random")
end

---Build weapon list for each category.
function gmcore.Loadout.BuildWeaponList()
	if not weapons or not weapons.GetList then return end
	if #weapons.GetList() <= 0 then return end

	gmcore.Loadout.ResetCategoryItems()
	addRandomOption(gmcore.Loadout.Categories.Primary.Items)
	addRandomOption(gmcore.Loadout.Categories.Secondary.Items)
	addRandomOption(gmcore.Loadout.Categories.Grenade.Items)

	local tWepTable = weapons.GetList()
	table.SortByMember(tWepTable, "PrintName", function(a, b) return a > b end)

	for _, weapon in pairs(tWepTable) do
		if not weapon or not weapon.ClassName then continue end

		local className = weapon.ClassName
		local lowerClass = string.lower(className)
		if string.find(lowerClass, "funround", 1, true) then continue end
		if string.find(lowerClass, "ghost", 1, true) then continue end
		if weapon.CanBuy then continue end

		if weapon.Kind == WEAPON_HEAVY then
			if table.HasValue(gmcore.Loadout.Categories.Primary.Exclude, className) then continue end
			table.insert(gmcore.Loadout.Categories.Primary.Items, className)
		elseif weapon.Kind == WEAPON_PISTOL then
			if table.HasValue(gmcore.Loadout.Categories.Secondary.Exclude, className) then continue end
			table.insert(gmcore.Loadout.Categories.Secondary.Items, className)
		end
	end

	if SERVER then
		hook.Call("gmcore.Loadout.ConfigReady")
	end
end

function gmcore.Loadout.HasAccess(ply, iRank)
	if gmcore.StoreRank then
		return tonumber(ply:GetStoreRank()) >= tonumber(iRank)
	end

	return false
end

local nameCorrection = { -- TTT likes to be inconsistent with it's names
	--[[ Weapon Names --]]
	["rifle_name"] = "Rifle",
	["shotgun_name"] = "Shotgun",
	["pistol_name"] = "Pistol",

	--[[ Grenade Names --]]
	["confgrenade_name"] = "Discombobulator",
	["grenade_smoke"] = "Smoke Grenade",
	["grenade_fire"] = "Incendiary Grenade"
}

---Return loadout data the web UI in Lua table format.
---@return table
function gmcore.Loadout.GetWebLoadoutData()
	if not CLIENT then return {} end

	local data = {}
	local loadout = gmcore.Loadout.localLoadout or {}

	local function buildSlotData(slot, cat)
		local weaponsList = {}
		for _, className in ipairs(cat.Items) do
			if string.lower(className) == "random" then continue end

			local swep = weapons.Get(className)
			local displayName = className
			if swep and swep.PrintName and swep.PrintName ~= "" then
				displayName = swep.PrintName
			end

			if nameCorrection[displayName] then
				displayName = nameCorrection[displayName]
			end

			table.insert(weaponsList, {
				class = className,
				name = displayName,
				model = (swep and (swep.WorldModel or swep.Model)) or nil
			})
		end

		local rankName = tostring(cat.Rank or 0)
		if gmcore.StoreRank and gmcore.StoreRank.Ranks and gmcore.StoreRank.Ranks[tonumber(cat.Rank or 0)] then
			rankName = gmcore.StoreRank.Ranks[tonumber(cat.Rank or 0)].name or rankName
		end

		table.insert(data, {
			kind = slot,
			label = gmcore.Loadout.GetSlotLabel(slot),
			rankRequired = cat.Rank or 0,
			rankName = rankName,
			weapons = weaponsList,
			selected = gmcore.Loadout.NormalizeSelection(loadout[slot] or "random")
		})
	end

	local preferredOrder = {"Secondary", "Primary", "Grenade"}
	local usedSlots = {}

	for _, slot in ipairs(preferredOrder) do
		local cat = gmcore.Loadout.Categories[slot]
		if cat then
			usedSlots[slot] = true
			buildSlotData(slot, cat)
		end
	end

	for slot, cat in SortedPairs(gmcore.Loadout.Categories, false) do
		if not usedSlots[slot] then
			buildSlotData(slot, cat)
		end
	end

	local ply = LocalPlayer()
	local playerRank = (IsValid(ply) and ply.GetStoreRank and ply:GetStoreRank()) or 0

	return {
		slots = data,
		playerRank = tonumber(playerRank) or 0
	}
end

---Return a snapshot of the current loadout config for network sync.
---@return table
function gmcore.Loadout.GetConfigSnapshot()
	local snapshot = {}

	for name, cat in pairs(gmcore.Loadout.Categories) do
		snapshot[name] = {
			Rank = cat.Rank or 0,
			Ammo = cat.Ammo or 0,
			Items = table.Copy(cat.Items or {}),
			exclude = table.Copy(cat.Exclude or {})
		}
	end

	return snapshot
end

---Apply loadout config received from server.
---@param snapshot table
function gmcore.Loadout.ApplyConfig(snapshot)
	if not snapshot then return end

	for name, cat in pairs(snapshot) do
		gmcore.Loadout.Categories[name] = gmcore.Loadout.Categories[name] or {}
		gmcore.Loadout.Categories[name].Rank = cat.Rank or 0
		gmcore.Loadout.Categories[name].Ammo = cat.Ammo or 0
		gmcore.Loadout.Categories[name].Items = cat.Items or {}
		gmcore.Loadout.Categories[name].Exclude = cat.exclude or {}
	end

	hook.Call("gmcore.Loadout.ConfigUpdated")
end

gmcore.Loadout.ResetCategoryItems()

timer.Remove("gmcore.Pointshop.Loadout.ServerUntilWeaponsInit")
timer.Create("gmcore.Pointshop.Loadout.ServerUntilWeaponsInit", 2, 0, function()
	if not weapons or not weapons.GetList then return end
	if #weapons.GetList() <= 0 then return end

	gmcore.Loadout.BuildWeaponList()
	timer.Remove("gmcore.Pointshop.Loadout.ServerUntilWeaponsInit")
end)
