
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.HoldType = "grenade"

if CLIENT then
	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "Hex-Shield",
		desc = [[A protective force field that protects against bullets,
explosions, and any type of damage!]]
	}

	SWEP.Icon = "vgui/ttt/icon_gl_hexgrenade"
end

SWEP.AutoSpawnable = false

SWEP.PrintName =	"Hex-Shield"
SWEP.Slot =		6
SWEP.ViewModel =	"models/weapons/c_hexshield_grenade.mdl"
SWEP.WorldModel =	"models/weapons/w_hexshield_grenade.mdl"
SWEP.UseHands =		true
SWEP.ViewModelFOV =	54

SWEP.Primary.ClipSize		=  -1
SWEP.Primary.DefaultClip	=  -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Delay = 1.0
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.Kind = WEAPON_EQUIP1
SWEP.CanBuy = {ROLE_DETECTIVE}

function SWEP:PrimaryAttack()
	if !SERVER then return end
	local tr = self:GetOwner():GetEyeTrace()
	local pos, ang = LocalToWorld(Vector(-7.372986, -22.582741, 6.5), Angle(-49.604, -95.015, 176.585), tr.StartPos, tr.Normal:Angle())

	local ent = ents.Create("hexshield_grenade")
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetShieldColor(Vector(0, 0, 255))
	ent:Spawn()
	ent.OwnerPlayer = self:GetOwner()

	local physobj = ent:GetPhysicsObject()

	if IsValid(physobj) then
		physobj:Wake()
		physobj:SetVelocityInstantaneous(self:GetOwner():GetVelocity())

		local fw = tr.HitPos - pos
		local dist = fw:Length()

		if dist > 0 then
			fw:Mul(750 / dist)

			local up = ang:Up()
			up:Mul(4)
			up:Add(pos)

			physobj:ApplyForceOffset(fw, up)
		end

		self:Remove()
	end
end
