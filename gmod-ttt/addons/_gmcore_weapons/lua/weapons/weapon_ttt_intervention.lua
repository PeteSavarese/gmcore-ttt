-- TODO: UPDATE IRONSIGHT TO M9k

AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName = "Intervention"
	SWEP.Slot = 6
	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV = 70
	SWEP.Icon = "vgui/ttt/icon_gl_intervention"

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = [[Speciality sniper rifle designed for the Detective
looking to protect from any distance.]]
	}
end

SWEP.Primary.Recoil = 2
SWEP.Primary.Damage = 60
SWEP.Primary.Delay = 1.5
SWEP.Primary.Cone = 0.002
SWEP.Primary.ClipSize = 10
SWEP.Primary.ClipMax = 20
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = true
SWEP.ViewModel = "models/weapons/intervention/v_snip_int.mdl"
SWEP.WorldModel = "models/weapons/intervention/w_snip_int.mdl"
SWEP.Primary.Ammo = "357"
SWEP.AmmoEnt = "item_ammo_357_ttt"
SWEP.HoldType = "ar2"
SWEP.Primary.Sound = Sound("Weapon_INT.Single")
SWEP.IronSightsPos = Vector(-3.481, -4.824, 0.119)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.HeadshotMultiplier = 3
SWEP.AutoSpawnable = false
SWEP.Secondary.Sound = Sound("Default.Zoom")
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_DETECTIVE}

-- Sniper specifications
SWEP.IsSniper = true
SWEP.SniperSettings = {
	SetZoomFunc = function(wep)
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetTexture(surface.GetTextureID("scope/gdcw_acogcross"))
		surface.DrawTexturedRect(wep.ReticleTable.x, wep.ReticleTable.y, wep.ReticleTable.w, wep.ReticleTable.h)

		-- Draw the CHEVRON
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetTexture(surface.GetTextureID("scope/gdcw_acogchevron"))
		surface.DrawTexturedRect(wep.ReticleTable.x, wep.ReticleTable.y, wep.ReticleTable.w, wep.ReticleTable.h)

		-- Draw the SCOPE
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
		surface.DrawTexturedRect(wep.LensTable.x, wep.LensTable.y, wep.LensTable.w, wep.LensTable.h)
	end
}
