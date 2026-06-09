-- --Logan's Zombie dispenser, now nicknamed "NPC Vault"
-- AddCSLuaFile()

-- if CLIENT then
--   ENT.Icon = "vgui/ttt/icon_zomvault"
--   ENT.PrintName = "NPC Vault"
--   surface.CreateFont("ZomVaultLarge", {
--     font = "Trebuchet24",
--     size = 28,
--     weight = 1000
--   })

--   surface.CreateFont("ZomVault", {
--     font = "Trebuchet24",
--     size = 20,
--     weight = 800
--   })

--   hook.Add("PostDrawOpaqueRenderables", "GottaDrawMyZombieVault", function(a, b)
--     local ply = LocalPlayer()
--     local pos = ply:GetShootPos()
--     local ang = ply:GetAimVector()
--     local tracedata = {}
--     tracedata.start = pos
--     tracedata.endpos = pos + (ang * 500)
--     tracedata.filter = ply

--     local trace = util.TraceLine(tracedata)
--     local vault = trace.Entity

--     if not IsValid(vault) or vault:GetClass() ~= "ttt_zombie_vault" then return end
--     pos = vault:GetPos() + Vector(0, 0, 35)

--     local eyeang = LocalPlayer():EyeAngles().y - 90
--     local ang = Angle(0, eyeang, 60)

--     if IsValid(vault) then
--       cam.Start3D2D(pos, ang, 0.1)
--       surface.SetDrawColor(0, 0, 0, 150)
--       surface.DrawRect(-150, 0, 300, 80)

--       draw.DrawText("NPC Vault", "ZomVaultLarge", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER)
--       draw.DrawText(vault:GetStatusString(), "ZomVault", 0, 28, Color(255, 255, 255), TEXT_ALIGN_CENTER)
--       draw.DrawText(vault:GetActionString(), "ZomVault", 0, 51, Color(255, 255, 255), TEXT_ALIGN_CENTER)
--       cam.End3D2D()
--     end
--   end)
-- end

-- if SERVER then
--   CreateConVar("ttt_npc_vault_max_enemies", "20", FCVAR_ARCHIVE, "The maximum amount of enemies that may be spawned by the vault at any given moment")
--   CreateConVar("ttt_npc_vault_spawn_interval", "3", FCVAR_ARCHIVE, "The time (in seconds) between enemy spawning - too low will cause enemies to spawn inside one another")
--   CreateConVar("ttt_npc_vault_deactivation_delay", "12", FCVAR_ARCHIVE, "Time (in seconds) between when you can press USE on the item (to de-/re-activate it)")
--   CreateConVar("ttt_npc_vault_sound_is_global", "0", FCVAR_ARCHIVE, "Whether or not players are globally notified of the vault activation - 0 is false, 1 is true")
-- end

-- ENT.Type = "anim"
-- ENT.Model = Model("models/props/cs_office/microwave.mdl")
-- ENT.AlreadySpawning = false

-- function ENT:Initialize()
--     self:SetModel(self.Model)

--     self:PhysicsInit(SOLID_VPHYSICS)
--     self:SetMoveType(MOVETYPE_VPHYSICS)
--     self:SetSolid(SOLID_BBOX)

--     local b = 32
--     self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

--     self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
--     if SERVER then
--        local phys = self:GetPhysicsObject()
--        if IsValid(phys) then
--           phys:SetMass(44) --200 is used on the health station, 45 is the "carry limit", I want it to be carryable
--        end

--        self:SetUseType(SIMPLE_USE)
--     end

--     self.myeffectdata = EffectData()
--     self.myeffectdata:SetOrigin(self:GetPos())

--     self.fingerprints = {}
--     self.spawnedzombies = {}

--     self:SetColor(Color(90, 90, 90, 255))
--     self:SetMaterial("phoenix_storms/metalset_1-2.vmt")
-- end

-- function ENT:Use(ply)
--   if not IsValid(ply) or not ply:IsPlayer() or not ply:IsActive() then return end

--   local t = CurTime()

