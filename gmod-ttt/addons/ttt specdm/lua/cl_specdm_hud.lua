local table = table
local surface = surface
local draw = draw
local math = math
local string = string

local cSpecDMMain = Color(255, 127, 39, 100)

local healthRectColors = {
	border = COLOR_WHITE,
	background = Color(100, 25, 25, 255),
	fill = Color(200, 50, 50, 250)
}

local ammoRectColors = {
	border = COLOR_WHITE,
	background = Color(20, 20, 5, 222),
	fill = Color(205, 155, 0, 255)
}

local iMathApproachHealth = 0
local iMathApproachAmmo = 0

local function ShadowedText(text, font, x, y, color, xalign, yalign)
	draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
	draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

-- Returns player's ammo information
local function GetAmmo(ply)
	local weap = ply:GetActiveWeapon()
	if !weap or !ply:Alive() then return -1 end

	local ammo_inv = weap:Ammo1() or 0
	local ammo_clip = weap:Clip1() or 0
	local ammo_max = weap.Primary.ClipSize or 0

	return ammo_clip, ammo_max, ammo_inv
end

-- Paints a bar with a vlue, with a background color to show valuation/devaluation
-- Uses
local function paintMeteredBar(x, y, iWidth, iHeight, tColorTableRef, iMeterWidth, sText, eTextAlign)
	if !tColorTableRef or tColorTableRef == nil or type(tColorTableRef) ~= "table" then return end -- A whole wahck ton of checks to insure no HUDPaint errors
	eTextAlign = eTextAlign or TEXT_ALIGN_CENTER

	surface.SetDrawColor(tColorTableRef.background)
	surface.DrawRect(x - 1, y - 1, iWidth + 2, iHeight + 2)

	-- Draw background of meter
	surface.SetDrawColor(tColorTableRef.fill)
	surface.DrawRect(x, y, iMeterWidth, iHeight)


	surface.SetFont("gmcore.HUDPaint.HealthAmmo")

	local iTextW, iTextH = surface.GetTextSize(sText)
	ShadowedText(sText, "gmcore.HUDPaint.HealthAmmo", x + 10, y + iTextH / 2 - 5, color_white, eTextAlign)
end

-- These are actually scaled in 2560x1440 until i get scaling to work
-- Takes a number and returns what is the proper value for scaling to a display
-- Always insures an even number is returned for nice math calculation in HUD formatting
-- TODO: ACTUALLY DO SCALING
local function scaledFrom1080(iNumIn1080, bIsWidth)
	if ScrW() > 1 then return iNumIn1080 end

	local iPercOfVal
	local iRetrunVal

	if bIsWidth then -- Are we calculating the width or the height. Needed to determine which direction to scale in
		iPercOfVal = iNumIn1080 / 1920
		iReturnVal = iPercOfVal * ScrW()
	else
		iPercOfVal = iNumIn1080 / 1080
		iReturnVal = iPercOfVal * ScrH()
	end

	if iReturnVal % 2 ~= 0 then -- If we can't divide by 2 and aren't even, math calculation will be a pain in other parts.
		iRetrunVal = iReturnVal + 1 -- Insure an even number by just adding 1 to the odd number
	end

	return iReturnVal
end

local cBackgroundColor = FRAME_BACKGROUND_COLOR

-- All values listed below are in 1080
local iWidth = 334
local iHeight = 166
local iRoleStateBackground = 40
local iPanelPadding = 10 -- 10 px from left and 10 px from the bottom

