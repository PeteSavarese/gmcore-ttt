ITEM.Name = "Radar Speed"
ITEM.Price = 3000
ITEM.Material = "vgui/ttt/icon_radar"
ITEM.OneUse = true
ITEM.Section = 0
ITEM.Description = "Increase radar update speed by 4 seconds per upgrade."

ITEM.UpgradeList = {}
ITEM.UpgradeList[1] = 3000
ITEM.UpgradeList[2] = 4000
ITEM.UpgradeList[3] = 5000
ITEM.UpgradeList[4] = 8000
ITEM.UpgradeList[5] = 10000


function ITEM:OnBuy(ply)

end

function ITEM:OnUpgrade(ply)

end

function ITEM:OnEquip(ply, modifications)

end

function ITEM:OnHolster(ply)

end
