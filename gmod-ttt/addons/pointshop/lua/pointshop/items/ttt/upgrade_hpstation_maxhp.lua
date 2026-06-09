ITEM.Name = "Health Station Max"
ITEM.Price = 1200
ITEM.Material = "vgui/ttt/icon_health"
ITEM.OneUse = true
ITEM.Section = 0
ITEM.Description = "Increase max charge your health station can hold by 20hp on each upgrade."

ITEM.UpgradeList = {}
ITEM.UpgradeList[1] = 1200
ITEM.UpgradeList[2] = 1800
ITEM.UpgradeList[3] = 2000
ITEM.UpgradeList[4] = 3500
ITEM.UpgradeList[5] = 5500


function ITEM:OnBuy(ply)

end

function ITEM:OnUpgrade(ply)

end

function ITEM:OnEquip(ply, modifications)

end

function ITEM:OnHolster(ply)

end
