if CLIENT then
	SWEP.PrintName = "Riot Shield"
	SWEP.Icon = "vgui/ttt/icon_gl_riotshield"
	SWEP.Slot = 6
	SWEP.EquipMenuData = {
		name = "Riot Shield",
		type = "Defense",
		desc = [[Protection from bullets and charge
your enemies and knock them out of
with your primary attack.
		]]
	}
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "slam"
SWEP.ViewModelFOV = 10
SWEP.ViewModelFlip = false
SWEP.AdminSpawnable = true
SWEP.Kind = WEAPON_EQUIP1

SWEP.Primary.Damage         = 0
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Delay          = 2.5
SWEP.Primary.Ammo       = "none"

SWEP.Primary.ClipSize  = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic  = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.LimitedStock = true

SWEP.WorldModel = "models/arleitiss/riotshield/shield.mdl" -- The reason im having a world model is that, when it lies on the ground, it should have a model then too.
SWEP.ViewModel  = "models/weapons/v_crowbar.mdl"

local playerPushedSound = Sound("phx/epicmetal_soft5.wav")

local function onDropOrRemove(self)
	if not SERVER then return end

	self:SetColor(Color(255, 255, 255, 255))

	if not IsValid(self.ent) then return end

	self.ent:Remove()
end

function SWEP:Deploy()
	if SERVER then
		local owner = self:GetOwner()

		if not IsValid(self) or not IsValid(owner) then return end
		if IsValid(self.ent) then return end

		local ownerEyeAng = owner:EyeAngles()

		owner:DrawViewModel(false)
		self:SetNoDraw(true)
		self.ent = ents.Create("prop_physics")
		self.ent:SetModel("models/arleitiss/riotshield/shield.mdl")
		self.ent:SetPos(owner:GetPos() + Vector(10, 0, 15) + (owner:GetForward() * 25))
		self.ent:SetAngles(Angle(0, ownerEyeAng.y, ownerEyeAng.r))
		self.ent:SetParent(owner)
		self.ent:Fire("SetParentAttachmentMaintainOffset", "eyes", 0.01)
		self.ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
		self.ent.AllowPropspec = false
		self.ent:Spawn()
		self.ent:Activate()
	end

	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	local owner = self:GetOwner()
	local tr = util.QuickTrace(owner:GetShootPos(), owner:GetAimVector() * 80, {owner, self.ent})

	if not (tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() and (owner:EyePos() - tr.HitPos):Length() < 100) then return end
	if not SERVER then return end

	local ply = tr.Entity
	local pushvel = tr.Normal * 300

	pushvel.z = math.Clamp(pushvel.z, 250, 300)

	ply:SetVelocity(ply:GetVelocity() + pushvel)
	owner:EmitSound(playerPushedSound)

	timer.Simple(0.05, function()
		if not IsValid(owner) then return end

		local eyePos = owner:EyePos()
		local eyeAng = owner:EyeAngles()
		self.ent:SetPos(eyePos + eyeAng:Forward() * 25 + eyeAng:Right() * 0 + eyeAng:Up() * -5)
		self.ent:SetAngles(Angle(eyeAng.p, eyeAng.y, 0))
	end)
end

function SWEP:Holster()
	if not SERVER then return end
	if IsValid(self.ent) then self.ent:Remove() end

	return true
end

function SWEP:OnDrop()
	return onDropOrRemove(self)
end

function SWEP:OnRemove()
	return onDropOrRemove(self)
end