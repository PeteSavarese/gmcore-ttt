AddCSLuaFile()

SWEP.HoldType			= "pistol"

if CLIENT then
	SWEP.PrintName = "Malfunction Pistol"
	SWEP.Slot = 6

	SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "Forces the player you shoot to fire\nan uncontrolled round of shots."
	};

	SWEP.Icon = "vgui/ttt/icon_gl_malfunction_pistol"
	SWEP.IconLetter = "a"
	SWEP.ViewModelFOV = 70
end

SWEP.Base = "weapon_tttbase"
SWEP.Primary.Recoil	= 1.35
SWEP.Primary.Damage = 0
SWEP.Primary.Delay = 0.38
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 12
SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 12
SWEP.Primary.ClipMax = 12

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy
SWEP.WeaponID = AMMO_MALFUNCTIONGUN

SWEP.IsSilent = true

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModel  = "models/weapons/malfunction_pistol/c_csgo_usp.mdl"
SWEP.WorldModel = "models/weapons/malfunction_pistol/w_pist_223.mdl"

SWEP.Primary.Sound = Sound("weapons/usp/usp1.wav")
SWEP.Primary.SoundLevel = 50

SWEP.IronSightsPos = Vector(-0, -4, 0)
SWEP.IronSightsAng = Vector(-0.5, 0, 0)

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim = ACT_VM_RELOAD_SILENCED

local weaponfilter = {}
weaponfilter["weapon_zm_improvised"] = true
weaponfilter["weapon_ttt_unarmed"] = true
weaponfilter["weapon_zm_carry"] = true
weaponfilter["weapon_ttt_confgrenade"] = true
weaponfilter["weapon_ttt_smokegrenade"] = true
weaponfilter["weapon_zm_molotov"] = true

