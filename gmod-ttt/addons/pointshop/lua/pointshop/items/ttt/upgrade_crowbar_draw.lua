ITEM.Name = "Crowbar Speed"
ITEM.Price = 1000
ITEM.Material = "vgui/ttt/icon_cbar.png"
ITEM.OneUse = true
ITEM.Section = 0
ITEM.Description = "Increase crowbar hit speed by 10% with each level."

ITEM.UpgradeList = {}
ITEM.UpgradeList[1] = 1000
ITEM.UpgradeList[2] = 1500
ITEM.UpgradeList[3] = 2000
ITEM.UpgradeList[4] = 2500
ITEM.UpgradeList[5] = 3000


function ITEM:OnBuy(ply)
end

function ITEM:OnUpgrade(ply)
end

function ITEM:OnEquip(ply, modifications)
end

function ITEM:OnHolster(ply)
end
