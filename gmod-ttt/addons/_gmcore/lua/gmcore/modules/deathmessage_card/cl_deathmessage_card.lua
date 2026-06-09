CreateClientConVar("ttt_dmsg_seconds", 7, FCVAR_ARCHIVE)

gmcore.Deathcard = {}
gmcore.Deathcard.CurrentPanel = nil

local function removeCard()
	hook.Remove("CalcView", "gmcore.Deathcard.FollowAttacker")
	hook.Remove("KeyPress", "gmcore.Deathcard.ExitState")
	hook.Remove("PreDrawHalos", "gmcore.Deathcard.DrawAttackerHalo")

	if gmcore.Deathcard.CurrentPanel != nil then
		gmcore.Deathcard.CurrentPanel:Remove()
		gmcore.Deathcard.CurrentPanel = nil
	end

	gmcore.Deathcard.CamInfo = nil

	net.Start("gmcore.Deathcard.UpdateCardPanelState")
	net.WriteBool(false)
	net.SendToServer()
end

---Displays the deathmessage card of attacker and setup camera follow
---@param attacker Entity Attacker entity that killed us
---@param role number Role of attacker
---@param dmginfo table Integer of how many times attacker hit us
---@param dnaFound boolean Table of the hits that victim inflicted on attacker
function gmcore.Deathcard:ShowAttackerCard(attacker, role, dmginfo, dnaFound)
	gmcore.Deathcard.CurrentPanel = vgui.Create("GmcoreDeathcardPanel")
	gmcore.Deathcard.CurrentPanel:SetSize(750, 250)
	gmcore.Deathcard.CurrentPanel:SetPos((ScrW() / 2) - (gmcore.Deathcard.CurrentPanel:GetWide() / 2),
		ScrH() - gmcore.Deathcard.CurrentPanel:GetTall() - 15)
	gmcore.Deathcard.CurrentPanel:SetVisible(true)
	gmcore.Deathcard.CurrentPanel.RemoveOn = CurTime() + GetConVar("ttt_dmsg_seconds"):GetFloat()
	gmcore.Deathcard.CurrentPanel:SetInfo(attacker, role, dmginfo, dnaFound)

	self.CamInfo = {
		startingPos = dmginfo.DeathPos,
		endPos = dmginfo.DeathPos + Vector(0, 0, 90), -- Move to head height
		lerpTime = 3,
		lastAng = LocalPlayer():LocalEyeAngles(),
		isExiting = false -- True if player wants to exit card early
	}

	-- hook.Add("KeyPress", "gmcore.Deathcard.ExitState", function(ply, key)
	--   if key == KEY_W or key == KEY_S or key == KEY_A or key == KEY_D then
	--
	-- end)

	hook.Add("CalcView", "gmcore.Deathcard.FollowAttacker", function(ply, pos, ang, fov)
		if self.CamInfo.isExiting then
			self.CamInfo.startingPos = LerpVector(self.CamInfo.lerpTime, self.CamInfo.startingPos, self.CamInfo.endPos)
		else
			self.CamInfo.startingPos = LerpVector(self.CamInfo.lerpTime * FrameTime(), self.CamInfo.startingPos,
				self.CamInfo.endPos)
		end

		if IsValid(attacker) then
			if attacker:IsPlayer() then
				-- If attacker then set camera pos on player
				local attackerEnt = attacker:Alive() and attacker or attacker:GetNWEntity("ttt_ragdoll")
				if ! IsValid(attackerEnt) then return end

				local attackerPosToScreen = attackerEnt:LocalToWorld(attackerEnt:OBBCenter())
				local attackerAngDiff = (attackerPosToScreen - self.CamInfo.startingPos):Angle()

				self.CamInfo.lastAng = LerpAngle(self.CamInfo.lerpTime * FrameTime(), self.CamInfo.lastAng, attackerAngDiff)
			else
				local attackerEnt = LocalPlayer():GetNWEntity("ttt_ragdoll")
				if ! IsValid(attackerEnt) then return end

				local attackerPosToScreen = attackerEnt:LocalToWorld(attackerEnt:OBBCenter())
				local attackerAngDiff = (attackerPosToScreen - self.CamInfo.startingPos):Angle()

				self.CamInfo.lastAng = LerpAngle(self.CamInfo.lerpTime * FrameTime(), self.CamInfo.lastAng, attackerAngDiff)
			end
		end

		local view = {}
		view.origin = self.CamInfo.startingPos
		view.angles = self.CamInfo.lastAng
		view.fov = fov

		return view
	end)

	hook.Add("PreDrawHalos", "gmcore.Deathcard.DrawAttackerHalo", function()
		local attackerEnt = nil

		if IsValid(attacker) and attacker:IsPlayer() then
			attackerEnt = attacker:Alive() and attacker or attacker:GetNWEntity("ttt_ragdoll")
		else
			attackerEnt = LocalPlayer():GetNWEntity("ttt_ragdoll")
		end

		halo.Add({ attackerEnt }, Color(255, 0, 0), 0, 0, 2, true, true)
	end)

	net.Start("gmcore.Deathcard.UpdateCardPanelState")
	net.WriteBool(gmcore.Deathcard.CurrentPanel and true or false)
	net.SendToServer()
end


---Player wants to leave camera early by using left or right click
function gmcore.Deathcard:PlayerExitCard()
	if ! IsValid(LocalPlayer():GetObserverTarget()) then return removeCard() end
	if ! self.CamInfo then return removeCard() end

	self.CamInfo.endPos = LocalPlayer():GetObserverTarget():GetPos() + Vector(0, 0, 70) -- Move to attackker head height
	self.CamInfo.lerpTime = 0.1
	self.CamInfo.isExiting = true


	timer.Simple(0.3, removeCard)
end

hook.Add("Think", "RemoveBadge", function()
	if gmcore.Deathcard.CurrentPanel and CurTime() >= gmcore.Deathcard.CurrentPanel.RemoveOn then
		removeCard()
	end
end)

hook.Add("PlayerSpawnClient", "gmcore.Deathcard.RemoveCardOnSpawn", function()
	removeCard()
end)

net.Receive("gmcore.Deathcard.HandleDeath", function()
	if gmcore.Deathcard.CurrentPanel and gmcore.Deathcard.CurrentPanel:IsValid() then
		removeCard()
	end

	gmcore.Deathcard:ShowAttackerCard(net.ReadEntity(), net.ReadInt(8), net.ReadTable(), net.ReadBool())
end)