hook.Add("Initialize", "Initialize_GhostHUD", function()
	local GetLang = LANG.GetUnsafeLanguageTable
	local old_DrawHUD = GAMEMODE.HUDPaint

	function GAMEMODE:HUDPaint()
		local ply = LocalPlayer()
		if !ply:IsGhost() then return old_DrawHUD(self) end

		self:HUDDrawTargetID()
		MSTACK:Draw(ply)
		TBHUD:Draw(ply)
		WSWITCH:Draw(ply)
		self:HUDDrawPickupHistory()


		local L = GetLang()
		local round_state = GAMEMODE.round_state
		local cRoleColor = cSpecDMMain
		cRoleColor.a = 255

		cTimeColor = cSpecDMMain
		local bIsHasteMode = HasteMode() and round_state == ROUND_ACTIVE
		local iRoundStateWidth = scaledFrom1080(iWidth) - scaledFrom1080(iWidth) * .25
		local fRoundTime = GetGlobalFloat("ttt_round_end", 0) - CurTime()
		local iHealth = math.max(0, ply:Health())
		local x = iPanelPadding
		local y = ScrH() - iPanelPadding - iHeight

		-- Draw grey background
		surface.SetDrawColor(cBackgroundColor)
		surface.DrawRect(x, y, scaledFrom1080(iWidth), scaledFrom1080(iHeight))

		-- Accent role coloring on border
		surface.SetDrawColor(cRoleColor)
		surface.DrawRect(x, y, 5, scaledFrom1080(iHeight))

		-- Role background color on top, where text is drawn ontop of this.
		surface.SetDrawColor(cRoleColor)
		surface.DrawRect(x, y, iRoundStateWidth, scaledFrom1080(iRoleStateBackground))

		-- Round timer, where text is drawn ontop of this
		surface.SetDrawColor(cBackgroundColor)
		surface.DrawRect(scaledFrom1080(iWidth) - scaledFrom1080(iWidth) * .25 + iPanelPadding + 1, y, scaledFrom1080(iWidth) * .25, scaledFrom1080(iRoleStateBackground))

		-- Paint health meter
		iMathApproachHealth = math.Approach(iMathApproachHealth, iHealth / ply:GetMaxHealth(), 1.2 * FrameTime())
		local iMeterWidth = (scaledFrom1080(iWidth) - 25) * math.Clamp(iMathApproachHealth, 0, 1)
		paintMeteredBar(x + 15, y + 50, scaledFrom1080(iWidth) - 25, 40, healthRectColors, iMeterWidth, iHealth .. " HP", TEXT_ALIGN_LEFT)

		-- Paint ammo meter
		if ply:GetActiveWeapon().Primary then
			local iAmmoCurClip, iMaxWepAmmo, iAmmoInInventory = GetAmmo(ply)

			if iAmmoCurClip ~= -1 then
				iMathApproachAmmo = math.Approach(iMathApproachAmmo, iAmmoCurClip / iMaxWepAmmo, 1.2 * FrameTime())
				iMeterWidth = (scaledFrom1080(iWidth) - 25) * math.Clamp(iMathApproachAmmo, 0, 1)
				local sAmmoText = string.format("%i", iAmmoCurClip)
				paintMeteredBar(x + 15, y + 100, scaledFrom1080(iWidth) - 25, 40, ammoRectColors, iMeterWidth, sAmmoText, TEXT_ALIGN_LEFT)
			end
		end

		local sRole = "Ghost DM"
		surface.SetFont("gmcore.HUDPaint.RoleState")
		local iTextW, iTextH = surface.GetTextSize(sRole)
		ShadowedText(sRole, "gmcore.HUDPaint.RoleState", iRoundStateWidth / 2 + iPanelPadding, ScrH() - scaledFrom1080(iHeight) - iPanelPadding + 3, COLOR_WHITE, TEXT_ALIGN_CENTER) -- +5 on iPanelPadding fixes text sizing problems and alignment
		local sRoundTiome
		local cRoundTime = color_white

		-- Stripped from original TTT HUD
		-- Time displays differently depending on whether haste mode is on, whether the player is traitor or not, and whether it is overtime.
		local endtime = GetGlobalFloat("ttt_round_end", 0) - CurTime()

		if bIsHasteMode then
			local hastetime = GetGlobalFloat("ttt_haste_end", 0) - CurTime()

			if hastetime < 0 then
				sRoundTime = L.overtime
				-- ry = ry + 5
				-- rx = rx - 3
			else
				local t = hastetime
				sRoundTime = util.SimpleTime(math.max(0, t), "%02i:%02i")
			end
		else
			sRoundTime = util.SimpleTime(math.max(0, endtime), "%02i:%02i")
		end

		surface.SetFont("gmcore.HUDPaint.HealthAmmo")
		local iTextW, iTextH = surface.GetTextSize(sRoundTime)
		ShadowedText(sRoundTime, "gmcore.HUDPaint.HealthAmmo", scaledFrom1080(iWidth) - iPanelPadding - 25, ScrH() - scaledFrom1080(iHeight) - iTextH / 2 + 5, cRoundTime, TEXT_ALIGN_CENTER) -- Round time notice

		if bIsHasteMode then
			ShadowedText(L.hastemode, "gmcore.HUDPaint.TimeHaste", scaledFrom1080(iWidth) - iPanelPadding - 25, ScrH() - scaledFrom1080(iHeight) + iTextH / 2 + 5, cRoundTime, TEXT_ALIGN_CENTER) -- Round time notice
		end

		return
	end
end)
