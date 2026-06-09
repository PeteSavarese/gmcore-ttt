SWEP.Base               = "weapon_tttbase"
SWEP.HoldType           = "slam"

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo          = "none"
SWEP.Primary.Delay         = 1.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.Delay       = 1.0
SWEP.UseHands      = true
SWEP.ViewModelFOV    = 60

SWEP.ViewModel = Model("models/weapons/c_slam.mdl")
SWEP.WorldModel = Model("models/weapons/w_slam.mdl")

SWEP.Kind = WEAPON_EQUIP1
SWEP.AutoSpawnable = false
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = false
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true

local throwsound = Sound("Weapon_SLAM.SatchelThrow")

if CLIENT then
	SWEP.PrintName = "Tripmine"
	SWEP.Slot = 6 -- add 1 to get the slot number key
	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 65
	SWEP.Icon = "vgui/ttt/icon_gl_tripwire"

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = [[Place it on a wall. Once a player crosses the line, the
tripmine will explode.]]
	}
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_SLAM_TRIPMINE_DRAW)

	return true
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
		RunConsoleCommand("lastinv")
		end
end

function SWEP:PrimaryAttack()
	if SERVER and not self.Planted then
		self:TripMineStick()

		timer.Simple(0.2, function()
			if IsValid(self) then self:TryRemove() end
		end)
	end

	self:EmitSound(throwsound)
end

function SWEP:TryRemove()
	if self.Planted then self:Remove() end
end

function SWEP:TripMineStick()
	if SERVER then
		local ply = self:GetOwner()
		if not IsValid(ply) then return end

		if self.Planted then return end

		local ignore = {ply, self}
		local spos = ply:GetShootPos()
		local epos = spos + ply:GetAimVector() * 80
		local tr = util.TraceLine({start=spos, endpos=epos, filter=ignore, mask=MASK_SOLID})

		if tr.HitWorld then
			local mine = ents.Create("ttt_tripmine")
			if IsValid(mine) then
				mine:PointAtEntity(ply)

				local tr_ent = util.TraceEntity({
					start = spos,
					endpos = epos,
					filter = ignore,
					mask = MASK_SOLID
				}, mine)

				if tr_ent.HitWorld then
					local ang = tr_ent.HitNormal:Angle()
					ang.p = ang.p + 90

					mine:SetPos(tr_ent.HitPos + (tr_ent.HitNormal * 3))
					mine:SetAngles(ang)
					mine:SetOwner(ply)
					mine:Spawn()

					mine.fingerprints = self.fingerprints
					self:SendWeaponAnim( ACT_SLAM_TRIPMINE_ATTACH )

					self.Planted = true
				end
			end
		end
	end
end
