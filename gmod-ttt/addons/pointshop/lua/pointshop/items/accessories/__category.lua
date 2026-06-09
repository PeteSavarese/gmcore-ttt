---@class PSCategory
---@field Name string Display name of the category
---@field Icon string Icon filename (without extension) from vgui materials
---@field Order number Sort order in the shop nav bar
---@field AllowedEquipped number Max equipped items (-1 for unlimited)
---@field Custom string Custom tab type identifier
---@field AllowedUserGroups? string[] Usergroups allowed to access this category
---@field SharedCategories? string[] Categories sharing equip limits
---@field CanPlayerSee? fun(self: PSCategory, ply: Player): boolean
if CATEGORY == nil then
	CATEGORY = {}
end

local cat_name = "Accessories"
CATEGORY.Name = cat_name
CATEGORY.Icon = "wizard-hat-solid"
CATEGORY.Order = 100
CATEGORY.AllowedEquipped = 1
