surface.CreateFont("gmcore.HUDPaint.HealthAmmo", {
	font = "Biko",
	size = 24,
	weight = 750 -- Bold
})

surface.CreateFont("gmcore.Deathcard.DNAFound", {
	font = "Biko",
	size = 20,
	weight = 300 -- Bold
})

---@class gmcoreDeathcardPanel : Panel
local PANEL = {}

-- TODO: Have names in all ent files
local entClassToName = {
	["ttt_firegrenade_proj"] = "Incendiary Grenade",
	["env_fire"] = "Incendiary Grenade",
	["ttt_death_station"] = "Death Station",
	["ttt_harpoon"] = "Harpoon",
	["ttt_tripmine"] = "Tripmine",
	["ttt_teargas_proj"] = "Tear Gas",
	["ttt_boogie_bomb_proj"] = "Boogie Bomb"
}

---@param entClass Entity The entity to resolve a display name for
---@return string name The display name of the entity, or "Misc." if unknown
local function entToName(entClass)
	if !entClass then return "Misc." end
	if entClass == nil or entClass == NULL then return "Misc." end
	if entClass:IsWeapon() then return entClass:GetPrintName() end
	if !entClass:GetClass() or entClass:GetClass() == nil or entClass:GetClass() == NULL then print("[DMSG] Attempted to get class for null entity/panel: " .. entClass) return "Misc." end

	return entClassToName[entClass:GetClass()] or "Misc."
end

---@param x number The x position of the bar
---@param y number The y position of the bar
---@param width number The total width of the bar background
---@param height number The height of the bar
---@param tColorTableRef Color[] The border and fill colors for the bar
---@param meterWidth number The filled portion width of the meter
---@param meterText string|number The text or value displayed on the meter
---@param eTextAlign? number
local function paintMeteredBar(x, y, width, height, tColorTableRef, meterWidth, meterText, eTextAlign)
	if !tColorTableRef or tColorTableRef == nil or type(tColorTableRef) != "table" then return end -- A whole wahck ton of checks to insure no HUDPaint errors
	eTextAlign = eTextAlign or TEXT_ALIGN_CENTER

	surface.SetDrawColor(tColorTableRef[1])
	surface.DrawRect(x - 1, y - 1, width + 2, height + 2)

	-- Draw background of meter
	surface.SetDrawColor(tColorTableRef[2])
	surface.DrawRect(x, y, meterWidth, height)

	surface.SetFont("gmcore.HUDPaint.HealthAmmo")

	local iTextW, iTextH = surface.GetTextSize(meterText)
	draw.SimpleText(meterText, "gmcore.HUDPaint.HealthAmmo", x + 5, y, color_white, eTextAlign)
end

PANEL.DamageTypeInfo = {
	[0] = {"Innocent", Color(33, 177, 33), Color(27, 146, 27)},
	[1] = {"Traitor", Color(226, 43, 43), Color(178, 34, 34)},
	[2] = {"Detective", Color(9, 101, 203), Color(14, 69, 148)},
	[3] = {"Ghost DM", Color(255, 127, 39), Color(211, 98, 20)},
	[4] = {"Spectator", Color(146, 146, 26), Color(122, 122, 21)},
	[5] = {"Suicide", Color(204, 204, 0), Color(180, 180, 0)}
}

surface.CreateFont("gmcore.Deathcard.AttackerHeader", {
	font = "Biko",
	size = 38
})

surface.CreateFont("gmcore.Deathcard.AttackerRole", {
	font = "Biko",
	size = 50
})

surface.CreateFont("gmcore.Deathcard.DmgInfo", {
	font = "Biko",
	size = 20,
})

local GRADIENT = Material("vgui/gradient-d")

