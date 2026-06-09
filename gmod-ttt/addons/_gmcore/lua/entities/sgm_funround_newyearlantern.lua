---New Year lantern pickup entity for the fun round. Grants a random power-up (speed boost, float, health, or gravity change) on touch.
AddCSLuaFile()

ENT.Type = "anim"

--[[
0* Powerup is randomly chosen in ENT:Touch.
0--]]
local powerUps = {
	-- Increased speed for 10 seconds
	[1] = function(ply)
		local iOriginalWalkSpeed = ply:GetWalkSpeed()
		ply:SetWalkSpeed(ply:GetWalkSpeed() * 2)
		ply.bCurrentlyBoosted = true -- Don't allow them to pickup another lantern booster
		ply:ChatPrint("You have 2x speed boost for 10 seconds!")

		timer.Simple(10, function()
			ply:SetWalkSpeed(iOriginalWalkSpeed)
			ply.bCurrentlyBoosted = false
			ply:ChatPrint("You speed boost has expired!") -- TODO: Change this to SGM's prefixed chat msg
		end)
	end,
	[2] = function(ply)
		local trail = util.SpriteTrail(ply, 0, Color(255, 0, 0), false, 60, 0, 4, 1 / (60 + 20) * 0.5, "trails/smoke.vmt")

		-- This is a hacky way of having player move at a constant velocity without accelerating them nor having gravity slow their vertical speed
		hook.Add("Think", "SGM.ChinNewYear.FloatBooster" .. ply:SteamID64(), function()
			if ply:GetVelocity().z < 500 then
				ply:SetVelocity(Vector(0, 0, 500))
			end
		end)

		ply:ChatPrint("TRAP! FLY UP LIKE A LANTERN!") -- TODO: Change this to SGM's prefixed chat msg

		timer.Simple(0.5, function()
			hook.Remove("Think", "SGM.ChinNewYear.FloatBooster" .. ply:SteamID64()) -- Remove our think hook since we no longer need to fly them up

			local pos = ply:GetPos()
			local effect = EffectData()
			effect:SetOrigin(pos)
			effect:SetStart(pos)
			effect:SetMagnitude(512)
			effect:SetScale(128)
			util.Effect("Explosion", effect)

			timer.Simple(0.1, function()
				ply:Kill()
				trail:Remove()
			end)
		end)
	end,
	[3] = function(ply)
		ply:Give("weapon_ttt_harpoon")
		ply:ChatPrint("You got a harpoon!") -- TODO: Change this to SGM's prefixed chat msg
	end,
	[4] = function(ply)
		local iOriginalJumpPower = ply:GetJumpPower()
		ply:SetJumpPower(iOriginalJumpPower * 2)
		ply.bCurrentlyBoosted = true
		ply:ChatPrint("Double jump power for 10 seconds! Jump twice as high!")

		timer.Simple(10, function()
			ply:SetJumpPower(iOriginalJumpPower)
			ply.bCurrentlyBoosted = false
			ply:ChatPrint("You jump boost has expired!") -- TODO: Change this to SGM's prefixed chat msg
		end)
	end,
	[5] = function(ply)
		ply:SetGravity(2)
		ply.bCurrentlyBoosted = true
		ply:ChatPrint("WARNING! You've consumed a black hole! Your gravity pull is increased by 2x.") -- TODO: Change this to SGM's prefixed chat msg

		timer.Simple(10, function()
			ply:SetGravity(0)
			ply.bCurrentlyBoosted = false
			ply:ChatPrint("Your 2x gravity pull has expired!") -- TODO: Change this to SGM's prefixed chat msg
		end)
	end
}

function ENT:Initialize()
	self:SetModel("models/props/de_nuke/emergency_lighta.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	if SERVER then
		self:SetTrigger(true)
	end

	self.tickRemoval = false
end

function ENT:CanPickupLantern(ply)
	if ply.bCurrentlyBoosted then
		return false
	end

	return true
end

function ENT:Touch(ent)
	if (SERVER and self.tickRemoval ~= true) and ent:IsValid() and ent:IsPlayer() and self:CanPickupLantern(ent) then
		self.tickRemoval = true

		--local iRandInt = math.Round(math.Rand(1, #powerUps))
		local iRandInt = 5
		powerUps[iRandInt](ent) -- Chose random powerup and pass ply as arg
		self:Remove()
	end
end
