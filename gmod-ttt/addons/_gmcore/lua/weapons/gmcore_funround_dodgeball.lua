AddCSLuaFile()

SWEP.HoldType = "melee"

SWEP.Base = "weapon_tttbase"
SWEP.PrintName = "Dodge Ball (Fun Round)"

SWEP.Kind = WEAPON_HEAVY

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModelFOV	= 70
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel		= "models/weapons/w_crowbar.mdl"

SWEP.Primary.ClipSize		= 100					-- Size of a clip
SWEP.Primary.DefaultClip	= 100				-- Default number of bullets in a clip
SWEP.Primary.Automatic		= true			-- Automatic/Semi Auto
SWEP.Primary.Ammo			= "CombineCannon"

SWEP.Secondary.ClipSize		= 0					-- Size of a clip
SWEP.Secondary.DefaultClip	= 0				-- Default number of bullets in a clip
SWEP.Secondary.Automatic	= false				-- Automatic/Semi Auto
SWEP.Secondary.Ammo			= ""

SWEP.AllowDelete = false -- never removed for weapon reduction
SWEP.AllowDrop = false
SWEP.LoadoutDisabled = true

function SWEP:SetupDataTables()
	self:NetworkVar("Vector", 0, "BallColor")
end

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
end

function SWEP:Deploy()
	local vm = self:GetOwner():GetViewModel()
	vm:ResetSequence( vm:LookupSequence( "fists_idle01" ) )

	return true
end

function SWEP:PrimaryAttack()
	if self:CanPrimaryAttack() then

		self:SendWeaponAnim( ACT_GRENADE_TOSS )
		self:GetOwner():MuzzleFlash()
		self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

		self:EmitSound("weapons/slam/throw.wav")

		if SERVER then

			self:GetOwner():LagCompensation(true)

			local ball = ents.Create("gmcore_funround_ents_dodgeball")
				ball:SetPos(self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 20)
				ball:SetOwner(self:GetOwner())
				ball:Spawn()
				ball:Activate()

				ball:SetBallColor(self:GetBallColor())

			local ballphys = ball:GetPhysicsObject()
			if ballphys:IsValid() then
				ballphys:SetVelocity(self:GetOwner():GetAimVector() * 2000)
			end

			self:GetOwner():LagCompensation(false)

			if self:Clip1() <= 0 then
				self:Remove()
			end

		end

	else
		self:EmitSound("Buttons.snd14")
	end

	self:SetNextPrimaryFire(CurTime() + 0.6)
end

if CLIENT then
	local matBall = Material( "sprites/sent_ball" )
	function SWEP:DrawWorldModel()
		local pos = self:GetPos()
		if IsValid(self:GetOwner()) then
			local attachment = self:GetOwner():GetAttachment(self:GetOwner():LookupAttachment("anim_attachment_RH"))
			if attachment then pos = attachment.Pos end
		end

		render.SetMaterial( matBall )

		local lcolor = render.ComputeLighting( self:GetPos(), Vector( 0, 0, 1 ) )
		local c = self:GetBallColor()

		lcolor.x = c.r * (math.Clamp( lcolor.x, 0, 1 ) + 0.5) * 255
		lcolor.y = c.g * (math.Clamp( lcolor.y, 0, 1 ) + 0.5) * 255
		lcolor.z = c.b * (math.Clamp( lcolor.z, 0, 1 ) + 0.5) * 255

		render.DrawSprite( pos, 16, 16, Color( lcolor.x, lcolor.y, lcolor.z, 255 ) )

	end
end
