ITEM.Name = "Detective"
ITEM.Price = 300
ITEM.Material = "vgui/ttt/icon_det.png"
ITEM.OneUse = true
ITEM.KeepOnDeath = true
ITEM.Section = "Round Roles"
ITEM.Description = "Sherlock Holmes here! Become a detective whenever you have this equipped."

function ITEM:OnEquip(ply, modifications)
	gmcore.chatprint(ply, "Detective round equipped! It will take effect at the start of the next round")

	if SERVER then
		---@cast ply Player
		hook.Add("SelectRoles", ply:UniqueID() .. "_detective", function()
			if !IsValid(ply) then return end -- Player left before round began
			if ply:GetSlayCount() > 0 then gmcore.chatprint(ply, "Your Detective round wasn't applied since you were slain") return end

			if ply:GetRole() == ROLE_DETECTIVE then
				gmcore.chatprint(ply, "You are already a Detective! You will receive Detective next round")
			elseif ply:GetRole() == ROLE_TRAITOR then
				gmcore.chatprint(ply, "You are a Traitor! You will receive Detective next round")
			else
				ply:SetRole(ROLE_DETECTIVE)
				--ply:SetDefaultCredits()
				--GAMEMODE.LastRole[ply:SteamID()] = ply:GetRole()
				ply:PS_TakeItem(self.ID)

				hook.Remove("SelectRolesSelected", ply:UniqueID() .. "_detective")
				hook.Remove("SelectRoles", ply:UniqueID() .. "_detective")

				ply.HasBoughtD = true

				hook.Run("glPointshopPlayerBoughtRole", ply, ROLE_DETECTIVE)
			end

			hook.Remove("TTTBeginRound", ply:UniqueID() .. "_detective")
		end)
	end
end

function ITEM:OnHolster(ply)
	hook.Remove("SelectRolesSelected", ply:UniqueID() .. "_detective")
	hook.Remove("SelectRoles", ply:UniqueID() .. "_detective")
end

function ITEM:OnSell(ply)
	hook.Remove("SelectRolesSelected", ply:UniqueID() .. "_detective")
	hook.Remove("SelectRoles", ply:UniqueID() .. "_detective")
end

if SERVER then
	hook.Add("TTTBeginRound", "gmcore.InventoryShop.BroadcastBoughtDRound", function()
		timer.Simple(0.1, function()
			local iPlysBoughtRound = 0

			for _, ply in ipairs(player.GetAll()) do
				if ply.HasBoughtD then
					iPlysBoughtRound = iPlysBoughtRound + 1
					ply.HasBoughtD = false
				end
			end

			if iPlysBoughtRound > 0 then
				gmcore.chatprintAll(iPlysBoughtRound .. " player(s) bought", Color(0, 100, 200), " detective ", color_white, "this round")
			end
		end)
	end)
end
