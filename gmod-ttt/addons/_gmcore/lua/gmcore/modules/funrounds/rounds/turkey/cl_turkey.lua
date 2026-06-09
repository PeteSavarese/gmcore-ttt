local EVENT = gmcore.FunRounds.RegisteredFunRounds["Turkey"]

surface.CreateFont( "gmcore.FunRound.TurkeyCounter", {
	font = "Arial",
	size = 50,
	weight = 1000, -- Bold
	antialias = true,
})

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale

function EVENT:Prepare()
	m_Begin(self)
	self.KillsThisRound = {} -- For counting how many kills each player has
	self:AddHook("PostDrawTranslucentRenderables", self.DrawItemText) -- Draws text above spawned food items

	net.Receive("gmcore.FunRound.Turkey.StuffKillConfetti", function()
		local eStuffedPly = net.ReadEntity()
		em = ParticleEmitter(eStuffedPly:GetPos())

		for i = 0, 200 do
			local part = em:Add("effects/spark", eStuffedPly:GetPos() + VectorRand() * math.random(-100, 100) + Vector(math.random(1, 10), math.random(1, 10), math.random(50, 100)))
			part:SetAirResistance(100)
			part:SetBounce(0.3)
			part:SetCollide(true)
			part:SetColor(108, 47, 0)
			part:SetDieTime(2)
			part:SetEndAlpha(0)
			part:SetEndSize(0)
			part:SetGravity(Vector(0, 0, -250))
			part:SetRoll(math.Rand(0, 360))
			part:SetRollDelta(math.Rand(-7, 7))
			part:SetStartAlpha(math.Rand(80, 250))
			part:SetStartSize(math.Rand(6, 12))
			part:SetVelocity(VectorRand() * 75)
		end
	end)
end

function EVENT:Begin()
	self:AddHook("HUDPaint", self.DrawMyStuffings) -- Draws text above spawned food items
end


local featherPic = Material("sgm/turkey/header_stuffing.png")

function EVENT:DrawMyStuffings(iWidth, iHeight)
	if !LocalPlayer():Alive() then return end

	surface.SetFont("gmcore.FunRound.TurkeyCounter")

	local sText = "Stuffing Counter: " .. LocalPlayer():GetNW2Int("gmcore.FunRound.StuffedCount", 0)

	local iTextW, iTextH = surface.GetTextSize(sText)

	surface.SetTextColor(color_white)
	surface.SetTextPos(ScrW() / 2 - iTextW / 2, 64)
	surface.DrawText(sText)

	-- Draw feather icon
	if LocalPlayer():GetNW2Int("gmcore.FunRound.StuffedCount", 0) >= self.iStuffingToKill * 0.75 then
		surface.SetDrawColor(Color(math.abs(math.sin(CurTime() * 0.9) * 255), 0, 0))
	else
		surface.SetDrawColor(255, 255, 255)
	end

	surface.SetMaterial(featherPic)
	surface.DrawTexturedRect(ScrW() / 2 - iTextW / 2 - (64 + 5), 64 - 30 + iTextH / 2, 64, 64) -- - 30 because of png border
end

-- Colors for 3d2d camera. Keep this outside the hook as to reduce resources
local cThanksGivingBrown = Color(162, 107, 53, 255) -- Background in which text is drawn

local iMaxDistance = 490000 -- Max distance to stop drawing 3d2d. This number is 700(units) squared

