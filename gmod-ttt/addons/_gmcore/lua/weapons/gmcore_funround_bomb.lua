local BOMB_FUSE_TIME = 10 -- Once the bomb wep is spawned and given, how long until it explodes

if CLIENT then
	SWEP.PrintName = "Bomb (Fun Round)"
	SWEP.Slot = 7

	SWEP.Icon = "vgui/ttt/icon_gl_jihad"
end

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.ViewModel  = Model("models/weapons/zaratusa/jihad_bomb/v_jb.mdl")
SWEP.WorldModel = Model("models/weapons/zaratusa/jihad_bomb/w_jb.mdl")

-- TTT Information Start
SWEP.Base = "weapon_tttbase"
SWEP.ViewModelFlip = false
SWEP.Slot = 7

SWEP.AllowDrop = false
-- TTT Information End

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"
SWEP.Primary.Delay			= 0.1

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "TimerStart")
	self:NetworkVar("Float", 1, "TimerDetonate")
	self:NetworkVar("Int", 3, "PassAmount")
end

function SWEP:Initialize()
	self:SetTimerStart(CurTime())
	self:SetTimerDetonate(CurTime() + BOMB_FUSE_TIME)
	self:SetPassAmount(0)
	self.HasExploded = false -- The explode func will be called multiple times. Prevents Think running after exploding
end

--[[
	Handle passing of bomb to another player
]]
function SWEP:PrimaryAttack()
	if CLIENT then return end

	self:GetOwner():LagCompensation( true )
	local startPos = self:GetOwner():GetShootPos()
	local endPos = startPos + self:GetOwner():GetAimVector() * 100
	local ignore = {self, self:GetOwner()}
	local tr = util.TraceLine({
		start = startPos,
		endpos = endPos,
		filter = ignore,
		mask = MASK_SOLID
	})
	self:GetOwner():LagCompensation( false )
	if !tr.Entity:IsPlayer() then return end

	local ply = tr.Entity
	if ply:HasWeapon(self:GetClass()) then return end -- they already have a bomb

	-- Now give them a bomb with identical start and detonate times to keep the timer the same
	ply:StripWeapons()

	local bombWep = ply:Give(self:GetClass())
	bombWep:SetTimerStart(self:GetTimerStart())

	if self:GetPassAmount() <= 3 and (self:GetTimerDetonate() - CurTime() <= 3) then
		-- If passed no more than 4 times with less then 3 seconds, then add increase to timer
		bombWep:SetTimerDetonate(self:GetTimerDetonate() + 3)
	else
		bombWep:SetTimerDetonate(self:GetTimerDetonate())
	end

	bombWep:SetPassAmount(self:GetPassAmount() + 1)

	ply:SelectWeapon(bombWep)
	ply:SetVelocity(ply:GetVelocity() + (tr.Normal * 700))

	-- Alert plys now
	gmcore.chatprint(self:GetOwner(), "You passed the bomb to ", Color(30, 90, 150), ply:Nick())
	gmcore.chatprint(ply, Color(30, 90, 150), self:GetOwner():Nick(), color_white, " passed you the bomb!")

	self:Remove()
end

--[[
	Whenever weapon is given or deployed, this is called. Ensure walkspeed is set
]]
function SWEP:Deploy()
	if !SERVER then return end

	self.BombOwner = self:GetOwner()
	self.OwnerOriginalWalkSpeed = self.BombOwner:GetWalkSpeed()
	self.BombOwner:SetWalkSpeed(self.OwnerOriginalWalkSpeed * 1.5)
end

--[[
	Called whenever weapon is holestered, NOT REMOVED! This is just to cover an edgecase
]]
function SWEP:Holster()
	if !SERVER then return end

	self.BombOwner:SetWalkSpeed(self.OwnerOriginalWalkSpeed)
end

--[[
	Called when weapon is removed when timer runs out. Return player's walk speed to normal
]]
function SWEP:OnRemove()
	if !SERVER then return end

	self.BombOwner:SetWalkSpeed(self.OwnerOriginalWalkSpeed)
end

--[[
	Draws over HUD to show a countdown of when the bomb will explode. Moved from fun round client code to here to cover possible edge cases
]]
local CONTAINER_BOX_WIDTH = 200
local CONTAINER_BOX_HEIGHT = 50

