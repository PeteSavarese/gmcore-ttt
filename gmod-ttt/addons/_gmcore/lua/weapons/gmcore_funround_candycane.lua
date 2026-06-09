AddCSLuaFile()

SWEP.Base = "weapon_tttbase"
SWEP.PrintName = "Candy Cane (Fun Round)"

SWEP.Kind = WEAPON_EQUIP

SWEP.AutoSpawnable = false
SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.1

SWEP.Secondary.Automatic = false
SWEP.AllowDrop = false
SWEP.NoSights = true

SWEP.HoldType = "melee"
SWEP.UseHands = true
SWEP.ViewModel = Model("models/weapons/melee/v_crowbar.mdl")
SWEP.WorldModel = Model("models/weapons/melee/w_crowbar.mdl")

SWEP.ConvertDuration = 5
SWEP.ConvertRange = 110
SWEP.ConvertLockRadius = 160

local STATE_NONE = 0
local STATE_CONVERT = 1

local sound_christmas = Sound("gmcore/sleigh_bells.mp3")

local function traceHullTarget(owner, range)
	if not IsValid(owner) then return end

	local startPos = owner:EyePos()
	local endPos = startPos + owner:EyeAngles():Forward() * range

	local tr = util.TraceHull({
		start = startPos,
		endpos = endPos,
		filter = owner,
		mins = Vector(-12, -12, -12),
		maxs = Vector(12, 12, 12),
		mask = MASK_SHOT
	})

	local ent = tr.Entity
	if IsValid(ent) and ent:IsPlayer() then
		return ent
	end
end

local function inLockRadius(owner, targ, radius)
	if not IsValid(owner) or not IsValid(targ) then return false end
	local radiusSqr = radius * radius
	return owner:GetPos():DistToSqr(targ:GetPos()) <= radiusSqr
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "State")
	self:NetworkVar("Float", 0, "StartTime")
	self:NetworkVar("Float", 1, "Duration")
	self:NetworkVar("Entity", 0, "Target")

	if SERVER then
		self:SetState(STATE_NONE)
		self:SetDuration(self.ConvertDuration)
	end
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	return self.BaseClass.Initialize(self)
end

local function isElfOwner(wep)
	local owner = wep:GetOwner()
	return IsValid(owner) and owner:IsPlayer() and owner:GetRole() == ROLE_TRAITOR
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	if not isElfOwner(self) then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local ent = traceHullTarget(owner, self.ConvertRange)
	if not IsValid(ent) or not ent:IsPlayer() then return end
	if ent:GetRole() == ROLE_TRAITOR then return end

	self:SetState(STATE_CONVERT)
	self:SetStartTime(CurTime())
	self:SetTarget(ent)

	owner:EmitSound(sound_christmas)
	ent:PrintMessage(HUD_PRINTCENTER, "Someone is spreading Christmas cheer to you!")

	-- Freeze stacking so multiple elves don't permanently lock someone.
	ent:SetNWInt("gmcore.FR.ChristmasCheer.FreezeCount", ent:GetNWInt("gmcore.FR.ChristmasCheer.FreezeCount", 0) + 1)
	ent:Freeze(true)

	self:SetNextPrimaryFire(CurTime() + self:GetDuration())
end

local function unfreezeOne(ent)
	if not IsValid(ent) or not ent:IsPlayer() then return end

	local c = math.max(0, ent:GetNWInt("gmcore.FR.ChristmasCheer.FreezeCount", 0) - 1)
	ent:SetNWInt("gmcore.FR.ChristmasCheer.FreezeCount", c)
	if c == 0 then
		ent:Freeze(false)
	end
end

function SWEP:Abort()
	local owner = self:GetOwner()
	if IsValid(owner) then
		owner:StopSound(sound_christmas)
	end

	local targ = self:GetTarget()
	unfreezeOne(targ)

	self:SetTarget(NULL)
	self:SetState(STATE_NONE)
	self:SetNextPrimaryFire(CurTime() + 0.1)
end

function SWEP:Think()
	if CLIENT then return end

	if self:GetState() ~= STATE_CONVERT then return end

	local owner = self:GetOwner()
	local targ = self:GetTarget()

	if not IsValid(owner) or not IsValid(targ) or not targ:IsPlayer() then
		self:Abort()
		return
	end

	if not owner:KeyDown(IN_ATTACK) then
		self:Abort()
		return
	end

	if not inLockRadius(owner, targ, self.ConvertLockRadius or self.ConvertRange) then
		self:Abort()
		return
	end

	if CurTime() >= self:GetStartTime() + self:GetDuration() then
		unfreezeOne(targ)

		if gmcore and gmcore.FunRounds and isfunction(gmcore.FunRounds.ChristmasCheer_Convert) then
			gmcore.FunRounds.ChristmasCheer_Convert(owner, targ)
		end

		self:SetTarget(NULL)
		self:SetState(STATE_NONE)
		owner:StopSound(sound_christmas)
	end
end

function SWEP:Holster()
	if SERVER then
		self:Abort()
	end
	return true
end

function SWEP:OnRemove()
	if SERVER then
		self:Abort()
	end
end

function SWEP:OnDrop()
	if SERVER then
		self:Remove()
	end
end

if CLIENT then
	function SWEP:DrawHUD()
		if self:GetState() ~= STATE_CONVERT then return end

		local x = ScrW() / 2
		local y = ScrH() / 2 + (ScrH() / 3)
		local w, h = 255, 20

		local progress = math.TimeFraction(self:GetStartTime(), self:GetStartTime() + self:GetDuration(), CurTime())
		progress = math.Clamp(progress, 0, 1)

		surface.SetDrawColor(0, 255, 0, 155)
		surface.DrawOutlinedRect(x - w / 2, y - h, w, h)
		surface.DrawRect(x - w / 2, y - h, w * progress, h)

		draw.SimpleTextOutlined("SPREADING CHRISTMAS CHEER", "TabLarge", x, y - h - 15, Color(255, 255, 255, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
	end
end
