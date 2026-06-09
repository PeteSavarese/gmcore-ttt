ITEM.Name = "Traitor"
ITEM.Price = 625
ITEM.Material = "vgui/ttt/icon_traitor.png"
ITEM.OneUse = true
ITEM.KeepOnDeath = true
ITEM.Section = "Round Roles"
ITEM.Description = "Need revenge on someone? Become a Traitor whenever you have this equipped. ONE USE PER MAP"

local boughtRound = {}

function ITEM:OnEquip(ply, modifications)
	if boughtRound[ply:SteamID()] == true then
		ply:PS_HolsterItem(self.ID)
		ply:PS_Notify("Traitor can only be purchased once a map.")
	else
		gmcore.chatprint(ply, "Traitor round equipped! It will take effect at the start of the next round")

		if SERVER then
			hook.Add("SelectRolesSelected", ply:UniqueID() .. "_traitor", function(ply2, role)
				if ply == ply2 and role == ROLE_DETECTIVE then
					return false
				end
			end)

			---@cast ply Player
			hook.Add("SelectRoles", ply:UniqueID() .. "_traitor", function()
				if !IsValid(ply) then return end -- Player left before round began
				if ply:GetSlayCount() > 0 then gmcore.chatprint(ply, "Your Traitor round wasn't applied since you were slain") return end

				if ply:GetRole() == ROLE_TRAITOR then
					gmcore.chatprint(ply, "You are already a Traitor! You will receive Traitor next round")
				else
					ply:SetRole(ROLE_TRAITOR)
					ply:SetDefaultCredits()
					GAMEMODE.LastRole[ply:SteamID()] = ply:GetRole()
					ply:PS_TakeItem(self.ID)

					gmcore.chatprint(ply, "Forced Traitor. Have fun!")

					ply.HasBoughtT = true
					boughtRound[ply:SteamID()] = true

					hook.Run("glPointshopPlayerBoughtRole", ply, ROLE_TRAITOR)
				end

				hook.Remove("SelectRolesSelected", ply:UniqueID() .. "_traitor")
				hook.Remove("SelectRoles", ply:UniqueID() .. "_traitor")
			end)
		end
	end
end

function ITEM:OnHolster(ply)
	hook.Remove("SelectRolesSelected", ply:UniqueID() .. "_traitor")
	hook.Remove("SelectRoles", ply:UniqueID() .. "_traitor")
end

function ITEM:OnSell(ply)
	hook.Remove("SelectRolesSelected", ply:UniqueID() .. "_traitor")
	hook.Remove("SelectRoles", ply:UniqueID() .. "_traitor")
end

if SERVER then
	hook.Add("TTTBeginRound", "gmcore.InventoryShop.BroadcastBoughtTRound", function()
		timer.Simple(0.1, function()
			local iPlysBoughtRound = 0

			for _, ply in ipairs(player.GetAll()) do
				if ply.HasBoughtT then
					iPlysBoughtRound = iPlysBoughtRound + 1
					ply.HasBoughtT = false
				end
			end

			if iPlysBoughtRound > 0 then
				gmcore.chatprintAll(iPlysBoughtRound .. " player(s) bought", Color(255, 0, 0), " traitor ", color_white, "this round")
			end
		end)
	end)
end
