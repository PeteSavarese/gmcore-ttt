-- --[[Author's information]]--
-- --Much of this used is from the health station
-- SWEP.Author = "Logan Christianson"
-- SWEP.Contact = "http://steamcommunity.com/id/LoganChristianson"

-- -- Replace SWEP.TypeInfo with a single default spawn info (always fast zombies - GMod base)
-- local DEFAULT_SPAWNINFO = {
--     display_text = "Fast Zombies (GMod Base)",
--     global_announce = "THE DEAD WALK THE EARTH. ARE YOU PREPARED?",
--     sound_announce = "ambient/creatures/town_zombie_call1.wav",
--     spawn_ent = "npc_fastzombie",
--     PostSpawnFunc = function(enemy, spawner)
--       enemy:SetSchedule(SCHED_ALERT_WALK)
--       enemy:NavSetWanderGoal(100, 100)

--       if #spawner.spawnedzombies > 0 then
--         for k, v in pairs(spawner.spawnedzombies) do
--           constraint.NoCollide(enemy, v, 0, 0)
--         end
--       end

--       spawner.spawnedzombies[#spawner.spawnedzombies + 1] = enemy
--     end
-- }

-- AddCSLuaFile()

-- SWEP.HoldType               = "normal"

-- if CLIENT then
--    SWEP.PrintName           = "NPC Vault"
--    SWEP.Slot                = 6

--    SWEP.ViewModelFOV        = 10
--    SWEP.DrawCrosshair       = false

--    SWEP.EquipMenuData = {
--       type = "item_weapon",
--       desc = [[Spawn zombies where thrown. Vault locks in
-- place when turned.
-- Large room = roam, small room = turtle.]]
--    };

--    SWEP.Icon                = "vgui/ttt/icon_zomvault"
-- end

-- SWEP.Base                   = "weapon_tttbase"

-- SWEP.ViewModel              = "models/weapons/v_crowbar.mdl"
-- SWEP.WorldModel             = "models/props/cs_office/microwave.mdl"

-- SWEP.Primary.ClipSize       = -1
-- SWEP.Primary.DefaultClip    = -1
-- SWEP.Primary.Automatic      = true
-- SWEP.Primary.Ammo           = "none"
-- SWEP.Primary.Delay          = 1.0

-- SWEP.Secondary.ClipSize     = -1
-- SWEP.Secondary.DefaultClip  = -1
-- SWEP.Secondary.Automatic    = true
-- SWEP.Secondary.Ammo         = "none"
-- SWEP.Secondary.Delay        = 1.0

-- -- This is special equipment
-- SWEP.Kind                   = WEAPON_EQUIP
-- SWEP.CanBuy                 = {} -- only traitors can buy
-- SWEP.LimitedStock           = true -- only buyable once

-- SWEP.AllowDrop              = false
-- SWEP.NoSights               = true

-- function SWEP:Initialize()
--   -- Keep the function present for any base initialisation needs
-- end

-- function SWEP:OnDrop()
--   self:Remove()
-- end

-- function SWEP:PrimaryAttack()
--   self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
--   self:SpawnerDrop()
-- end

-- function SWEP:SecondaryAttack()
--   self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
--   self:SpawnerDrop()
-- end

-- local throwsound = Sound( "Weapon_SLAM.SatchelThrow" )

-- function SWEP:SpawnerDrop()
--   if SERVER then
--     local ply = self:GetOwner()
--     if not IsValid(ply) then return end

--     local vsrc = ply:GetShootPos()
--     local vang = ply:GetAimVector()
--     local vvel = ply:GetVelocity()
--     local vthrow = vvel + vang * 125
--     local vault = ents.Create("ttt_zombie_vault")

--     if IsValid(vault) then
--       vault:SetPos(vsrc + vang * 10)
--       -- Always use the default fast-zombie spawn info
--       vault.SpawnInfo = DEFAULT_SPAWNINFO
--       vault:Spawn()
--       vault:SetPlayer(ply)
--       vault:PhysWake()

--       local phys = vault:GetPhysicsObject()
--       if IsValid(phys) then phys:SetVelocity(vthrow) end

--       self:Remove()
--       self.Planted = true
--     end
--   end

--   self:EmitSound(throwsound)
-- end

-- function SWEP:Reload()
--   return false
-- end

-- function SWEP:OnRemove()
--   if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
--     RunConsoleCommand("lastinv")
--   end
-- end

-- function SWEP:Deploy()
--   if SERVER and IsValid(self:GetOwner()) then
--     self:GetOwner():DrawViewModel(false)
--   end

--   return true
-- end

-- function SWEP:DrawWorldModel()
-- end

-- function SWEP:DrawWorldModelTranslucent()
-- end