-- Draw some 3D text
local function Draw3DText(pos, ang, scale, text, cColor)
	local angle = EyeAngles()
	angle = Angle(0, angle.y, 0)
	angle.y = angle.y + math.sin(CurTime()) * 10

	angle:RotateAroundAxis(angle:Up(), -90)
	angle:RotateAroundAxis(angle:Forward(), 90)


	for k, v in ipairs(player.GetAll()) do
		if v == LocalPlayer() then continue end -- Don't draw on ourselves
		if !v:Alive() then continue end
		if LocalPlayer():GetPos():DistToSqr(v:GetPos()) > iMaxDistance then continue end -- Don't draw since we're too far away to make out text

		local posEyesAttach = v:LookupAttachment("eyes")

		if !posEyesAttach or posEyesAttach == nil then continue end -- Errors happen before playermodel is recognized. Prevent errors

		posEyesAttach = v:GetAttachment(posEyesAttach)

		if !posEyesAttach or posEyesAttach == nil then continue end -- Have to check again to prevent errors

		local posEyes = posEyesAttach.Pos
		posEyes.z = posEyes.z + 15 -- From their eyes to above their head

		cam.Start3D2D(posEyes, angle, 0.1)
			local sStuffCount = v:GetNW2Int("gmcore.FunRound.StuffedCount", 0)

			surface.SetFont("gmcore.FunRound.TurkeyCounter")

			local tW, tH = surface.GetTextSize(sStuffCount)
			local iPadding = 5

			surface.SetDrawColor(cThanksGivingBrown)
			surface.DrawRect(-tW / 2 - iPadding, -iPadding, tW + iPadding * 2, tH + iPadding * 2)

			local cStuffingText = Color(tonumber(sStuffCount) / gmcore.FunRounds.RegisteredFunRounds["Turkey"].iStuffingToKill * 255, 0, 0)
			draw.SimpleText(sStuffCount, "gmcore.FunRound.TurkeyCounter", -tW / 2, 0, cStuffingText)
		cam.End3D2D()
	end

	cam.Start3D2D(pos, ang, scale)
		draw.DrawText(text, "gmcore.FunRounds.Ents.FoodItemName", 0, 0, cColor, TEXT_ALIGN_CENTER)
	cam.End3D2D()

	-- Draw other side
	ang:RotateAroundAxis(Vector(0, 0, 1), 180)
	cam.Start3D2D(pos, ang, scale)
		draw.DrawText(text, "gmcore.FunRounds.Ents.FoodItemName", 0, 0, cColor, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

function EVENT:DrawItemText()
	local iDistance = 500
	local dir = LocalPlayer():GetAimVector()
	local angle = math.cos(math.rad(180)) -- 180 degrees
	local startPos = LocalPlayer():EyePos()

	local ents = ents.FindInCone(startPos, dir, iDistance, angle)

	for _, ent in ipairs(ents) do
		if ent:GetClass() != "gmcore_funround_ents_fooditem" then continue end

		local sWeaponName = string.gsub(weapons.Get(ent:GetItemClass()).PrintName, "(Fun Round)", "")

		local _, maxs = ent:GetModelBounds()
		local ang = Angle(0, SysTime() * 100 % 360, 90)

		local pos = ent:GetPos() + Vector(0, 0, maxs.z + 25)
		Draw3DText(pos, ang, 0.2, sWeaponName, color_black)

		pos = ent:GetPos() + Vector(-1, 0, maxs.z + 25)
		Draw3DText(pos, ang, 0.2, sWeaponName, Color(158, 104, 42))
	end
end

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	-- (2) Create panels for each winner.
	---------------------------------------------------------
	local lastAlive = vgui.Create("GmcoreFunRoundWinner")
	lastAlive:SetWinner({
		ply = tWinners.eLastAlive,
		text = string.format("Last Alive")
	})
	table.insert(winners, lastAlive)
	---------------------------------------------------------

	---------------------------------------------------------
	local mostKills = vgui.Create("GmcoreFunRoundWinner")
	mostKills:SetWinner({
		ply = tWinners.eMostKills,
		text = string.format("Most Stuffings (%i)", tWinners.iKillCount)
	})
	table.insert(winners, mostKills)
	---------------------------------------------------------

	return winners
end

function EVENT:RemoveWinners()
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end
end

gmcore.FunRounds:RegisterFunRound("Turkey", EVENT)
