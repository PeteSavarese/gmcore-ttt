--[[
	pointshop/sh_init.lua
	first file included on both states.
]]--

---@alias CSModel Entity Clientside model entity created via ClientsideModel()

---@class PSItem
---@field ID string Unique item identifier (lowercase filename without .lua)
---@field Name string Display name of the item
---@field Price number Base price of the item in points
---@field Category string Category name this item belongs to
---@field Model string|nil 3D model path for the item
---@field Material string|nil Material path for the item
---@field Icon string|nil Icon identifier for the item
---@field Description string|nil Item description shown to players
---@field Bone string|nil Bone name for attachment (accessories)
---@field Section string|number|nil Section or rank requirement for the item
---@field Skin number|nil Model skin index
---@field AdminOnly boolean Whether item is admin-only
---@field AllowedUserGroups table List of user groups allowed to use this item
---@field SingleUse boolean Whether item is consumed on use
---@field NoPreview boolean Whether to hide preview in menu
---@field CanPlayerBuy boolean Whether players can buy this item
---@field CanPlayerSell boolean Whether players can sell this item
---@field CanPlayerEquip boolean Whether players can equip this item
---@field CanPlayerHolster boolean Whether players can holster this item
---@field Upgradable boolean|nil Whether item can be upgraded
---@field UpgradePrice number|nil Price to upgrade this item
---@field ModelPerk boolean Whether item provides a model/cosmetic perk
---@field HasClientEffect boolean Whether item has client-side effects
---@field IsRankColored boolean|nil Whether item is colored by rank (weapon skins)
---@field OnBuy fun(ITEM: PSItem, ply: Player) Callback when item is purchased
---@field OnSell fun(ITEM: PSItem, ply: Player) Callback when item is sold
---@field OnEquip fun(ITEM: PSItem, ply: Player, modifications: table|nil) Callback when item is equipped
---@field OnHolster fun(ITEM: PSItem, ply: Player) Callback when item is holstered
---@field OnModify fun(ITEM: PSItem, ply: Player, modifications: table) Callback when item is modified
---@field ModifyClientsideModel fun(ITEM: PSItem, ply: Player, model: CSModel, pos: Vector, ang: Angle): CSModel, Vector, Angle Modify clientside model position/angle
---@field PlayerSetModel fun(ITEM: PSItem, ply: Player)|nil Callback for player model change (playermodels)
---@field PlayerSpawn fun(ITEM: PSItem, ply: Player)|nil Callback on player spawn
---@field CanPlayerUse fun(ITEM: PSItem, ply: Player): boolean|nil Check if player can use this item
---@field AllowSell boolean|nil Whether item can be sold back
---@field Class string|nil Weapon class name (for weapon items)
---@field ViewMaterials table|nil View model materials (weapon skins)
---@field WorldMaterials table|nil World model materials (weapon skins)
---@field ViewModel string|nil View model path (weapon skins)
---@field WorldModel string|nil World model path (weapon skins)
---@field Requirements table|nil Requirements table for item access
---@field Event string|nil Event name this item is associated with
---@field begin number|nil Event start timestamp (weapon skins)
---@field ["end"] number|nil Event end timestamp (weapon skins)

---@class PS
---@field Items table<string, PSItem> All registered pointshop items, keyed by item ID
---@field Categories table<string, PSCategory> All registered categories, keyed by folder name
---@field ClientsideModels table<Player, table<string, CSModel>> Clientside models per player per item ID
---@field Config PSConfig Configuration table
---@field DataProvider PSDataProvider Active data provider instance
---@field ShopMenu Panel|nil Client shop menu panel
---@field ReceivedInitialSpawnData boolean Whether client has received initial spawn data
---@field HoverModel string|nil Currently hovered item ID for preview
---@field HoverModelClientsideModel CSModel|nil Clientside model for the hovered item
---@field CurrentBuild number Current addon build number
---@field LatestBuild number Latest addon build number
---@field UnclaimedLotteryWinnings table[]|nil Unclaimed lottery winnings from database
---@field UnclaimedLotteryWinningsMapping table<string, number[]> SteamID64 to unclaimed winning indices
---@field SkinEventInfo table<string, table>|nil Event metadata for weapon skins
---@field weapon_skins_table table[]|nil Temporary table for loading weapon skins
PS = {}
PS.__index = PS

