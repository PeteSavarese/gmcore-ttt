-- Custom weapon base, used to derive from CS one, still very similar

AddCSLuaFile()

---- TTT SPECIAL EQUIPMENT FIELDS

-- This must be set to one of the WEAPON_ types in TTT weapons for weapon
-- carrying limits to work properly. See /gamemode/shared.lua for all possible
-- weapon categories.
SWEP.Kind = WEAPON_NONE

-- If CanBuy is a table that contains ROLE_TRAITOR and/or ROLE_DETECTIVE, those
-- players are allowed to purchase it and it will appear in their Equipment Menu
-- for that purpose. If CanBuy is nil this weapon cannot be bought.
--   Example: SWEP.CanBuy = { ROLE_TRAITOR }
-- (just setting to nil here to document its existence, don't make this buyable)
SWEP.CanBuy = nil

if CLIENT then
	-- If this is a buyable weapon (ie. CanBuy is not nil) EquipMenuData must be
	-- a table containing some information to show in the Equipment Menu. See
	-- default equipment weapons for real-world examples.
	SWEP.EquipMenuData = nil

	-- Example data:
	-- SWEP.EquipMenuData = {
	--
	---- Type tells players if it's a weapon or item
	--     type = "Weapon",
	--
	---- Desc is the description in the menu. Needs manual linebreaks (via \n).
	--     desc = "Text."
	-- };

	-- This sets the icon shown for the weapon in the DNA sampler, search window,
	-- equipment menu (if buyable), etc.
	SWEP.Icon = "vgui/ttt/icon_nades" -- most generic icon I guess

	-- You can make your own weapon icon using the template in:
	--   /garrysmod/gamemodes/terrortown/template/

	-- Open one of TTT's icons with VTFEdit to see what kind of settings to use
	-- when exporting to VTF. Once you have a VTF and VMT, you can
	-- resource.AddFile("materials/vgui/...") them here. GIVE YOUR ICON A UNIQUE
	-- FILENAME, or it WILL be overwritten by other servers! Gmod does not check
	-- if the files are different, it only looks at the name. I recommend you
	-- create your own directory so that this does not happen,
	-- eg. /materials/vgui/ttt/mycoolserver/mygun.vmt
end

---- MISC TTT-SPECIFIC BEHAVIOUR CONFIGURATION

-- ALL weapons in TTT must have weapon_tttbase as their SWEP.Base. It provides
-- some functions that TTT expects, and you will get errors without them.
-- Of course this is weapon_tttbase itself, so I comment this out here.
--  SWEP.Base = "weapon_tttbase"

-- If true AND SWEP.Kind is not WEAPON_EQUIP, then this gun can be spawned as
-- random weapon by a ttt_random_weapon entity.
SWEP.AutoSpawnable = false

-- Set to true if weapon can be manually dropped by players (with Q)
SWEP.AllowDrop = true

-- Set to true if weapon kills silently (no death scream)
SWEP.IsSilent = false

-- If this weapon should be given to players upon spawning, set a table of the
-- roles this should happen for here
--  SWEP.InLoadoutFor = { ROLE_TRAITOR, ROLE_DETECTIVE, ROLE_INNOCENT }

-- DO NOT set SWEP.WeaponID. Only the standard TTT weapons can have it. Custom
-- SWEPs do not need it for anything.
--  SWEP.WeaponID = nil

---- YE OLDE SWEP STUFF

if CLIENT then
	SWEP.DrawCrosshair   = false
	SWEP.ViewModelFOV    = 82
	SWEP.ViewModelFlip   = true
	SWEP.CSMuzzleFlashes = true
end

SWEP.Base = "weapon_base"

SWEP.Category           = "TTT"
SWEP.Spawnable          = false

SWEP.IsGrenade = false

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Primary.Sound          = Sound( "Weapon_Pistol.Empty" )
SWEP.Primary.Recoil         = 1.5
SWEP.Primary.Damage         = 1
SWEP.Primary.NumShots       = 1
SWEP.Primary.Cone           = 0.02
SWEP.Primary.Delay          = 0.15

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Primary.ClipMax        = -1

SWEP.Secondary.ClipSize     = 1
SWEP.Secondary.DefaultClip  = 1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.ClipMax      = -1

SWEP.HeadshotMultiplier = 2.7

SWEP.StoredAmmo = 0
SWEP.IsDropped = false

SWEP.DeploySpeed = 1.4

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK
SWEP.ReloadAnim = ACT_VM_RELOAD

SWEP.fingerprints = {}

local sparkle = CLIENT and CreateConVar("ttt_crazy_sparks", "0", FCVAR_ARCHIVE)

-- crosshair
if CLIENT then
	local sights_opacity = CreateConVar("ttt_ironsights_crosshair_opacity", "0.8", FCVAR_ARCHIVE)
	local crosshair_brightness = CreateConVar("ttt_crosshair_brightness", "1.0", FCVAR_ARCHIVE)
	local crosshair_size = CreateConVar("ttt_crosshair_size", "1.0", FCVAR_ARCHIVE)
	local disable_crosshair = CreateConVar("ttt_disable_crosshair", "0", FCVAR_ARCHIVE)

	local enable_color_crosshair = CreateConVar("ttt_crosshair_color_enable", "0", FCVAR_ARCHIVE)
	local crosshair_color_r = CreateConVar("ttt_crosshair_color_r", "255", FCVAR_ARCHIVE)
	local crosshair_color_g = CreateConVar("ttt_crosshair_color_g", "255", FCVAR_ARCHIVE)
	local crosshair_color_b = CreateConVar("ttt_crosshair_color_b", "255", FCVAR_ARCHIVE)

	local crosshair_static = CreateConVar("ttt_crosshair_static", "0", FCVAR_ARCHIVE)
	local crosshair_weaponscale = CreateConVar("ttt_crosshair_weaponscale", "1", FCVAR_ARCHIVE)
	local crosshair_opacity = CreateConVar("ttt_crosshair_opacity", "1", FCVAR_ARCHIVE)
	local crosshair_thickness = CreateConVar("ttt_crosshair_thickness", "1", FCVAR_ARCHIVE)
	local crosshair_outlinethickness = CreateConVar("ttt_crosshair_outlinethickness", "0", FCVAR_ARCHIVE)


	local enable_gap_crosshair = CreateConVar("ttt_crosshair_gap_enable", "0", FCVAR_ARCHIVE)
	local crosshair_gap = CreateConVar("ttt_crosshair_gap", "0", FCVAR_ARCHIVE)
	local enable_dot_crosshair = CreateConVar("ttt_crosshair_dot", "0", FCVAR_ARCHIVE)
	local enable_static_crosshair = CreateClientConVar("ttt_static_crosshair", "0", FCVAR_ARCHIVE)

	local mat_antialias = GetConVar("mat_antialias")
	local scope = surface.GetTextureID("sprites/scope") -- Used for default TTT scope


	local drawStatic = GetConVar("ttt_crosshair_static"):GetBool()
	cvars.AddChangeCallback("ttt_crosshair_static", function(convarName, oldValue, newValue) drawStatic = tobool(newValue) end, "gmcore.crosshair.staticCrosshairConVarChange")

	local crosshairGap = GetConVar("ttt_crosshair_gap"):GetFloat()
	cvars.AddChangeCallback("ttt_crosshair_gap", function(convarName, oldValue, newValue) crosshairGap = tonumber(newValue) end, "gmcore.crosshair.crosshairGapConVarChange")

	local drawDot = GetConVar("ttt_crosshair_dot"):GetBool()
	cvars.AddChangeCallback("ttt_crosshair_dot", function(convarName, oldValue, newValue) drawDot = tobool(newValue) end, "gmcore.crosshair.crosshairDotConVarChange")


	function SWEP:DrawHUD()
		if !self.IsSniper then return self:DrawHUDCrosshairs(drawStatic, crosshairGap) end

		if self:GetIronsights() then
			-- Used for default weps that use TTT scope
			if self.SniperSettings.UseDefaultTTTScope then
				surface.SetDrawColor(0, 0, 0, 255)

				local scrW = ScrW()
				local scrH = ScrH()

				local x = scrW / 2.0
				local y = scrH / 2.0
				local scope_size = scrH

				-- crosshair
				local gap = 80
				local length = scope_size
				surface.DrawLine(x - length, y, x - gap, y)
				surface.DrawLine(x + length, y, x + gap, y)
				surface.DrawLine(x, y - length, x, y - gap)
				surface.DrawLine(x, y + length, x, y + gap)

				gap = 0
				length = 50

				surface.DrawLine(x - length, y, x - gap, y)
				surface.DrawLine(x + length, y, x + gap, y)
				surface.DrawLine(x, y - length, x, y - gap)
				surface.DrawLine(x, y + length, x, y + gap)

				-- cover edges
				local sh = scope_size / 2
				local w = (x - sh) + 2
				surface.DrawRect(0, 0, w, scope_size)
				surface.DrawRect(x + sh - 2, 0, w, scope_size)

				-- cover gaps on top and bottom of screen
				surface.DrawLine(0, 0, scrW, 0)
				surface.DrawLine(0, scrH - 1, scrW, scrH - 1)
				surface.SetDrawColor(255, 0, 0, 255)
				surface.DrawLine(x, y, x + 1, y + 1)

				-- scope
				surface.SetTexture(scope)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)

				return
			end

			local iScreenWidth = ScrW()
			local iScreenHeight = ScrH()

			self.ScopeTable = {}
			self.ScopeTable.l = (iScreenHeight + 1) * 0.5 -- I don't know why this works, but it does.

			self.QuadTable = {}
			self.QuadTable.h1 = 0.5 * iScreenHeight - self.ScopeTable.l
			self.QuadTable.w3 = 0.5 * iScreenWidth - self.ScopeTable.l

			self.LensTable = {}
			self.LensTable.x = self.QuadTable.w3
			self.LensTable.y = self.QuadTable.h1
			self.LensTable.w = 2 * self.ScopeTable.l
			self.LensTable.h = 2 * self.ScopeTable.l

			self.ReticleTable = {}
			self.ReticleTable.wdivider = 3.125
			self.ReticleTable.hdivider = 1.7579 / 0.5 -- Draws the texture at 512 when the resolution is 1600x900
			self.ReticleTable.x = (iScreenWidth / 2) - ((iScreenHeight / self.ReticleTable.hdivider) / 2)
			self.ReticleTable.y = (iScreenHeight / 2) - ((iScreenHeight / self.ReticleTable.hdivider) / 2)
			self.ReticleTable.w = iScreenHeight / self.ReticleTable.hdivider

			self.ReticleTable.h = iScreenHeight / self.ReticleTable.hdivider
			self.SniperSettings.SetZoomFunc(self)
		else
			return self:DrawHUDCrosshairs()
		end
	end

	function SWEP:DrawHUDCrosshairs(static, gap)
			if self.HUDHelp then
				self:DrawHelp()
			end


			local client = LocalPlayer()
			if disable_crosshair:GetBool() or (!IsValid(client)) then return end

			local sights = (!self.NoSights) and self:GetIronsights()

			local x = math.floor(ScrW() / 2.0)
			local y = math.floor(ScrH() / 2.0)
			local scale = math.max(0.2, 10 * self:GetPrimaryCone())

			if !static then
				local LastShootTime = self:LastShootTime()
				scale = scale * (2 - math.Clamp( (CurTime() - LastShootTime) * 5, 0.0, 1.0 ))
			end

			local alpha = sights and sights_opacity:GetFloat() or crosshair_opacity:GetFloat()
			local bright = crosshair_brightness:GetFloat() or 1

			gap = gap or math.floor(20 * scale * (sights and 0.8 or 1))
			local length = math.floor(gap + (25 * crosshair_size:GetFloat()) * scale)

			local thickness = math.max(1, crosshair_thickness:GetInt())
			local rect = thickness > 1

			-- lines are drawn with antialiasing when MSAA is enabled which makes them 1 pixel longer
			local antialias = !rect and mat_antialias:GetInt() > 1

			local offset, odd_offset = 0, 0
			if rect then
				offset = math.floor(thickness / 2)

				-- ensures that high thickness levels don't cause the crosshair to overlap itself
				gap = gap + offset
				length = length + offset

				-- prevents the distance between crosshair prongs from becoming uneven with odd thickness levels
				odd_offset = thickness % 2
			elseif !antialias then
				odd_offset = 1
			end

			local outline = crosshair_outlinethickness:GetInt()
			if outline > 0 then
				surface.SetDrawColor(0, 0, 0, 255 * alpha)

				local out_thick = thickness + outline * 2
				local out_length = antialias and length + 1 or length
				out_length = out_length - gap + outline * 2

				local out_offset = offset + outline

				local out_topleft = length + outline
				local out_bottomright = gap - outline + odd_offset

				surface.DrawRect( x - out_topleft, y - out_offset, out_length, out_thick )
				surface.DrawRect( x + out_bottomright, y - out_offset, out_length, out_thick )
				surface.DrawRect( x - out_offset, y - out_topleft, out_thick, out_length )
				surface.DrawRect( x - out_offset, y + out_bottomright, out_thick, out_length )
			end

			if enable_color_crosshair:GetBool() then
				surface.SetDrawColor(crosshair_color_r:GetInt() * bright,
															crosshair_color_g:GetInt() * bright,
															crosshair_color_b:GetInt() * bright,
															255 * alpha)
			elseif client.IsTraitor and client:IsTraitor() then -- somehow it seems this can be called before my player metatable additions have loaded
				surface.SetDrawColor(255 * bright,
															50 * bright,
															50 * bright,
															255 * alpha)
			else
				surface.SetDrawColor(0,
															255 * bright,
															0,
															255 * alpha)
			end
			if drawDot then
				surface.DrawRect(x - thickness / 2, y - thickness / 2, thickness, thickness) -- draw crosshair dot
			end

			if rect then
				local rect_length = length - gap
				gap = gap + odd_offset

				surface.DrawRect( x - length, y - offset, rect_length, thickness )
				surface.DrawRect( x + gap, y - offset, rect_length, thickness )
				surface.DrawRect( x - offset, y - length, thickness, rect_length )
				surface.DrawRect( x - offset, y + gap, thickness, rect_length )
			else
				surface.DrawLine( x - length, y, x - gap, y )
				surface.DrawLine( x + length, y, x + gap, y )
				surface.DrawLine( x, y - length, x, y - gap )
				surface.DrawLine( x, y + length, x, y + gap )
			end
	end

	function SWEP:AdjustMouseSensitivity()
		if !self.IsSniper then return nil end

		return (self:GetIronsights() and 0.18) or nil
	end

	local GetPTranslation = LANG.GetParamTranslation

	-- Many non-gun weapons benefit from some help
	local help_spec = {text = "", font = "TabLarge", xalign = TEXT_ALIGN_CENTER}
	function SWEP:DrawHelp()
			local data = self.HUDHelp

			local translate = data.translatable
			local primary   = data.primary
			local secondary = data.secondary

			if translate then
				primary   = primary   and GetPTranslation(primary,   data.translate_params)
				secondary = secondary and GetPTranslation(secondary, data.translate_params)
			end

			help_spec.pos  = {ScrW() / 2.0, ScrH() - 40}
			help_spec.text = secondary or primary
			draw.TextShadow(help_spec, 2)

			-- if no secondary exists, primary is drawn at the bottom and no top line
			-- is drawn
			if secondary then
				help_spec.pos[2] = ScrH() - 60
				help_spec.text = primary
				draw.TextShadow(help_spec, 2)
			end
	end

	-- mousebuttons are enough for most weapons
	local default_key_params = {
			primaryfire   = Key("+attack",  "LEFT MOUSE"),
			secondaryfire = Key("+attack2", "RIGHT MOUSE"),
			usekey        = Key("+use",     "USE")
	};

	function SWEP:AddHUDHelp(primary_text, secondary_text, translate, extra_params)
			extra_params = extra_params or {}

			self.HUDHelp = {
				primary = primary_text,
				secondary = secondary_text,
				translatable = translate,
				translate_params = table.Merge(extra_params, default_key_params)
			};
	end