---Forces target player to fire their weapon repeatedly in bursts
---If active weapon has no ammo, switch to another weapon and fires for a duration based on clip size
---Attacker is recorded for credit if chain upgrade is equipped
---@param attacker Player player who shot the malfunction pistol
---@param target Player player being forced to shoot
local function forceTargetToShoot(attacker, target)
	if not SERVER then return end
	if not GAMEMODE:AllowPVP() then return end -- disable if pre/post round
	if not target:IsPlayer() then return end

	---@class SWEP
	local targetPlyActiveWeapon = target:GetActiveWeapon()

	if not IsValid(targetPlyActiveWeapon) or not targetPlyActiveWeapon.Primary then return end

	local function getClipSize(wep)
		if not IsValid(wep) or not wep.Primary then return 0 end

		return wep.Primary.ClipSize or 0
	end

	local function getDelay(wep)
		if not IsValid(wep) or not wep.Primary then return 0.1 end

		return wep.Primary.Delay or 0.1
	end

	local repeats = 1
	local targetPlyClipSize = getClipSize(targetPlyActiveWeapon)

	if targetPlyClipSize <= 0 then
		local weapons = target:GetWeapons()
		local preferedWeapons = {}

		for k, v in pairs(weapons) do
			if IsValid(v) and (not weaponfilter[v:GetClass()]) and v.Primary and (v.Primary.ClipSize or 0) > 0 then
				table.insert(preferedWeapons, v)
			end
		end

		-- if #weapons >= 4 then
		-- for i=4,#weapons do
		-- if weapons[i] then
		-- if weapons[i]:GetClass() ~= "weapon_ttt_confgrenade" and weapons[i]:GetClass() ~= "weapon_ttt_smokegrenade" and weapons[i]:GetClass() ~= "weapon_zm_molotov" then
		-- table.insert(preferedWeapons,i)
		-- end
		-- end
		-- end
		-- end

		if #preferedWeapons > 0 then
			target:SelectWeapon(preferedWeapons[math.random(1, #preferedWeapons)]:GetClass())
			-- Re-fetch active weapon after switching to get new delay
			targetPlyActiveWeapon = target:GetActiveWeapon()

			if not IsValid(targetPlyActiveWeapon) or not targetPlyActiveWeapon.Primary then return end

			targetPlyClipSize = getClipSize(targetPlyActiveWeapon)

			if targetPlyClipSize <= 0 then return end

			repeats = (targetPlyClipSize / 2) + math.random(-targetPlyClipSize * 0.05, targetPlyClipSize * 0.05)
		else
			-- nothing suitable found to use
			return
		end
	else
		repeats = (targetPlyClipSize / 2) + math.random(-targetPlyClipSize * 0.05, targetPlyClipSize * 0.05)
	end

	target.isUnderMalfunctionInfluence = attacker

	repeats = math.floor(repeats + 0.5)
	if repeats < 1 then repeats = 1 end

	local fireTimerName = "gmcore.MalfunctionPistol.InfluenceFireWeapon" .. tostring(target:SteamID64())
	local disableTimerName = "gmcore.MalfunctionPistol.DisableInfluence" .. tostring(target:SteamID64())

	-- Avoid stacking timers if target is hit repeatedly
	timer.Remove(fireTimerName)
	timer.Remove(disableTimerName)

	local initialDelay = getDelay(targetPlyActiveWeapon)

	timer.Create(fireTimerName, initialDelay, repeats, function()
		---@class SWEP
		local w = target:GetActiveWeapon()

		if IsValid(w) and w.Primary then
			w:PrimaryAttack()

			timer.Adjust(fireTimerName, getDelay(w))
		end
	end)

	timer.Create(disableTimerName, initialDelay * repeats + 0.1, 1, function()
		if IsValid(target) then
			target.isUnderMalfunctionInfluence = nil
		end
	end)
end


---Since forceTargetToShoot only takes 2 args (attacker and target) but bullet callback has 3 params, only select what we need then forward to forceTargetToShoot
---@param ply Player Original ply ent that shot bullet
---@param path TraceResult Path table of player's trace
---@param dmginfo CTakeDamageInfo CDamageInfo of damage... not used
local function forwardCallbackToFunction(ply, path, dmginfo)
	---@class Entity
	local target = path.Entity

	if not IsValid(target) then return end
	if not target:IsPlayer() then return end
	---@cast target Player

	forceTargetToShoot(ply, target)
end

local function overrideMalfunctionAttacker(target, dmg)
	local attacker = dmg:GetAttacker()

	if attacker.isUnderMalfunctionInfluence then
		local originalMalfunctionAttacker = attacker.isUnderMalfunctionInfluence

		dmg:SetAttacker(originalMalfunctionAttacker)

		if IsValid(originalMalfunctionAttacker) and originalMalfunctionAttacker:PS_HasItemEquipped("upgrade_malfunction_chain") then
			forceTargetToShoot(originalMalfunctionAttacker, target)
		end
	end
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
	self.BaseClass.Deploy(self)
	return true
end

-- We were bought as special equipment, and we have an extra to give
function SWEP:WasBought(buyer)
	-- probably already self:GetOwner()
	if IsValid(buyer) then
		buyer:GiveAmmo(3, "Pistol")
	end
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if not self:CanPrimaryAttack() then return end

	self:EmitSound(self.Primary.Sound)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:ShootMalfunctionBullet()
	self:TakePrimaryAmmo(1)

	if IsValid(self:GetOwner()) then
		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
		self:GetOwner():ViewPunch(Angle(math.Rand(-0.2, -0.1) * self.Primary.Recoil, math.Rand(-0.1, 0.1) * self.Primary.Recoil, 0))
	end

	if ((game.SinglePlayer() and SERVER) or CLIENT) then
		self:SetNWFloat("LastShootTime", CurTime())
	end
end

function SWEP:ShootMalfunctionBullet()
	local cone = self.Primary.Cone
	local bullet = {}
	bullet.Num = 1
	bullet.Src = self:GetOwner():GetShootPos()
	bullet.Dir = self:GetOwner():GetAimVector()
	bullet.Spread = Vector(cone, cone, 0)
	bullet.Tracer = 1
	bullet.Force = 2
	bullet.Damage = self.Primary.Damage
	bullet.TracerName = self.Tracer
	bullet.Callback = forwardCallbackToFunction -- Send for selection which then sends to forceTargetToShoot

	self:GetOwner():FireBullets(bullet)
end

hook.Add("EntityTakeDamage", "gmcore.Weapons.OverrideMalfunctionAttacker", overrideMalfunctionAttacker)