function PANEL:DrawAttackerInfo()
	if !self.attacker then return end

	self.attackerAvatar = vgui.Create("AvatarImage", self)
	self.attackerAvatar:SetSize(128, 128)
	self.attackerAvatar:SetPos(10, 60)

	if !self.isSuicide and self.attacker:IsPlayer() then
		self.attackerAvatar:SetPlayer(self.attacker, 128)
	else
		self.attackerAvatar:SetPlayer(LocalPlayer(), 128)
	end


	self.attackerLbl = vgui.Create("DLabel", self)

	if !self.isSuicide and self.attacker:IsPlayer() then
		self.attackerLbl:SetText(self.attacker:Nick())
	else
		self.attackerLbl:SetText("Killed in Action")
	end

	self.attackerLbl:SetFont("gmcore.Deathcard.AttackerHeader")
	self.attackerLbl:SizeToContents()
	self.attackerLbl:SetPos(10, (50 / 2) - self.attackerLbl:GetTall() / 2)

	self.attackerRoleLbl = vgui.Create("DLabel", self)

	if self.isSuicide or !self.attacker:IsPlayer() then
		-- Suicide
		self.attackerRoleLbl:SetText(self.DamageTypeInfo[5][1])
		self.attackerRoleLbl:SetTextColor(self.DamageTypeInfo[5][2])
	else
		-- DRAW WEAPON INFO
		self.weaponName = vgui.Create("DLabel", self)
		self.weaponName:SetText(self.attackerDmgInfo and LANG.TryTranslation(entToName(self.attackerDmgInfo.wep)) or "Misc.")
		self.weaponName:SetFont("gmcore.Deathcard.DmgInfo")
		self.weaponName:SizeToContents()

		self.weaponModelPreview = vgui.Create("DModelPanel", self)
		self.weaponModelPreview:SetSize(235, self.attackerAvatar:GetTall() * 0.65)
		self.weaponModelPreview:SetPos(self:GetWide() - self.weaponModelPreview:GetWide() - 10, self.attackerAvatar.y + (self.weaponModelPreview:GetTall() / 2))
		self.weaponModelPreview:SetModel((self.attackerDmgInfo != nil and IsValid(self.attackerDmgInfo.wep)) and self.attackerDmgInfo.wep:GetModel() or "models/weapons/w_crowbar.mdl")
		self.weaponModelPreview.LayoutEntity = function() end -- Disable rotation

		local PrevMins, PrevMaxs = self.weaponModelPreview.Entity:GetRenderBounds()
		self.weaponModelPreview:SetCamPos(PrevMins:Distance(PrevMaxs) * Vector(0.30, 0.30, 0.25) + Vector(10, 10, 25))
		self.weaponModelPreview:SetLookAt((PrevMaxs + PrevMins) / 2)
		self.weaponModelPreview:Show()

		-- SET ROLE TEXT
		if self.attacker:IsGhost() then
			-- Player is in GhostDM
			self.attackerRoleLbl:SetText(self.DamageTypeInfo[3][1])
			self.attackerRoleLbl:SetTextColor(self.DamageTypeInfo[3][2])
		else
			-- Regular TTT Role
			self.attackerRoleLbl:SetText(self.DamageTypeInfo[self.attackerRole][1])
			self.attackerRoleLbl:SetTextColor(self.DamageTypeInfo[self.attackerRole][2])
		end

		-- SET DAMAGE INFO
		if self.attackerDmgInfo != nil then
			self.receivedDmgInfo = vgui.Create("DLabel", self)
			self.receivedDmgInfo:SetText("Damage Received: " .. self.attackerDmgInfo.dmg .. " in " .. self.attackerDmgInfo.hits .. " hit" .. (self.attackerDmgInfo.hits > 1 and "s" or ""))
			self.receivedDmgInfo:SetFont("gmcore.Deathcard.DmgInfo")
			self.receivedDmgInfo:SizeToContents()
			self.receivedDmgInfo:SetPos(10, self.attackerAvatar.y + self.attackerAvatar:GetTall() + 5)
		end

		if self.victimDmgInfo != nil then
			self.givenDmgInfo = vgui.Create("DLabel", self)
			self.givenDmgInfo:SetText("Damage Given: " .. self.victimDmgInfo.dmg .. " in " .. self.victimDmgInfo.hits .. " hit" .. (self.victimDmgInfo.hits > 1 and "s" or ""))
			self.givenDmgInfo:SetFont("gmcore.Deathcard.DmgInfo")
			self.givenDmgInfo:SizeToContents()

			if self.receivedDmgInfo then
				self.givenDmgInfo:SetPos(10, self.receivedDmgInfo.y + self.receivedDmgInfo:GetTall() + 5)
			else
				self.givenDmgInfo:SetPos(10, self.attackerAvatar.y + self.attackerAvatar:GetTall() + 5)
			end
		end
	end

	self.attackerRoleLbl:SetFont("gmcore.Deathcard.AttackerRole")
	self.attackerRoleLbl:SizeToContents()
	self.attackerRoleLbl:SetPos(self.attackerAvatar.x + self.attackerAvatar:GetWide() + 10, self.attackerAvatar.y)

	if self.weaponName then
		self.weaponName:SetPos(self.weaponModelPreview.x + (self.weaponModelPreview:GetWide() / 2) - (self.weaponName:GetWide() / 2), self.attackerRoleLbl.y + self.attackerRoleLbl:GetTall() / 2)
		self.weaponModelPreview:SetPos(self.weaponModelPreview.x, self.weaponName.y + self.weaponName:GetTall() + 5)
	end