end

-- Shooting functions largely copied from weapon_cs_base
function SWEP:PrimaryAttack(worldsnd)

	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

	if !self:CanPrimaryAttack() then return end

	if !worldsnd then
			self:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )
	elseif SERVER then
			sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
	end

	self:ShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone() )

	self:TakePrimaryAmmo( 1 )

	local owner = self:GetOwner()
	if !IsValid(owner) or owner:IsNPC() or (!owner.ViewPunch) then return end

	owner:ViewPunch( Angle( util.SharedRandom(self:GetClass(),-0.2,-0.1,0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(),-0.1,0.1,1) * self.Primary.Recoil, 0 ) )
end

function SWEP:DryFire(setnext)
	if CLIENT and LocalPlayer() == self:GetOwner() then
			self:EmitSound( "Weapon_Pistol.Empty" )
	end

	setnext(self, CurTime() + 0.2)

	self:Reload()
end

function SWEP:CanPrimaryAttack()
	if !IsValid(self:GetOwner()) then return end

	if self:Clip1() <= 0 then
			self:DryFire(self.SetNextPrimaryFire)
			return false
	end
	return true
end

function SWEP:CanSecondaryAttack()
	if !IsValid(self:GetOwner()) then return end

	if self:Clip2() <= 0 then
			self:DryFire(self.SetNextSecondaryFire)
			return false
	end
	return true
