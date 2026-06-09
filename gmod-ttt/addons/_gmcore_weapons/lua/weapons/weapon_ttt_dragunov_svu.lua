-- TODO: UPDATE IRONSIGHT TO M9k

AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName = "Dragunov SVU"
	SWEP.Slot = 6
	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 65
	SWEP.Icon = "vgui/ttt/icon_gl_dragunov_svu"

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = [[
		Deliver a silent and killing blow to innocents
		from any distance.]]
	}
end

SWEP.Primary.Recoil = 2
SWEP.Primary.Damage = 50
SWEP.Primary.Delay = 0.8
SWEP.Primary.Cone = 0.005
SWEP.Primary.ClipSize = 10
SWEP.Primary.ClipMax = 20
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = true
SWEP.ViewModel = "models/weapons/dragunov/v_sniper_svu.mdl"
SWEP.WorldModel = "models/weapons/dragunov/w_dragunov_svu.mdl"
SWEP.Primary.Ammo = "357"
SWEP.AmmoEnt = "item_ammo_357_ttt"
SWEP.HoldType = "ar2"
SWEP.Primary.Sound = Sound("weapons/svu/g3sg1-1.mp3")
SWEP.IronSightsPos = Vector(-3.481, -4.824, 0.119)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.HeadshotMultiplier = 3
SWEP.AutoSpawnable = false
SWEP.Secondary.Sound = Sound("Default.Zoom")
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR}

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