---@type table<string, PSItem>
PS.Items = {}
---@type table<string, PSCategory>
PS.Categories = {}
---@type table<Player, table<string, CSModel>>
PS.ClientsideModels = {}

---Applies default OnEquip, OnHolster, and PlayerSetModel callbacks to a playermodel item.
---@param item PSItem The playermodel item to apply default callbacks to
function PS:ApplyPlayermodelItemDefaults(item)
	if not item then return end

	local subMaterials = item.SubMaterials
	local function applySubMaterials(ent)
		if not subMaterials then return end
		if not IsValid(ent) or not ent.SetSubMaterial then return end

		for k, v in pairs(subMaterials) do
			if isnumber(k) and v then
				ent:SetSubMaterial(k - 1, v)
			end
		end
	end

	local bodyGroups = item.BodyGroups
	local function applyBodyGroups(ent)
		if not bodyGroups then return end
		if not IsValid(ent) or not ent.SetBodygroup then return end

		for k, v in pairs(bodyGroups) do
			if isnumber(k) and isnumber(v) then
				ent:SetBodygroup(k, v)
			end
		end
	end

	item.OnEquip = function(ITEM, ply, modifications)
		if not IsValid(ply) then return end
		if TEAM_SPECTATOR != nil and ply:Team() == TEAM_SPECTATOR then return end
		if TEAM_SPEC != nil and ply:Team() == TEAM_SPEC then return end
		if ply.Spectating then return end
		if ply.IsActiveDetective and ply:IsActiveDetective() then return end
		if not ITEM.Model then return end

		if not ply._OldModel then
			ply._OldModel = ply:GetModel()
		end

		-- Apply immediately if player has spawned, otherwise wait for spawn
		if ply:Alive() and ply:GetModel() then
			ply:SetModel(ITEM.Model)

			if ITEM.Skin != nil then
				ply:SetSkin(ITEM.Skin)
			end

			applySubMaterials(ply)
			applyBodyGroups(ply)
		else
			-- Player hasn't fully spawned yet
			timer.Simple(0.1, function()
				if not IsValid(ply) then return end
				if ply.IsActiveDetective and ply:IsActiveDetective() then return end

				ply:SetModel(ITEM.Model)

				if ITEM.Skin != nil then
					ply:SetSkin(ITEM.Skin)
				end

				applySubMaterials(ply)
				applyBodyGroups(ply)
			end)
		end
	end

	item.OnHolster = function(ITEM, ply)
		if not IsValid(ply) then return end
		if not ply:IsActive() then return end
		if ply.IsActiveDetective and ply:IsActiveDetective() then return end

		if ply._OldModel then
			ply:SetModel(ply._OldModel)
		end
	end

	item.PlayerSetModel = function(ITEM, ply)
		if not IsValid(ply) then return end
		if not ply:IsActive() then return end
		if ply.IsActiveDetective and ply:IsActiveDetective() then return end
		if not ITEM.Model then return end

		if gmcore and gmcore.FunRounds and gmcore.FunRounds.ActiveRound and gmcore.FunRounds.ChosenFunRound == "Infected" and ply:IsAlive() and ply:GetRole() == ROLE_TRAITOR then return end

		ply:SetModel(ITEM.Model)
		if ITEM.Skin != nil then
			ply:SetSkin(ITEM.Skin)
		end
		applySubMaterials(ply)
		applyBodyGroups(ply)
	end

	if subMaterials or bodyGroups then
		local oldModifyClientsideModel = item.ModifyClientsideModel
		item.ModifyClientsideModel = function(ITEM, ply, model, pos, ang)
			local newModel, newPos, newAng = oldModifyClientsideModel(ITEM, ply, model, pos, ang)
			local target = newModel or model
			applySubMaterials(target)
			applyBodyGroups(target)
			return newModel, newPos, newAng
		end
	end
end

