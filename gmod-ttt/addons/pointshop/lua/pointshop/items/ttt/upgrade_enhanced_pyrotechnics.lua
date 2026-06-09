ITEM.Name = "Enhanced Pyrotechnics"
ITEM.Price = 4000
ITEM.Material = "vgui/ttt/icon_flare"
ITEM.Section = 0
ITEM.Description = "Levels 1 and 2 make flare gun flames last longer. Levels 3 and 4 make them more damaging"

ITEM.UpgradeList = {}
ITEM.UpgradeList[1] = 4000
ITEM.UpgradeList[2] = 5000
ITEM.UpgradeList[3] = 7000
ITEM.UpgradeList[4] = 8000


function ITEM:OnBuy(ply)

end

function ITEM:OnUpgrade(ply)

end

function ITEM:OnEquip(ply, modifications)

end

function ITEM:OnHolster(ply)

end