--   if t > self:GetUseDelay() then --If the player should be allowed to run use on the ent, regardless of its state
--     local phys = self:GetPhysicsObject()
--     if not phys then return end

--     if self.AlreadySpawning then --If the vault is currently set to spawn zombies, TURN OFF
--       self:SetStatusString("Status: De-activating")
--       self:SetActionString("You are free to move the vault")

--       timer.Simple(GetConVar("ttt_npc_vault_deactivation_delay"):GetFloat(), function()
--         if not self then return end
--         self:SetStatusString("Status: de-activated")
--         self:SetActionString("Press [E] to re-activate")
--       end)

--       timer.Remove("DelayZombieSpawning")

--       self.AlreadySpawning = false
--       self:SetActivate(false)
--       self:EmitSound("buttons/combine_button2.wav")

--       phys:EnableMotion(true)
--     else --Else, TURN ON
--       local vel = self:GetVelocity()

--       if phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) or (math.abs(vel.x) > 20 or math.abs(vel.y) > 20 or math.abs(vel.z) > 20) then return end

--       local info = self.SpawnInfo

--       self:SetStatusString("Status: Activating")
--       self:SetActionString("The vault is now locked in place")

--       timer.Simple(GetConVar("ttt_npc_vault_deactivation_delay"):GetFloat(), function()
--         if not self then return end

--         self:SetStatusString("Status: Activated")
--         self:SetActionString("Press [E] to de-activate")
--       end)

--       self.AlreadySpawning = true
--       self:SetActivate(true)
--       self:SetActivatingPlayer(ply)
--       self:EmitSound("buttons/combine_button1.wav")

--       phys:EnableMotion(false)

--       if not table.HasValue(self.fingerprints, ply) then table.insert(self.fingerprints, ply) end