---Registers a gamemode hook for a pointshop item callback function.
---@param item PSItem The item to register the hook for
---@param prop string Property name (hook event name)
---@param val any Property value (hook callback if function)
function PS:RegisterItemHook(item, prop, val)
	if type(val) == "function" then
		hook.Add(prop, "PS_Item_" .. item.Name .. "_" .. prop, function(...)
			for _, ply in pairs(player.GetAll()) do
				if ply:PS_HasItemEquipped(item.ID) then
					item[prop](item, ply, ply.PS_Items[item.ID].Modifiers, unpack({...}))
				end
			end
		end)
	end
end

include("sh_config.lua")
include("sh_player_extension.lua")

---Validates and clamps a points value to a non-negative number.
---@param points any The value to validate as a point amount
---@return number The validated non-negative point amount
function PS:ValidatePoints(points)
	if type(points) != "number" then return 0 end

	return points >= 0 and points or 0
end

-- Utils

---Finds a category table by its display name.
---@param cat_name string The display name of the category to find
---@return PSCategory|false The matching category table, or false if not found
function PS:FindCategoryByName(cat_name)
	for id, cat in pairs(self.Categories) do
		if cat.Name == cat_name then
			return cat
		end
	end

	return false
end

-- Initialization

---Initializes the pointshop, loading data provider (server) and items.
function PS:Initialize()
	if SERVER then self:LoadDataProvider() end

	self:LoadItems()
end

-- Loading

---Loads weapon skin items from a category's weapon_skins.lua file.
---@param category string Category folder name
---@param CATEGORY PSCategory Category table
function PS:LoadWeaponSkins(category, CATEGORY)
	local name = "weapon_skins.lua"

	if SERVER then
		AddCSLuaFile("pointshop/items/" .. category .. "/" .. name)
	end

	include("pointshop/items/" .. category .. "/" .. name)

	for _, skin in pairs(PS.weapon_skins_table) do
		ITEM = {}
		ITEM.__index = ITEM
		ITEM.ID = skin.ID
		ITEM.Category = CATEGORY.Name
		ITEM.Price = 0
		ITEM.AdminOnly = false
		ITEM.AllowedUserGroups = {}
		ITEM.SingleUse = false
		ITEM.NoPreview = false
		ITEM.CanPlayerBuy = active
		ITEM.CanPlayerSell = true
		ITEM.CanPlayerEquip = true
		ITEM.CanPlayerHolster = true
		ITEM.OnBuy = function() end
		ITEM.OnSell = function() end
		ITEM.OnEquip = function() end
		ITEM.OnHolster = function() end
		ITEM.OnModify = function() end
		ITEM.ModifyClientsideModel = function(ITEM, ply, model, pos, ang) return model, pos, ang end

		ITEM.begin = skin.Begin
		ITEM["end"] = skin["End"]
		ITEM.Name = skin.Name
		ITEM.Class = skin.Weapon
		ITEM.Price = skin.Price
		ITEM.Event = skin.Event
		ITEM.Requirements = skin.Requirements
		ITEM.ViewMaterials = skin.ViewMaterials
		ITEM.WorldMaterials = skin.WorldMaterials
		ITEM.ViewModel = skin.ViewModel
		ITEM.WorldModel = skin.WorldModel
		ITEM.IsRankColored = skin.IsRankColored or false
		ITEM.ModelPerk = ITEM.CosmeticPerk or false
		ITEM.HasClientEffect = ITEM.ClientEffect or false

		ITEM.Section = 0
		if skin.Requirements then
			for _, req in ipairs(skin.Requirements) do
				if req.type == "store_rank" then
					ITEM.Section = tonumber(req.value) or 0
				elseif req.type == "ulx_rank" and req.value == "member" then
					ITEM.Section = 0
				end
			end
		end

		if not ITEM.Name then
			ErrorNoHalt("[POINTSHOP] Weapon Skin missing name: " .. category .. "/" .. name .. "\n")
			continue
		elseif not ITEM.Price then
			ErrorNoHalt("[POINTSHOP] Weapon Skin missing price: " .. category .. "/" .. name .. "\n")
			continue
		end

		if ITEM.Model then
			util.PrecacheModel(ITEM.Model)
		end

		self.Items[ITEM.ID] = ITEM
		ITEM = nil
	end
end

