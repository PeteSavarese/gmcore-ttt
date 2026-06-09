local surface = surface
local draw = draw
local math = math
local string = string

local GetLang = LANG.GetUnsafeLanguageTable
local interp = string.Interp

-- Fonts used in HUD
surface.CreateFont("gmcore.HUDPaint.RoleState", {
	font = "Biko",
	size = 32,
	weight = 1000 -- Bold
})

surface.CreateFont("gmcore.HUDPaint.HealthAmmo", {
	font = "Biko",
	size = 24,
	weight = 750 -- Bold
})

surface.CreateFont("gmcore.HUDPaint.TimeHaste", {
	font = "Biko",
	size = 12,
	weight = 500 -- Bold
})

surface.CreateFont("gmcore.HUDPaint.PropPossession", {
	font = "Biko",
	size = 18,
	weight = 500 -- Bold
})

surface.CreateFont("TimeLeft", {
	font = "Trebuchet24",
	size = 24,
	weight = 800
})

surface.CreateFont("HealthAmmo", {
	font = "Trebuchet24",
	size = 24,
	weight = 750
})

-- Color presets. Easy access for easy modification
local roleStateColors = {
	noround = Color(100, 100, 100, 255),
	traitor = Color(200, 25, 25, 255),
	innocent = Color(25, 200, 25, 255),
	detective = Color(0, 100, 200, 255)
}

local timeStateColors = {
	noround = Color(100, 100, 100, 255),
	traitor = Color(150, 25, 25, 255),
	innocent = Color(25, 150, 25, 255),
	detective = Color(0, 100, 150, 255)
}

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

local roundStateStrings = {
	[ROUND_WAIT] = "round_wait",
	[ROUND_PREP] = "round_prep",
	[ROUND_ACTIVE] = "round_active",
	[ROUND_POST] = "round_post"
}

local iMathApproachHealth = 0
local iMathApproachAmmo = 0

---@param text string The text to render
---@param font string Font name
---@param x number X position
---@param y number Y position
---@param color Color Text colour
---@param xalign? number TEXT_ALIGN_* horizontal alignment
---@param yalign? number TEXT_ALIGN_* vertical alignment
local function ShadowedText(text, font, x, y, color, xalign, yalign)
	draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
	draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

-- Returns player's ammo information
---@param ply Player Player to retrieve ammo information for
---@return number clip Current clip ammo (-1 if unavailable)
---@return number? max Max clip size
---@return number? inv Reserve ammo in inventory
local function GetAmmo(ply)
	local weap = ply:GetActiveWeapon()
	if ! weap or ! ply:Alive() then return -1 end

	local ammo_inv = weap:Ammo1() or 0
	local ammo_clip = weap:Clip1() or 0
	local ammo_max = weap.Primary.ClipSize or 0

	return ammo_clip, ammo_max, ammo_inv
end

-- Paints a bar with a value, with a background colour to show valuation/devaluation
---@param x number Left edge
---@param y number Top edge
---@param iWidth number Total bar width
---@param iHeight number Total bar height
---@param tColorTableRef {background: Color, fill: Color} Colour table with background and fill keys
---@param iMeterWidth number Width of the filled portion
---@param sText string Label drawn inside the bar
---@param eTextAlign? number TEXT_ALIGN_* constant (default TEXT_ALIGN_CENTER)
local function paintMeteredBar(x, y, iWidth, iHeight, tColorTableRef, iMeterWidth, sText, eTextAlign)
	if ! tColorTableRef or tColorTableRef == nil or type(tColorTableRef) ~= "table" then return end -- A whole wahck ton of checks to insure no HUDPaint errors
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

-- Takes a number and returns the proper value for scaling to the current display.
-- Always ensures an even number is returned for nice math calculation in HUD formatting.
-- TODO: ACTUALLY DO SCALING
---@param iNumIn1080 number Value designed for a 1920×1080 display
---@param bIsWidth? boolean True = scale against screen width; false/nil = height
---@return number scaledValue The scaled (and even-ified) value
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

local bHealthLablel = CreateClientConVar("ttt_health_label", "0", true)