end

function PANEL:DrawDeathInfo()

end

local DNA_ICON = Material("VGUI/ttt/icon_wtester")

function PANEL:Paint(w, h)
	-- Main background
	surface.SetDrawColor(48, 48, 48)
	surface.DrawRect(0, 50, w, h - 50)

	-- Header blue bar
	surface.SetDrawColor(COMMUNITY_PRIMARY_COLOR)
	surface.DrawRect(0, 0, w, 50)

	surface.SetDrawColor(51, 51, 51, 200)
	surface.SetMaterial(GRADIENT)
	surface.DrawTexturedRect(0, 0, w, 50)

	-- Attacker health
	if !self.isSuicide and self.attacker:IsPlayer() then
		local width = 150
		local height = 25

		local meterWidth = width * math.Clamp(self.attackerHealth / 100, 0, 1)
		paintMeteredBar(self.attackerRoleLbl.x, self.attackerAvatar.y + self.attackerAvatar:GetTall() - height, width, height, {Color(100, 25, 25, 255), Color(200, 50, 50, 250)}, meterWidth, self.attackerHealth, TEXT_ALIGN_LEFT)
	end

	-- DNA Icon
	if self.dnaFound then
		surface.SetDrawColor(color_white)
		surface.SetMaterial(DNA_ICON)
		surface.DrawTexturedRect(self.attackerRoleLbl.x, self.attackerRoleLbl.y + self.attackerRoleLbl:GetTall(), 40, 40)

		surface.SetFont("gmcore.Deathcard.DNAFound")

		local _, textH = surface.GetTextSize("DNA Found")

		surface.SetTextColor(color_white)
		surface.SetTextPos(self.attackerRoleLbl.x + 40 + 5, self.attackerRoleLbl.y + self.attackerRoleLbl:GetTall() + 40 - textH)
		surface.DrawText("DNA Found")
	end
end

---@param attacker Entity The entity that killed the player
---@param role number The TTT role index of the attacker
---@param dmginfo table The damage info containing attacker and victim damage data
---@param dnaFound boolean Whether DNA evidence was found on the victim
function PANEL:SetInfo(attacker, role, dmginfo, dnaFound)
	self.attacker = attacker
	self.attackerRole = role
	self.attackerHealth = IsValid(attacker) and math.Round(attacker:Health()) or 0
	self.attackerDmgInfo = dmginfo.AttackerDmg.dmg != nil and dmginfo.AttackerDmg or nil
	self.victimDmgInfo = dmginfo.VictimDamage.dmg != nil and dmginfo.VictimDamage or nil
	self.isSuicide = attacker == LocalPlayer()
	self.dnaFound = dnaFound

	if attacker:IsPlayer() then
		self:DrawAttackerInfo()
	else
		self:DrawDeathInfo()
	end

	self:DrawAttackerInfo()
end

vgui.Register("GmcoreDeathcardPanel", PANEL, "Panel")
