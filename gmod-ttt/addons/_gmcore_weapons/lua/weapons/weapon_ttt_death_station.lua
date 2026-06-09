SWEP.HoldType = "normal"

if CLIENT then
	SWEP.PrintName = "Death Station"
	SWEP.Slot = 6

	SWEP.ViewModelFOV = 10

	SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "Death Station explodes on use instead of healing!\nPlace in crowded areas for best results!"
	};

	SWEP.Icon = "vgui/ttt/icon_gl_deathstation"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel          = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel         = "models/props/cs_office/microwave.mdl"

SWEP.DrawCrosshair      = false
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Delay = 1.0

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR} -- Traitor Weapon
SWEP.LimitedStock = true -- True = You can buy only once per round

SWEP.AllowDrop = false

SWEP.NoSights = true

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:HealthDrop()
end
function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self:HealthDrop()
end

local throwsound = Sound( "Weapon_SLAM.SatchelThrow" )

-- Original Health Station Drop Code.... With some changes.
function SWEP:HealthDrop()
	if SERVER then
			local ply = self:GetOwner()
			if not IsValid(ply) then return end

			if self.Planted then return end

			local vsrc = ply:GetShootPos()
			local vang = ply:GetAimVector()
			local vvel = ply:GetVelocity()

			local vthrow = vvel + vang * 200

			local health = ents.Create("ttt_death_station")
			if IsValid(health) then
				health:SetPos(vsrc + vang * 10)
				health:Spawn()

				health:SetPlacer(ply)

				health:PhysWake()
				local phys = health:GetPhysicsObject()
				if IsValid(phys) then
						phys:SetVelocity(vthrow)
				end
				self:Remove()

				self.Planted = true
			end
	end

	self:EmitSound(throwsound)
end


function SWEP:Reload()
	return false
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
			RunConsoleCommand("lastinv")
	end
end

if CLIENT then
	function SWEP:Initialize()
			local tHelp = {}
			tHelp.pos  = {ScrW() / 2.0, ScrH() - 40}
			tHelp.text = "tHelp"
			draw.TextShadow(tHelp, 2)

			return self.BaseClass.Initialize(self)
	end
end

function SWEP:Deploy()
	if SERVER and IsValid(self:GetOwner()) then
			self:GetOwner():DrawViewModel(false)
	end
	return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end