function SWEP:DrawHUD()
	local startTime = self:GetTimerStart()
	local detonateTime = self:GetTimerDetonate()
	local timeUntilDetonate = detonateTime - CurTime()

	local containerBoxPosX = (ScrW() / 2) - (CONTAINER_BOX_WIDTH / 2)

	surface.SetDrawColor(FRAME_BACKGROUND_COLOR)
	surface.DrawRect(containerBoxPosX, 15, CONTAINER_BOX_WIDTH, CONTAINER_BOX_HEIGHT)

	surface.SetDrawColor(COMMUNITY_PRIMARY_COLOR)
	surface.DrawRect(containerBoxPosX, 15, CONTAINER_BOX_WIDTH, 5)

	-- Draw bar that counts down
	-- Background
	surface.SetDrawColor(Color(20, 20, 5, 222))
	surface.DrawRect(containerBoxPosX + 5, 15 + 10, CONTAINER_BOX_WIDTH - 10, CONTAINER_BOX_HEIGHT - 15)

	-- Bar with time remaining
	surface.SetDrawColor(COMMUNITY_PRIMARY_COLOR)
	surface.DrawRect(containerBoxPosX + 5, 15 + 10, (CONTAINER_BOX_WIDTH - 10) * (timeUntilDetonate / 10), CONTAINER_BOX_HEIGHT - 15)

	-- Stupid fix because round doesn't add trailing zero
	local timeUntilDetonateStr = math.Round(timeUntilDetonate, 1)

	if #string.Explode(".", timeUntilDetonateStr) <= 1 then
		timeUntilDetonateStr = timeUntilDetonateStr .. ".0"
	end

	draw.SimpleText(timeUntilDetonateStr, "gmcore.HUDPaint.RoleState", (ScrW() / 2) - (CONTAINER_BOX_WIDTH / 2) + 10, 15 + 10, Color(255, 255, 255))
end

--[[
	When timer reaches 0, handles explosion
]]
function SWEP:Explode()
	if self.HasExploded then return end
	if !IsValid(self:GetOwner()) then return end

	local ent = ents.Create("env_explosion")
	ent:SetPos(self:GetOwner():GetPos())
	ent:SetOwner(self:GetOwner())
	ent:SetKeyValue("iMagnitude", "25")
	ent:Spawn()
	ent:Fire("Explode", 0, 0)
	ent:EmitSound("siege/big_explosion.wav", 500, 100)

	-- Damage info so in PlayerDeath we can track that the weapon is the inflictor
	local dmg = DamageInfo()
	dmg:SetDamage(2000)
	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	dmg:SetDamageForce(self:GetOwner():GetAimVector())
	dmg:SetDamagePosition(self:GetOwner():GetPos())
	dmg:SetDamageType(DMG_BLAST)

	self:GetOwner():TakeDamageInfo(dmg)

	self:Remove()

	self.HasExploded = true
end

--[[
	Handles timer countdown, explosion, and beep sound in relation to time until detonation
]]
local beepSnd = Sound("weapons/c4/c4_beep1.wav")
local lastBeepWarning = 0

function SWEP:Think()
	if CLIENT then return end
	if self.HasExploded then return end
	if !self:GetTimerStart() then return end
	if !self:GetTimerDetonate() then return end

	local startTime = self:GetTimerStart()
	local detonateTime = self:GetTimerDetonate()
	local timeUntilDetonate = detonateTime - CurTime()

	if CurTime() >= detonateTime then
		self:Explode()

		return
	end

	-- Time between each beep changes depending on how close the bomb is to exploding
	-- TODO: Improve this
	if timeUntilDetonate >= 6 then
		if CurTime() - lastBeepWarning > 1 or lastBeepWarning == 0 then
			self:GetOwner():EmitSound(beepSnd)
			lastBeepWarning = CurTime()
		end
	elseif timeUntilDetonate < 6 and timeUntilDetonate >= 4 then
		if CurTime() - lastBeepWarning > 0.6 then
			self:GetOwner():EmitSound(beepSnd)
			lastBeepWarning = CurTime()
		end
	elseif timeUntilDetonate < 4 and timeUntilDetonate >= 1.5 then
		if CurTime() - lastBeepWarning > 0.2 then
			self:GetOwner():EmitSound(beepSnd)
			lastBeepWarning = CurTime()
		end
	elseif CurTime() < 1.5 and timeUntilDetonate <= 0.8 then
		if CurTime() - lastBeepWarning > 0.1 then
			self:GetOwner():EmitSound(beepSnd)
			lastBeepWarning = CurTime()
		end
	else
		if CurTime() - lastBeepWarning > 0.08 then
			self:GetOwner():EmitSound(beepSnd)
			lastBeepWarning = CurTime()
		end
	end
end
