
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "M14 EBR"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_m14"
end
SWEP.Primary.Recoil				= 3
SWEP.Primary.Damage				= 30
SWEP.Primary.Delay				= 0.4
SWEP.Primary.Cone				= 0.002
SWEP.Primary.ClipSize				= 10
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/m14ebr/v_notmic_m14ebr.mdl"
SWEP.WorldModel				= "models/weapons/m14ebr/w_ins2_m14ebr.mdl"
SWEP.Primary.Ammo					= "357"
SWEP.AmmoEnt					= "item_ammo_357_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Weapon_M14EBR.1")
SWEP.IronSightsPos					= Vector(3.3, 3.333, 0.6)
SWEP.IronSightsAng					= Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 20
SWEP.Primary.DefaultClip					= 10
SWEP.HeadshotMultiplier					= 6
SWEP.AutoSpawnable				= true

SWEP.Secondary.Sound       = Sound("Default.Zoom")
function SWEP:SetZoom(state)
		if CLIENT then
				return
		elseif IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
				if state then
						self:GetOwner():SetFOV(20, 0.3)
				else
						self:GetOwner():SetFOV(0, 0.2)
				end
		end
end

-- Add some zoom to ironsights for this gun
function SWEP:SecondaryAttack()
		if not self.IronSightsPos then return end
		if self:GetNextSecondaryFire() > CurTime() then return end

		bIronsights = not self:GetIronsights()

		self:SetIronsights( bIronsights )

		if SERVER then
				self:SetZoom(bIronsights)
		else
				self:EmitSound(self.Secondary.Sound)
		end

		self:SetNextSecondaryFire( CurTime() + 0.3)
end

function SWEP:PreDrop()
		self:SetZoom(false)
		self:SetIronsights(false)
		return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
		self:DefaultReload( ACT_VM_RELOAD );
		self:SetIronsights( false )
		self:SetZoom(false)
end


function SWEP:Holster()
		self:SetIronsights(false)
		self:SetZoom(false)
		return true
end

if CLIENT then
function SWEP:DrawHUD()
		if self:GetIronsights() then
				local iScreenWidth = surface.ScreenWidth()
				local iScreenHeight = surface.ScreenHeight()

				self.ScopeTable = {}
				self.ScopeTable.l = (iScreenHeight + 1)*0.5 -- I don't know why this works, but it does.

				self.QuadTable = {}
				self.QuadTable.h1 = 0.5*iScreenHeight - self.ScopeTable.l
				self.QuadTable.w3 = 0.5*iScreenWidth - self.ScopeTable.l

				self.LensTable = {}
				self.LensTable.x = self.QuadTable.w3
				self.LensTable.y = self.QuadTable.h1
				self.LensTable.w = 2*self.ScopeTable.l
				self.LensTable.h = 2*self.ScopeTable.l

				self.ReticleTable = {}
				self.ReticleTable.wdivider = 3.125
				self.ReticleTable.hdivider = 1.7579/0.5    -- Draws the texture at 512 when the resolution is 1600x900
				self.ReticleTable.x = (iScreenWidth/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
				self.ReticleTable.y = (iScreenHeight/2)-((iScreenHeight/self.ReticleTable.hdivider)/2)
				self.ReticleTable.w = iScreenHeight/self.ReticleTable.hdivider
				self.ReticleTable.h = iScreenHeight/self.ReticleTable.hdivider


				surface.SetDrawColor(0, 0, 0, 255)
				surface.SetTexture(surface.GetTextureID("scope/gdcw_acogcross"))
				surface.DrawTexturedRect(self.ReticleTable.x, self.ReticleTable.y, self.ReticleTable.w, self.ReticleTable.h)

				-- Draw the CHEVRON
				surface.SetDrawColor(0, 0, 0, 255)
				surface.SetTexture(surface.GetTextureID("scope/gdcw_acogchevron"))
				surface.DrawTexturedRect(self.ReticleTable.x, self.ReticleTable.y, self.ReticleTable.w, self.ReticleTable.h)

				-- Draw the SCOPE
				surface.SetDrawColor(0, 0, 0, 255)
				surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
				surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
		else
				return self.BaseClass.DrawHUD(self)
		end
end

function SWEP:AdjustMouseSensitivity()
		return (self:GetIronsights() and 0.18) or nil
end
end
