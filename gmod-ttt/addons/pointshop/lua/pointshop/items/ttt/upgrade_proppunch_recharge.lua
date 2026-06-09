ITEM.Name = "Punch-O-Meter Boost"
ITEM.Price = 3000
ITEM.Material = "vgui/ttt/icon_skull"
ITEM.OneUse = true
ITEM.Section = 0
ITEM.Description = "Increases Punch-O-Meter recharge rate by 15% each level."

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