---Discovers and loads all pointshop item categories and their items from the filesystem.
function PS:LoadItems()
	local _, dirs = file.Find("pointshop/items/*", "LUA")

	for _, category in pairs(dirs) do
		if category != "skins" then
			local f, _ = file.Find("pointshop/items/" .. category .. "/__category.lua", "LUA")

			if #f > 0 then
				CATEGORY = {}
				CATEGORY.Name = ""
				CATEGORY.Icon = ""
				CATEGORY.Order = 0
				CATEGORY.AllowedEquipped = -1
				CATEGORY.AllowedUserGroups = {}
				CATEGORY.CanPlayerSee = function() return true end
				CATEGORY.ModifyTab = function(tab) return end

				if SERVER then
					AddCSLuaFile("pointshop/items/" .. category .. "/__category.lua")
				end

				include("pointshop/items/" .. category .. "/__category.lua")

				if not PS.Categories[category] then
					PS.Categories[category] = CATEGORY
				end

				local files, _ = file.Find("pointshop/items/" .. category .. "/*.lua", "LUA")

				for _, name in pairs(files) do
					if name != "__category.lua" then
						if SERVER then
							AddCSLuaFile("pointshop/items/" .. category .. "/" .. name)
						end

						ITEM = {}
						ITEM.__index = ITEM
						ITEM.ID = string.gsub(string.lower(name), ".lua", "")
						ITEM.Category = CATEGORY.Name
						ITEM.Price = 0
						-- model and material are missing but there"s no way around it, there"s a check below anyway
						ITEM.AdminOnly = false
						ITEM.AllowedUserGroups = {} -- this will fail the #ITEM.AllowedUserGroups test and continue
						ITEM.SingleUse = false
						ITEM.NoPreview = false
						ITEM.CanPlayerBuy = true
						ITEM.CanPlayerSell = true
						ITEM.CanPlayerEquip = true
						ITEM.CanPlayerHolster = true
						ITEM.OnBuy = function() end
						ITEM.OnSell = function() end
						ITEM.OnEquip = function() end
						ITEM.OnHolster = function() end
						ITEM.OnModify = function() end
						ITEM.ModifyClientsideModel = function(ITEM, ply, model, pos, ang) return model, pos, ang end
						include("pointshop/items/" .. category .. "/" .. name)
						if category == "playermodels" then
							self:ApplyPlayermodelItemDefaults(ITEM)
						end
						ITEM.ModelPerk = ITEM.CosmeticPerk or false
						ITEM.HasClientEffect = ITEM.ClientEffect or false

						if not ITEM.Name then
							ErrorNoHalt("[POINTSHOP] Item missing name: " .. category .. "/" .. name .. "\n")
							continue
						elseif not ITEM.Price then
							ErrorNoHalt("[POINTSHOP] Item missing price: " .. category .. "/" .. name .. "\n")
							continue
						end

						-- precache
						if ITEM.Model then
							util.PrecacheModel(ITEM.Model)
						end

						-- item hooks
						local item = ITEM

						for prop, val in pairs(item) do
							-- although this hooks every function, it doesn"t matter because the non-hook functions will never get called
							self:RegisterItemHook(item, prop, val)
						end

						self.Items[ITEM.ID] = ITEM
						ITEM = nil
					end
				end

				CATEGORY = nil
			end
		else
			local f, _ = file.Find("pointshop/items/" .. category .. "/__category.lua", "LUA")

			if #f > 0 then
				CATEGORY = {}
				CATEGORY.Name = ""
				CATEGORY.Icon = ""
				CATEGORY.Order = 0
				CATEGORY.AllowedEquipped = -1
				CATEGORY.AllowedUserGroups = {}
				CATEGORY.CanPlayerSee = function() return true end
				CATEGORY.ModifyTab = function(tab) return end

				if SERVER then
					AddCSLuaFile("pointshop/items/" .. category .. "/__category.lua")
				end

				include("pointshop/items/" .. category .. "/__category.lua")

				if not PS.Categories[category] then
					PS.Categories[category] = CATEGORY
				end

				self:LoadWeaponSkins(category, CATEGORY)

				CATEGORY = nil
			end
		end
	end
end