---@param ply Player The local player to draw HUD for
local function AliveHUDPaint(ply)
	local L = GetLang()

	local round_state = GAMEMODE.round_state

	local cRoleColor = roleStateColors.innocent
	cTimeColor = timeStateColors.innocent

	local bIsHasteMode = HasteMode() and round_state == ROUND_ACTIVE
	local bIsTraitor = ply:IsActiveTraitor()
	local iRoundStateWidth = scaledFrom1080(iWidth) - scaledFrom1080(iWidth) * .25

	local fRoundTime = GetGlobalFloat("ttt_round_end", 0) - CurTime()

	local iHealth = math.max(0, ply:Health())

	local x = iPanelPadding
	local y = ScrH() - iPanelPadding - iHeight

	-- Useful for other elements like radar refresh time, which is placed above the HUD
	if ! GAMEMODE.HUD then
		GAMEMODE.HUD = {}
		GAMEMODE.HUD.Pos = {}
	end

	GAMEMODE.HUD.Pos["x"] = x
	GAMEMODE.HUD.Pos["y"] = y

	if GAMEMODE.round_state ~= ROUND_ACTIVE then
		cRoleColor = roleStateColors.noround
		cTimeColor = timeStateColors.noround
	elseif ply:GetTraitor() then
		cRoleColor = roleStateColors.traitor
		cTimeColor = timeStateColors.traitor
	elseif ply:GetDetective() then
		cRoleColor = roleStateColors.detective
		cTimeColor = timeStateColors.detective
	end

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
	surface.DrawRect(scaledFrom1080(iWidth) - scaledFrom1080(iWidth) * .25 + iPanelPadding + 1, y,
		scaledFrom1080(iWidth) * .25, scaledFrom1080(iRoleStateBackground))

	-- Paint health meter
	iMathApproachHealth = math.Approach(iMathApproachHealth, iHealth / ply:GetMaxHealth(), 1.2 * FrameTime())
	local iMeterWidth = (scaledFrom1080(iWidth) - 25) * math.Clamp(iMathApproachHealth, 0, 1)

	paintMeteredBar(x + 15, y + 50, scaledFrom1080(iWidth) - 25, 40, healthRectColors, iMeterWidth, iHealth .. " HP",
		TEXT_ALIGN_LEFT)

	if bHealthLablel:GetBool() then
		local sHealthStatus = util.HealthToString(iHealth, ply:GetMaxHealth())
		draw.SimpleText(L[sHealthStatus], "TabLarge", x + scaledFrom1080(iWidth) - 25, y + 50 + 20, COLOR_WHITE,
			TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	-- Paint ammo meter
	if ply:GetActiveWeapon().Primary then
		local iAmmoCurClip, iMaxWepAmmo, iAmmoInInventory = GetAmmo(ply)

		if iAmmoCurClip ~= -1 then
			iMathApproachAmmo = math.Approach(iMathApproachAmmo, iAmmoCurClip / iMaxWepAmmo, 1.2 * FrameTime())
			iMeterWidth = (scaledFrom1080(iWidth) - 25) * math.Clamp(iMathApproachAmmo, 0, 1)

			local sAmmoText = string.format("%i + %02i", iAmmoCurClip, iAmmoInInventory)

			paintMeteredBar(x + 15, y + 100, scaledFrom1080(iWidth) - 25, 40, ammoRectColors, iMeterWidth, sAmmoText,
				TEXT_ALIGN_LEFT)
		end
	end

	local text = nil
	if round_state == ROUND_ACTIVE then
		text = L[ply:GetRoleStringRaw()]
	else
		text = L[roundStateStrings[round_state]]
	end

	surface.SetFont("gmcore.HUDPaint.RoleState")
	local iTextW, iTextH = surface.GetTextSize(text)

	ShadowedText(text, "gmcore.HUDPaint.RoleState", iRoundStateWidth / 2 + iPanelPadding,
		ScrH() - scaledFrom1080(iHeight) - iPanelPadding + 3, COLOR_WHITE, TEXT_ALIGN_CENTER)                                                                                -- +5 on iPanelPadding fixes text sizing problems and alignment

	local sRoundTime
	local cRoundTime = color_white

	-- Stripped from original TTT HUD
	-- Time displays differently depending on whether haste mode is on, whether the player is traitor or not, and whether it is overtime.
	if bIsHasteMode then
		local fHasteTime = GetGlobalFloat("ttt_haste_end", 0) - CurTime()

		if fHasteTime < 0 then
			if ! bIsTraitor or (math.ceil(CurTime()) % 7 <= 2) then
				-- innocent or blinking "overtime"
				sRoundTime = L.overtime

				-- need to hack the position a little because of the font switch

				if ! ry then return end
				ry = ry + 5
				rx = rx - 3
			else
				-- traitor and not blinking "overtime" right now, so standard endtime display
				sRoundTime = util.SimpleTime(math.max(0, fRoundTime), "%02i:%02i")
				cRoundTime = COLOR_RED
			end
		else
			-- still in starting period
			local t = fHasteTime

			if bIsTraitor and math.ceil(CurTime()) % 6 < 2 then
				t = fRoundTime
				cRoundTime = COLOR_RED
			end
			sRoundTime = util.SimpleTime(math.max(0, t), "%02i:%02i")
		end
	else
		-- bog standard time when haste mode is off (or round not active)
		sRoundTime = util.SimpleTime(math.max(0, fRoundTime), "%02i:%02i")
	end

	surface.SetFont("gmcore.HUDPaint.HealthAmmo")
	local iTextW, iTextH = surface.GetTextSize(sRoundTime)

	ShadowedText(sRoundTime, "gmcore.HUDPaint.HealthAmmo", scaledFrom1080(iWidth) - iPanelPadding - 25,
		ScrH() - scaledFrom1080(iHeight) - iTextH / 2 + 5, cRoundTime, TEXT_ALIGN_CENTER)                                                                                             -- Round time notice

	if bIsHasteMode then
		ShadowedText(L.hastemode, "gmcore.HUDPaint.TimeHaste", scaledFrom1080(iWidth) - iPanelPadding - 25,
			ScrH() - scaledFrom1080(iHeight) + iTextH / 2 + 5, COLOR_WHITE, TEXT_ALIGN_CENTER)                                                                                            -- Round time notice
	end
end

local iSpecWidth = 334
local iSpecHeight = 40       -- SpecHeight changes depending if we are spectating a player or not.
local iSpecRoleStateBackground = 40
local iSpecPanelPadding = 10 -- 10 px from left and 10 px from the bottom
local iSpecRoundStateWidth = scaledFrom1080(iSpecWidth) - scaledFrom1080(iSpecWidth) * .25

local tKeyParams = { usekey = Key("+use", "USE") }

local function PunchPaint(ply)
	local L = GetLang()
	local punch = ply:GetNWFloat("specpunches", 0)

	local width, height = 200, 25
	local x = ScrW() / 2 - width / 2
	local y = iSpecPanelPadding / 2 + height

	local iPunchWidth = width * punch

	paintMeteredBar(x, y, width, height, ammoRectColors, iPunchWidth, "")

	draw.SimpleText(L.punch_title, "gmcore.HUDPaint.PropPossession", ScrW() / 2, y + 5, color_white, TEXT_ALIGN_CENTER)
	draw.SimpleText(L.punch_help, "gmcore.HUDPaint.PropPossession", ScrW() / 2, iSpecPanelPadding - 5, COLOR_WHITE,
		TEXT_ALIGN_CENTER)

	local bonus = ply:GetNWInt("bonuspunches", 0)
	if bonus != 0 then
		local text
		if bonus < 0 then
			text = interp(L.punch_bonus, { num = bonus })
		else
			text = interp(L.punch_malus, { num = bonus })
		end

		draw.SimpleText(text, "gmcore.HUDPaint.PropPossession", ScrW() / 2, y * 2, COLOR_WHITE, TEXT_ALIGN_CENTER)
	end
end

local function SpecHUDPaint(ply)
	local L = GetLang()

	local fRoundTime = GetGlobalFloat("ttt_round_end", 0) - CurTime()

	local x = iPanelPadding
	local y = ScrH() - iSpecPanelPadding - iSpecHeight

	-- Draw grey background
	surface.SetDrawColor(cBackgroundColor)
	surface.DrawRect(x, y, scaledFrom1080(iSpecWidth), scaledFrom1080(iSpecHeight))

	-- Accent role coloring on border
	surface.SetDrawColor(roleStateColors.noround)
	surface.DrawRect(x, y, 5, scaledFrom1080(iSpecHeight))

	-- Role background color on top, where text is drawn ontop of this.
	surface.SetDrawColor(roleStateColors.noround)
	surface.DrawRect(x, y, iSpecRoundStateWidth, scaledFrom1080(iRoleStateBackground))
	local iSpecRoundState = L[roundStateStrings[GAMEMODE.round_state]]

	surface.SetFont("gmcore.HUDPaint.RoleState")
	local iTextW, iTextH = surface.GetTextSize(iSpecRoundState)
	-- Round state (In prog,  waiting)
	ShadowedText(iSpecRoundState, "gmcore.HUDPaint.RoleState", iSpecRoundStateWidth / 2 + iSpecPanelPadding,
		ScrH() - scaledFrom1080(iSpecHeight) - iSpecPanelPadding + 3, COLOR_WHITE, TEXT_ALIGN_CENTER)                                                                                                   -- +5 on iPanelPadding fixes text sizing problems and alignment


	local sRoundTime = util.SimpleTime(math.max(0, fRoundTime), "%02i:%02i")
	surface.SetFont("gmcore.HUDPaint.HealthAmmo")
	local iTextW, iTextH = surface.GetTextSize(sRoundTime)

	ShadowedText(sRoundTime, "gmcore.HUDPaint.HealthAmmo", scaledFrom1080(iSpecWidth) - iSpecPanelPadding - 25,
		ScrH() - scaledFrom1080(iSpecHeight) - iTextH / 2 + 10, color_white, TEXT_ALIGN_CENTER)                                                                                                      -- Round time notice
	local eObserver = ply:GetObserverTarget()

	if IsValid(eObserver) and eObserver:IsPlayer() then
		iSpecHeight = 90
		local iHealth = eObserver:Health()

		iMathApproachHealth = math.Approach(iMathApproachHealth, iHealth / eObserver:GetMaxHealth(), 1.2 * FrameTime())
		local iMeterWidth = (scaledFrom1080(iSpecWidth) - 25) * math.Clamp(iMathApproachHealth, 0, 1)

		paintMeteredBar(x + 15, y + 45, scaledFrom1080(iSpecWidth) - 25, 40, healthRectColors, iMeterWidth, iHealth .. " HP",
			TEXT_ALIGN_LEFT)

		-- Player's Name
		ShadowedText(eObserver:Nick(), "gmcore.HUDPaint.RoleState", ScrW() / 2, 10, color_white, TEXT_ALIGN_CENTER)
	elseif ! eObserver:IsPlayer() then
		iSpecHeight = 40

		if IsValid(eObserver) and eObserver:GetNWEntity("spec_owner", nil) == ply then -- Are we possesing a prop?
			PunchPaint(ply)
		else
			ShadowedText(interp(L.spec_help, tKeyParams), "gmcore.HUDPaint.PropPossession", ScrW() / 2, iPanelPadding - 5,
				color_white, TEXT_ALIGN_CENTER)
		end
	end
end

-- Paints player status HUD element in the bottom left
function GM:HUDPaint()
	local ply = LocalPlayer()
	local shouldDrawHudConVar = GetConVar("cl_drawhud"):GetBool()

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTTargetID") then
		hook.Call("HUDDrawTargetID", GAMEMODE)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTMStack") and shouldDrawHudConVar then
		MSTACK:Draw(ply)
	end

	if (! ply:Alive()) or ply:Team() == TEAM_SPEC and shouldDrawHudConVar then
		if hook.Call("HUDShouldDraw", GAMEMODE, "TTTSpecHUD") then
			SpecHUDPaint(ply)
		end

		return
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTRadar") then
		RADAR:Draw(ply)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTTButton") then
		TBHUD:Draw(ply)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTWSwitch") then
		WSWITCH:Draw(ply)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTVoice") then
		VOICE.Draw(ply)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTDisguise") then
		DISGUISE.Draw(ply)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTPickupHistory") then
		hook.Call("HUDDrawPickupHistory", GAMEMODE)
	end

	-- Draw bottom left info panel
	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTInfoPanel") and shouldDrawHudConVar then
		AliveHUDPaint(ply)
	end
end

-- Hide the standard HUD stuff
local hud = { ["CHudHealth"] = true, ["CHudBattery"] = true, ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true }
function GM:HUDShouldDraw(name)
	if hud[name] then return false end

	return self.BaseClass.HUDShouldDraw(self, name)
end

--If player has anti-red tint perk. Assume they don't until server tells us otherwise.
hook.Add("HUDShouldDraw", "HideRedTint", function(name)
	if name == "CHudDamageIndicator" and LocalPlayer():PS_HasItemEquipped("upgrade_red_lenses") then
		return false
	end
end)

local silentPeople = {}
local function addtoSilentTable()
	local plyer = net.ReadEntity()
	local isDisguised = net.ReadBool()

	if isDisguised then
		silentPeople[plyer:SteamID64()] = true
	else
		silentPeople[plyer:SteamID64()] = nil
	end
end
net.Receive("gmcore.SilentFootstepsAlert", addtoSilentTable)

hook.Add("PlayerFootstep", "gmcore.HideClientsideSteps", function(ply, pos, foot, sound, volume, filter)
	if ply:GetNWBool("disguised", false) and silentPeople[ply:SteamID64()] then
		return true
	end
end)

hook.Add("TTTEndRound", "ClearSilentTable", function()
	silentPeople = {}
end)