end

local function Sparklies(attacker, tr, dmginfo)
	if tr.HitWorld and tr.MatType == MAT_METAL then
			local eff = EffectData()
			eff:SetOrigin(tr.HitPos)
			eff:SetNormal(tr.HitNormal)
			util.Effect("cball_bounce", eff)
	end
end

function SWEP:ShootBullet( dmg, recoil, numbul, cone )
	self:SendWeaponAnim(self.PrimaryAnim)
	self:GetOwner():MuzzleFlash()
	self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

	local sights = self:GetIronsights()

	numbul = numbul or 1
	cone   = cone   or 0.01

	local bullet = {}
	bullet.Num    = numbul
	bullet.Src    = self:GetOwner():GetShootPos()
	bullet.Dir    = self:GetOwner():GetAimVector()
	bullet.Spread = Vector( cone, cone, 0 )
	bullet.Tracer = 4
	bullet.TracerName = self.Tracer or "Tracer"
	bullet.Force  = 10
	bullet.Damage = dmg

	if CLIENT and sparkle:GetBool() then
			bullet.Callback = Sparklies
	end

	self:GetOwner():FireBullets( bullet )

	-- Owner can die after firebullets
	if (!IsValid(self:GetOwner())) or self:GetOwner():IsNPC() or (!self:GetOwner():Alive()) then return end

	if ((game.SinglePlayer() and SERVER) or
			((!game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then

			-- reduce recoil if ironsighting
			recoil = sights and (recoil * 0.6) or recoil

			local eyeang = self:GetOwner():EyeAngles()
			eyeang.pitch = eyeang.pitch - recoil
			self:GetOwner():SetEyeAngles( eyeang )
	end
end

function SWEP:GetPrimaryCone()
	local cone = self.Primary.Cone or 0.2
	-- 15% accuracy bonus when sighting
	return self:GetIronsights() and (cone * 0.85) or cone
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
	return self.HeadshotMultiplier
end

function SWEP:IsEquipment()
	return WEPS.IsEquipment(self)
end

function SWEP:DrawWeaponSelection() end

--[[
	Begin gl sniper zoom code
--]]
function SWEP:SecondaryAttack()
	if self.NoSights or (!self.IronSightsPos) then return end

	if self.IsSniper then
		if !self.IronSightsPos then return end
		if self:GetNextSecondaryFire() > CurTime() then return end

		bIronsights = !self:GetIronsights()

		self:SetIronsights(bIronsights)

		if SERVER then
			self:SetZoom(bIronsights)
		else
			self:EmitSound(self.Secondary.Sound)
		end

		self:SetNextSecondaryFire(CurTime() + 0.3)
	else
		self:SetIronsights(!self:GetIronsights())
		self:SetNextSecondaryFire(CurTime() + 0.3)
	end
end

--[[
	Called when the player uses secondary attack to zoom in or out.

	isZoomedOut: boolean which tells whether they are zooming in our out.
]]
function SWEP:SetZoom(isZoomedOut)
	if !self.IsSniper then return end

	if CLIENT then
		return
	elseif IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
		local vm = self:GetOwner():GetViewModel()

		if isZoomedOut then
			self:GetOwner():SetFOV(20, 0.3)

			timer.Simple(0.15, function()
				vm:SetNoDraw(true)
			end)
		else
			self:GetOwner():SetFOV(0, 0.2)
			vm:SetNoDraw(false)
		end
	end
end

-- The OnDrop() hook is useless for this as it happens AFTER the drop. OwnerChange
-- does not occur when a drop happens for some reason. Hence this thing.
function SWEP:PreDrop()
	if SERVER and IsValid(self:GetOwner()) and self.Primary.Ammo != "none" then
		if self.IsSniper then
			self:SetZoom(false)
			self:SetIronsights(false)
		end

			local ammo = self:Ammo1()

			-- Do not drop ammo if we have another gun that uses this type
			for _, w in ipairs(self:GetOwner():GetWeapons()) do
				if IsValid(w) and w != self and w:GetPrimaryAmmoType() == self:GetPrimaryAmmoType() then
						ammo = 0
				end
			end

			self.StoredAmmo = ammo

			if ammo > 0 then
				self:GetOwner():RemoveAmmo(ammo, self.Primary.Ammo)
			end
	end
end

function SWEP:Reload()
	if (self:Clip1() == self.Primary.ClipSize or self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0) then return end
	self:DefaultReload(self.ReloadAnim)
	self:SetIronsights(false)

	if self.IsSniper then
		self:SetZoom(false)
	end
end

function SWEP:Holster()
	self:SetIronsights(false)

	if self.IsSniper then
		self:SetZoom(false)
	end

	return true
end

function SWEP:OnRestore()
	self.NextSecondaryAttack = 0
	self:SetIronsights( false )
end

function SWEP:Ammo1()
	return IsValid(self:GetOwner()) and self:GetOwner():GetAmmoCount(self.Primary.Ammo) or false
end

function SWEP:DampenDrop()
	-- For some reason gmod drops guns on death at a speed of 400 units, which
	-- catapults them away from the body. Here we want people to actually be able
	-- to find a given corpse's weapon, so we override the velocity here and call
	-- this when dropping guns on death.
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
			phys:SetVelocityInstantaneous(Vector(0,0,-75) + phys:GetVelocity() * 0.001)
			phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
	end
end

local SF_WEAPON_START_CONSTRAINED = 1

-- Picked up by player. Transfer of stored ammo and such.
function SWEP:Equip(newowner)
	if SERVER then
			if self:IsOnFire() then
				self:Extinguish()
			end

			self.fingerprints = self.fingerprints or {}

			if not table.HasValue(self.fingerprints, newowner) then
				table.insert(self.fingerprints, newowner)
			end

			if self:HasSpawnFlags(SF_WEAPON_START_CONSTRAINED) then
				-- If this weapon started constrained, unset that spawnflag, or the
				-- weapon will be re-constrained and float
				local flags = self:GetSpawnFlags()
				local newflags = bit.band(flags, bit.bnot(SF_WEAPON_START_CONSTRAINED))
				self:SetKeyValue("spawnflags", newflags)
			end
	end

	if SERVER and IsValid(newowner) and self.StoredAmmo > 0 and self.Primary.Ammo != "none" then
			local ammo = newowner:GetAmmoCount(self.Primary.Ammo)
			local given = math.min(self.StoredAmmo, self.Primary.ClipMax - ammo)

			newowner:GiveAmmo( given, self.Primary.Ammo)
			self.StoredAmmo = 0
	end
end

-- We were bought as special equipment, some weapons will want to do something
-- extra for their buyer
function SWEP:WasBought(buyer)
end

function SWEP:SetIronsights(b)
	if (b != self:GetIronsights()) then
			self:SetIronsightsPredicted(b)
			self:SetIronsightsTime(CurTime())
			if CLIENT then
				self:CalcViewModel()
			end
	end
end
function SWEP:GetIronsights()
	return self:GetIronsightsPredicted()
end

---Dummy functions that will be replaced when SetupDataTables runs. These are
---here for when that does not happen (due to e.g. stacking base classes)
function SWEP:GetIronsightsTime() return -1 end
function SWEP:SetIronsightsTime( time ) end
function SWEP:GetIronsightsPredicted() return false end
function SWEP:SetIronsightsPredicted( bool ) end

-- Set up ironsights dt bool. Weapons using their own DT vars will have to make
-- sure they call this.
function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 3, "IronsightsPredicted")
	self:NetworkVar("Float", 3, "IronsightsTime")
end

local ReloadActIndex = {
	[ "pistol" ]      = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
	[ "smg" ]         = ACT_HL2MP_GESTURE_RELOAD_SMG1,
	[ "grenade" ]     = ACT_HL2MP_GESTURE_RELOAD_GRENADE,
	[ "ar2" ]         = ACT_HL2MP_GESTURE_RELOAD_AR2,
	[ "shotgun" ]     = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
	[ "rpg" ]         = ACT_HL2MP_GESTURE_RELOAD_RPG,
	[ "physgun" ]     = ACT_HL2MP_GESTURE_RELOAD_PHYSGUN,
	[ "crossbow" ]    = ACT_HL2MP_GESTURE_RELOAD_CROSSBOW,
	[ "melee" ]       = ACT_HL2MP_GESTURE_RELOAD_MELEE,
	[ "slam" ]        = ACT_HL2MP_GESTURE_RELOAD_SLAM,
	[ "fist" ]        = ACT_HL2MP_GESTURE_RELOAD_FIST,
	[ "melee2" ]      = ACT_HL2MP_GESTURE_RELOAD_MELEE2,
	[ "passive" ]     = ACT_HL2MP_GESTURE_RELOAD_PASSIVE,
	[ "knife" ]       = ACT_HL2MP_GESTURE_RELOAD_KNIFE,
	[ "duel" ]        = ACT_HL2MP_GESTURE_RELOAD_DUEL,
	[ "camera" ]      = ACT_HL2MP_GESTURE_RELOAD_CAMERA,
	[ "magic" ]       = ACT_HL2MP_GESTURE_RELOAD_MAGIC,
	[ "revolver" ]    = ACT_HL2MP_GESTURE_RELOAD_REVOLVER
}

function SWEP:CalcViewModel()
	if (!CLIENT) or (!IsFirstTimePredicted() and !game.SinglePlayer()) then return end
	self.bIron = self:GetIronsights()
	self.fIronTime = self:GetIronsightsTime()
	self.fCurrentTime = CurTime()
	self.fCurrentSysTime = SysTime()
end

-- Note that if you override Think in your SWEP, you should call
-- BaseClass.Think(self) so as not to break ironsights
function SWEP:Think()
	self:CalcViewModel()
end

function SWEP:DyingShot()
	local fired = false
	if self:GetIronsights() then
			self:SetIronsights(false)

			if self:GetNextPrimaryFire() > CurTime() then
				return fired
			end

			-- Owner should still be alive here
			if IsValid(self:GetOwner()) then
				local punch = self.Primary.Recoil or 5

				-- Punch view to disorient aim before firing dying shot
				local eyeang = self:GetOwner():EyeAngles()
				eyeang.pitch = eyeang.pitch - math.Rand(-punch, punch)
				eyeang.yaw = eyeang.yaw - math.Rand(-punch, punch)
				self:GetOwner():SetEyeAngles( eyeang )

				MsgN(self:GetOwner():Nick() .. " fired his DYING SHOT")

				self:GetOwner().dying_wep = self

				self:PrimaryAttack(true)

				fired = true
			end
	end

	return fired
end

local ttt_lowered = CreateConVar("ttt_ironsights_lowered", "1", FCVAR_ARCHIVE)
local host_timescale = GetConVar("host_timescale")

local LOWER_POS = Vector(0, 0, -2)

local IRONSIGHT_TIME = 0.25
function SWEP:GetViewModelPosition( pos, ang )
	if (!self.IronSightsPos) or (self.bIron == nil) then return pos, ang end

	local bIron = self.bIron
	local time = self.fCurrentTime + (SysTime() - self.fCurrentSysTime) * game.GetTimeScale() * host_timescale:GetFloat()

	if bIron then
			self.SwayScale = 0.3
			self.BobScale = 0.1
	else
			self.SwayScale = 1.0
			self.BobScale = 1.0
	end

	local fIronTime = self.fIronTime
	if (!bIron) and fIronTime < time - IRONSIGHT_TIME then
			return pos, ang
	end

	local mul = 1.0

	if fIronTime > time - IRONSIGHT_TIME then
			mul = math.Clamp( (time - fIronTime) / IRONSIGHT_TIME, 0, 1 )

			if !bIron then mul = 1 - mul end
	end

	local offset = self.IronSightsPos + (ttt_lowered:GetBool() and LOWER_POS or vector_origin)

	if self.IronSightsAng then
			ang = ang * 1
			ang:RotateAroundAxis( ang:Right(),    self.IronSightsAng.x * mul )
			ang:RotateAroundAxis( ang:Up(),       self.IronSightsAng.y * mul )
			ang:RotateAroundAxis( ang:Forward(),  self.IronSightsAng.z * mul )
	end

	pos = pos + offset.x * ang:Right() * mul
	pos = pos + offset.y * ang:Forward() * mul
	pos = pos + offset.z * ang:Up() * mul

	return pos, ang
end

--[[
	Begin Weapon Skin Section
--]]
function SWEP:CheckActiveSkin()
	local owner = self:GetOwner()
	if !IsValid(owner) then return end

	if !PS or !owner.PS_Items then
		-- Pointshop may not have loaded yet
		timer.Simple(0.5, function()
			if IsValid(self) and isfunction(self.CheckActiveSkin) then
				self:CheckActiveSkin()
			end
		end)

		return
	end

	local tPlyItems = owner.PS_Items

	for itemId, item in pairs(tPlyItems) do
		local itemTbl = PS.Items[itemId]

		if itemTbl == nil then continue end
		if itemTbl.Category != "Skins" then continue end
		if !itemTbl.Class then continue end
		if !owner:PS_HasItemEquipped(itemId) then continue end

		if itemTbl.Class == self:GetClass() then
			if SERVER then
				self:SetNWString("gmcore.ActiveWeaponSkin", itemId)
			end

			-- Small delay when sending to client since clients will have a nil ent index upon SWEP init
			-- This broadcasts the SWEPs active skin and stores it clientside so GetNWString won't have to be run constantly
			timer.Simple(0.1, function()
				BroadcastLua([[ents.GetByIndex(]] .. self:EntIndex() .. [[).ActiveSkin = "]] .. itemId .. [["]])
			end)

			self.ActiveSkin = itemId

			if itemTbl.ViewModel and !self.VElements then
			-- Ignore SWEP creator weps
				self.ViewModel = itemTbl.ViewModel

				owner:GetViewModel():SetModel(itemTbl.ViewModel)
				self:SendWeaponAnim(ACT_VM_DEPLOY)
			end

			if itemTbl.ViewModel and !self.WElements then
				-- Ignore SWEP creator weps
				self.WorldModel = itemTbl.WorldModel
			end
		end
	end
end

function SWEP:Initialize()
	if CLIENT and self:Clip1() == -1 then
			self:SetClip1(self.Primary.DefaultClip)
	elseif SERVER then
			self.fingerprints = {}

			self:SetIronsights(false)
	end

	self:SetDeploySpeed(self.DeploySpeed)

	-- compat for gmod update
	if self.SetHoldType then
			self:SetHoldType(self.HoldType or "pistol")

			if self.ReloadHoldType then
				local act = ReloadActIndex[self.ReloadHoldType]
				if act then
						self.ActivityTranslate[ ACT_MP_RELOAD_STAND ] = act
						self.ActivityTranslate[ ACT_MP_RELOAD_CROUCH ] = act
				end
			end
	end

	-- Apply skins to client, only if we actively have wep
	if CLIENT and !string.find(GetGlobalString("gmcore.ServerTag"), "vanilla") and self:GetOwner() == LocalPlayer() and isfunction(self.CheckActiveSkin) then
		self:CheckActiveSkin()
		self.ActiveSkin = self:GetNWString("gmcore.ActiveWeaponSkin")
	end
end

function SWEP:Deploy()
	self:SetIronsights(false)

	if !string.find(GetGlobalString("gmcore.ServerTag"), "vanilla") and isfunction(self.CheckActiveSkin) then
		self:CheckActiveSkin()
	end

	return true
end


SWEP.vRenderOrder = nil

-- Any model changes that must be made should be done before drawing the viewmodel
function SWEP:PreDrawViewModel(vm, wep)
	if !vm then return end

	local skinId = self.ActiveSkin

	if (skinId == nil or skinId == "") and isfunction(self.CheckActiveSkin) and CurTime() >= (self._gmcoreNextSkinCheck or 0) then
		-- Stupid hack fix until I figure out why knife doesn't load skin -- Dime
		self._gmcoreNextSkinCheck = CurTime() + 0.5
		self:CheckActiveSkin()

		skinId = self.ActiveSkin or self:GetNWString("gmcore.ActiveWeaponSkin", "")
	end

	if self.ActiveSkin == nil or self.ActiveSkin == "" then return end

	local itemTbl = PS.Items[skinId]

	if itemTbl.ModifySWEPProperties then
		for property, propValue in pairs(itemTbl.ModifySWEPProperties) do
			if self[property] == nil then continue end

			self[property] = propValue
		end
	end
end

function SWEP:ViewModelDrawn()
	if !isfunction(self:GetOwner().GetViewModel) then return end -- Sometimes bugs out and func is nil

	local vm = self:GetOwner():GetViewModel()
	local skinID = self.ActiveSkin

	if skinID != nil and skinID != "" then
		-- If we switch weapons, the two skins will clash. When weapon is switched, this will reset the current drawn materials
		vm:SetSubMaterial()

		local itemTbl = PS.Items[skinID]

		if itemTbl.ModifySWEPProperties then
			for property, propValue in pairs(itemTbl.ModifySWEPProperties) do
				if self[property] == nil then continue end

				self[property] = propValue
			end
		end

		if itemTbl.ViewMaterials then
			for k, v in pairs(itemTbl.ViewMaterials) do
				vm:SetSubMaterial(k - 1, v) -- SubMaterials start at 0 while lua starts at 1, so Material is index - 1 for some reason.
				end

			return
		end
	else
		vm:SetSubMaterial()
	end
end

function SWEP:DrawWorldModel()
	local skinID = self.ActiveSkin

	if skinID != nil and skinID != "" then
		local itemTbl = PS.Items[skinID]

		if itemTbl.WorldMaterials then
			for k, v in pairs(itemTbl.WorldMaterials) do
				self:SetSubMaterial(k - 1, v) -- SubMaterials start at 0 while lua starts at 1, so Material is index - 1 for some reason.
			end
		end
	end

	self:DrawModel()
end