--       --I want the creation of the timer delayed a bit, so I can globally play a sound that notifies all players, which won't overlap with the local sound
--       timer.Simple(2, function()
--         local sndlvl = 70
--         if GetConVar("ttt_npc_vault_sound_is_global"):GetBool() then --If it's global, we want text, otherwise, local text would be weird, so I'm not adding it
--           for k, v in pairs(player.GetAll()) do
--             v:PrintMessage(HUD_PRINTCENTER, info.global_announce)
--             v:ChatPrint(info.global_announce)
--           end

--           sndlvl = 511
--         end

--         if istable(info.sound_announce) then
--           self:EmitSound(info.sound_announce[math.random(#info.sound_announce)], sndlvl, 95, 1, CHAN_AUTO)
--         else
--           self:EmitSound(info.sound_announce, sndlvl, 95, 1, CHAN_AUTO)
--         end

--         timer.Simple(3, function()
--           timer.Create("DelayZombieSpawning", GetConVar("ttt_npc_vault_spawn_interval"):GetFloat(), 0, function()
--             if self and IsValid(self) then
--               self:AttemptSpawn()
--             end
--           end)
--         end)
--       end)

--       --We want to accomodate the 5 seconds spent delaying the timer creation (directly above) so players can't de-activate early, adding 5 to the equation fixes this
--       t = t + 5
--     end

--     self:SetUseDelay(t + GetConVar("ttt_npc_vault_deactivation_delay"):GetFloat())
--   end
-- end

-- function ENT:SetupDataTables()
--   self:NetworkVar("Bool", 0, "Activate")
--   self:NetworkVar("Float", 0, "TotalAlive")
--   self:NetworkVar("Float", 1, "TotalAllowed")
--   self:NetworkVar("Entity", 0, "Player")
--   self:NetworkVar("Entity", 1, "ActivatingPlayer")
--   self:NetworkVar("Float", 2, "UseDelay")
--   self:NetworkVar("String", 0, "StatusString")
--   self:NetworkVar("String", 1, "ActionString")

--   if SERVER then
--     self:SetActivate(false)
--     self:SetTotalAlive(0)
--     self:SetTotalAllowed(GetConVar("ttt_npc_vault_max_enemies"):GetFloat())
--     self:SetPlayer(nil)
--     self:SetActivatingPlayer(nil)
--     self:SetUseDelay(GetConVar("ttt_npc_vault_deactivation_delay"):GetFloat() + 5)
--     self:SetStatusString("Status: Inactive")
--     self:SetActionString("Press [E] to activate")
--   end
-- end

-- function ENT:AttemptSpawn()
--     if not self:GetActivate() then return end

--     if self:GetTotalAlive() <= self:GetTotalAllowed() then
--         local info = self.SpawnInfo

--         local zombie = ents.Create(info.spawn_ent)
--         zombie:SetPos(Vector(self:GetPos()[1], self:GetPos()[2], self:GetPos()[3] + 10))
--         zombie:Spawn()
--         zombie:PhysWake()
--         zombie:SetColor(Color(150, 100, 100))

--         if IsValid(self:GetActivatingPlayer()) then
--           zombie.ActivatingPlayer = self:GetActivatingPlayer()
--         end

--         timer.Simple(0, function()
--             if IsValid(zombie) then
--                 info.PostSpawnFunc(zombie, self)
--             end
--         end)

--         zombie.Vault = self

--         local sndlvl = 120
--         if GetConVar("ttt_npc_vault_sound_is_global"):GetBool() then sndlvl = 511 end
--         self:EmitSound("ambient/machines/thumper_hit.wav", sndlvl, 95, 0.80, CHAN_AUTO)

--         self.myeffectdata:SetOrigin(Vector(self:GetPos()[1], self:GetPos()[2], self:GetPos()[3] + 20))
--         util.Effect("VortDispel", self.myeffectdata, true, true)
--         self:SetTotalAlive(self:GetTotalAlive() + 1)
--     end
-- end

-- hook.Add("OnNPCKilled", "DecrementAliveCountOnKill", function(npc, attacker, inflictor)
--   if npc.Vault then
--     npc.Vault:SetTotalAlive(npc.Vault:GetTotalAlive() - 1)
--   end
-- end)

-- hook.Add("EntityTakeDamage", "gmcore.ZombieVault.AttributeActivator", function(victim, dmginfo)
--   local attacker = dmginfo:GetAttacker()

--   -- Check if attacker is an NPC with a vault and an activating player
--   if IsValid(attacker) and attacker:IsNPC() and attacker.Vault and IsValid(attacker.ActivatingPlayer) then
--     dmginfo:SetAttacker(attacker.ActivatingPlayer)
--   end
-- end)

-- if SERVER then
--     local TrackPeriod = 0
--     hook.Add("Think", "AntlionTracking", function()
--         if CurTime() > TrackPeriod then
--         --Snagged from the wiki, made it my own
--         --timer.Create("AntlionPathing", 0.05, 0, function()
--             local antlions = ents.GetAll()
--             local players = player.GetAll()

--             for k, v in ipairs( players ) do
--                 if not v:Alive() then
--                     players[k] = nil
--                 end
--             end

--             if #players == 0 then
--                 for _, ent in pairs(antlions) do
--                     if ent:GetClass() == "npc_antlion" then
--                         ent:SetSchedule(SCHED_IDLE_WANDER)
--                     end
--                 end
--                 return
--             end

--             local playerpositions = {}
--             for _, v in ipairs(players) do
--                 playerpositions[v] = v:GetPos()
--             end

--             for _, ent in ipairs(antlions) do
--                 if ent:GetClass() == "npc_antlion" and not IsValid(ent:GetEnemy()) then
--                     local currentply
--                     local currentplypos
--                     local currentdist = math.huge
--                     local npcpos = ent:GetPos()

--                     for _, ply in pairs(players) do
--                         local dist = npcpos:DistToSqr(ply:GetPos())

--                         if dist < currentdist then
--                             currentply = ply
--                             currentplypos = ply:GetPos()
--                             currentdist = dist
--                         end
--                     end

--                     if currentdist > 10000 then
--                         ent:SetSchedule(SCHED_IDLE_WANDER)
--                     else
--                         ent:SetEnemy(currentply)
--                         ent:UpdateEnemyMemory(currentply, currentplypos)
--                     end
--                 end
--             end

--             TrackPeriod = CurTime() + 0.01
--         end
--     end )
-- end
