-- if SERVER then
--   AddCSLuaFile()
--   game.AddDecal("demonic_pentagram", "decals/demonic_pentagram")
--   game.AddDecal("demonic_pentagram_flaming", "decals/demonic_pentagram_flaming")
--   game.AddDecal("demonic_scorch", "decals/demonic_scorch")
-- end

-- local maximumDemonicPower = CreateConVar("ttt_demonic_power_max", 400, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The maximum amount of Demonic Power.")
-- local demonicPowerRegen = CreateConVar("ttt_demonic_power_regen", 10, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The Demonic Power regenerated per second")
-- local attackCost = CreateConVar("ttt_demonic_power_req_attack", 50, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The Demonic Power required to do an attack.")
-- local moveCost = CreateConVar("ttt_demonic_power_req_move", 20, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The Demonic Power per second required to move.")
-- local takeOverCost = CreateConVar("ttt_demonic_power_req_take_over", maximumDemonicPower:GetInt(), {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The Demonic Power required to take over the victim.")

-- SWEP.PrintName = "Demonic Possession"
-- SWEP.Slot = 7
-- SWEP.Icon = "vgui/ttt/icon_gl_demonic_possession.png"
-- SWEP.Base = "weapon_tttbase"
-- SWEP.Spawnable = false
-- SWEP.Kind = 142
-- SWEP.AutoSpawnable = false
-- SWEP.CanBuy = {}
-- SWEP.LimitedStock = true
-- SWEP.DeploySpeed = 0.01
-- SWEP.Primary.Ammo = "none"
-- --SWEP.Primary.Recoil			= 8
-- --SWEP.Primary.Damage = 24
-- --SWEP.Primary.Delay = 0.8
-- SWEP.Primary.Cone = 0
-- SWEP.Primary.ClipSize = 1
-- SWEP.Primary.ClipMax = 1
-- SWEP.Primary.DefaultClip = 1
-- SWEP.Primary.Automatic = false
-- SWEP.AutoSpawnable = false
-- SWEP.ViewModelFlip = false
-- SWEP.DrawCrosshair = false
-- SWEP.UseHands = true
-- SWEP.ViewModelFOV = 54
-- SWEP.ViewModel = "models/weapons/v_knife_t.mdl"
-- SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
-- local function ShadowedText(text, font, x, y, color, xalign, yalign)
--   draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
--   draw.SimpleText(text, font, x, y, color, xalign, yalign)
-- end

-- SWEP.EquipMenuData = {
--   type = "item_weapon",
--   desc = [[Place your demonic sign on the ground and
-- take control of another player when they step
-- on it after your death.]]
-- }

-- local function PaintDownReverse(start, effname, ignore)
--   local btr = util.TraceLine({
--     start = start,
--     endpos = start + Vector(0, 0, -256),
--     filter = ignore,
--     mask = MASK_SOLID,
--     collisiongroup = COLLISION_GROUP_WORLD
--   })

--   util.Decal(effname, btr.HitPos - btr.HitNormal, btr.HitPos + btr.HitNormal)
-- end

-- function SWEP:Initialize()
--   self.deployed = false
--   self:SetWeaponHoldType("knife")
--   self:SetNoDraw(true)
--   self.RealHitPos = self:GetPos()
--   self.IsActive = false
--   self.Used = false
--   self.PlayerTrapped = false
--   self.demonMove = nil
--   self.attacking = false
--   self.jumping = false
--   self.crouching = false
--   self.reloading = false
--   self.forward = false
--   self.backward = false
--   self.left = false
--   self.right = false
--   self.movementForward = 0
--   self.sidewarsMovement = 0
--   self.upMove = 0
--   self.MouseX = 0
--   self.MouseY = 0
--   self.victim = nil
--   self.viewAngles = Angle(0, 0, 0)
--   self.attacked = CurTime()
--   self.killedVictim = false
--   self.DemonicPower = 50
--   self.DemonicMaxPower = maximumDemonicPower:GetInt()
--   self.Timer = false
--   self.Hits = 0
--   self.MovePressed = false
--   self.IsMoving = false
--   self.PossessedVictim = nil

--   hook.Add("PlayerCanPickupWeapon", "DemonicPossession_noDoublePickup", function(ply, wep)
--     if wep:GetClass() == "weapon_ttt_demonsign" or wep:GetClass() == "weapon_ttt_demonsign_tttc" and wep.Used then
--       return false
--     end
--   end)
-- end

-- function SWEP:PrimaryAttack()
--   --Draw the sign on the ground
--   self.RealHitPos = self:GetOwner():GetEyeTrace().HitPos

--   if self.RealHitPos:Distance(self:GetOwner():EyePos()) > 100 or not self:GetOwner():GetEyeTrace().Entity:IsWorld() then return end

--   local btr = util.TraceLine({
--     start = self:GetOwner():EyePos() + self:GetOwner():GetAimVector() * 2,
--     endpos = self:GetOwner():EyePos() + self:GetOwner():GetAimVector() * 200,
--     filter = function(ent) if ent:IsWorld() then return true end end,
--     mask = MASK_SOLID,
--     collisiongroup = COLLISION_GROUP_WORLD
--   })

--   if btr.HitPos:Distance(self:GetOwner():EyePos()) > 100 then return end

--   self.RealHitPos = btr.HitPos
--   self.eyePos = self:GetOwner():EyePos()
--   self.aimVector = self:GetOwner():GetAimVector()

--   if SERVER then
--     util.PaintDown(self.RealHitPos, "demonic_pentagram", function(ent) if ent:IsWorld() then return true end end)
--     PaintDownReverse(self.RealHitPos, "demonic_pentagram", function(ent) if ent:IsWorld() then return true end end)
--   end

--   self.Used = true

--   hook.Add("Think", "Demon_KillPentagram" .. self:GetOwner():Nick(), function()
--     if not IsValid(self) or not self.Used or not self.PlayerTrapped then return end

--     for k, v in pairs(ents.FindByClass("env_fire")) do
--       if v:GetPos():Distance(self.RealHitPos) >= 90 then continue end

--       self.PlayerTrapped = true

--       if SERVER then
--         util.PaintDown(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         util.PaintDown(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         util.PaintDown(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)

--         PaintDownReverse(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         PaintDownReverse(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         PaintDownReverse(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--       end
--     end
--   end)

--   hook.Add("PostPlayerDeath", "Demonic_MakePentagramFlaming" .. self:GetOwner():Nick(), function(ply, attacker, dmg)
--     if IsValid(self) and ply == self.LastOwner and self.Used and not self.PlayerTrapped and (self.LastOwner.NOWINASC == nil or not self.LastOwner.NOWINASC) then
--       timer.Create("Demon_MakeActiveAfterDeath" .. self.LastOwner:Nick(), 0.05, 1, function() self.IsActive = true end)

--       if SERVER then
--         util.PaintDown(self.RealHitPos, "demonic_pentagram_flaming", function(ent) if ent:IsWorld() then return true end end)
--         PaintDownReverse(self.RealHitPos, "demonic_pentagram_flaming", function(ent) if ent:IsWorld() then return true end end)
--       end
--     end

--     if IsValid(self) and IsValid(self.PossessedVictim) and ply == self.PossessedVictim then
--       ply.PossessedBy = nil
--     end
--   end)

--   local function FindCorpse(ply) -- From TTT Ulx Commands, sorry - from Gamefreak, sorry :P
--     for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
--       if ent.uqid == ply:UniqueID() and IsValid(ent) then return ent or false end
--     end
--   end

--   hook.Add("PlayerPostThink", "Demon_WalkOverSign" .. self:GetOwner():Nick(), function(ply)
--     if IsValid(self)
--       and self.Used
--       and not self.PlayerTrapped
--       and IsValid(ply)
--       and IsValid(self.LastOwner)
--       and not self.LastOwner:Alive()
--       and ply:Alive()
--       and ply != self.LastOwner
--       and ply:GetPos():Distance(self.RealHitPos) <= 35
--       and self.IsActive
--       and ply:IsTerror()
--       and (not (ply.IsTraitor and ply:IsTraitor()))
--     then
--       if SERVER then
--         util.PaintDown(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         util.PaintDown(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         util.PaintDown(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)

--         PaintDownReverse(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         PaintDownReverse(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--         PaintDownReverse(self.RealHitPos, "demonic_scorch", function(ent) if ent:IsWorld() then return true end end)
--       end

--       --set state variables for server and client
--       self.PlayerTrapped = true
--       self.PossessedVictim = ply
--       ply.PossessedBy = self.LastOwner
--       ply.ForcedAttack = false

--       self.victim = ply
--       self:SetNWBool(self.trappedVariable, true)
--       self:SetNWEntity(self.victimVariable, self.victim)

--       --let the owner spectate victim
--       self.LastOwner:Spectate(OBS_MODE_IN_EYE)
--       self.LastOwner:SpectateEntity(ply)
--       self.viewAngles = self.victim:EyeAngles()
--     end
--   end)

--   -- Use a hook id based on the current owner to avoid indexing nil LastOwner
--   local startCmdHookId = "Demon_MoveVictim" .. (IsValid(self:GetOwner()) and self:GetOwner():Nick() or tostring(math.random()))

--   hook.Add("StartCommand", startCmdHookId, function(player, ucmd)
--     -- Ensure the weapon entity still exists; if not, remove the hook to avoid future errors
--     if not IsValid(self) then
--       hook.Remove("StartCommand", startCmdHookId)
--       print("Demon_MoveVictim hook removed: weapon is no longer valid.")

--       return
--     end

--     -- Ensure the NW var key exists before using it
--     if not self.victimVariable then return end

--     self.victim = self:GetNWEntity(self.victimVariable)

--     if IsValid(player) and IsValid(self.LastOwner) and IsValid(self.victim) and player == self.LastOwner and not self.killedVictim and self.victim:Alive() then
--       if not self:GetNWBool(self.DemonModeActivatedVariable) and ucmd:KeyDown(IN_RELOAD) and SERVER then self:SetNWBool(self.DemonModeActivatedVariable, true) end
--       self.attacking = ucmd:KeyDown(IN_ATTACK)
--       self.reloading = ucmd:KeyDown(IN_RELOAD)
--       self.jumping = ucmd:KeyDown(IN_JUMP)
--       self.crouching = ucmd:KeyDown(IN_DUCK)
--       self.forward = ucmd:KeyDown(IN_FORWARD)
--       self.backward = ucmd:KeyDown(IN_BACK)
--       self.left = ucmd:KeyDown(IN_MOVELEFT)
--       self.right = ucmd:KeyDown(IN_MOVERIGHT)
--       self.movementForward = ucmd:GetForwardMove()
--       self.sidewarsMovement = ucmd:GetSideMove()
--       self.upMove = ucmd:GetUpMove()
--       self.MouseX = ucmd:GetMouseX()
--       self.MouseY = ucmd:GetMouseY()
--       --if(ucmd:KeyDown(IN_ATTACK)) then print("attacing") self.attacking = true end
--       if SERVER then self.demonMove = ucmd end
--       ucmd:SetViewAngles(self.victim:EyeAngles())
--       self.LastOwner:SetPos(self.victim:GetPos() + self.victim:GetAimVector() * 10)
--       --ucmd:SetMouseX(0)
--       --ucmd:SetMouseY(0)
--       if SERVER then
--         ucmd:ClearButtons()
--         self.LastOwner:Spectate(OBS_MODE_IN_EYE)
--         self.LastOwner:SpectateEntity(self.victim)
--       end
--       --print(player)
--     end

--     if IsValid(player) and IsValid(self.victim) and player == self.victim and self.demonMove != nil and not self.killedVictim and self.victim:Alive() then
--       --print(player, ucmd:GetViewAngles(), self.demonMove:GetViewAngles())
--       --print(self.demonMove:GetMouseX(), self.demonMove:GetMouseY())
--       --print(self.DemonicPower, self.DemonicMaxPower)
--       --do an attack
--       if self:GetNWBool(self.DemonModeActivatedVariable) and self.attacking and self.attacked + 0.5 <= CurTime() and self.DemonicPower >= attackCost:GetInt() then
--         self.attacked = CurTime()
--         ucmd:SetButtons(ucmd:GetButtons() + IN_ATTACK)
--         self.DemonicPower = self.DemonicPower - attackCost:GetInt()
--         self:SetNWFloat(self.DemonicPowerVariable, self.DemonicPower)
--         self.victim.ForcedAttack = true
--       end

--       if self:GetNWBool(self.DemonModeActivatedVariable) and self.reloading and self.DemonicPower >= takeOverCost:GetInt() then
--         self.DemonicPower = 0
--         self:SetNWFloat(self.DemonicPowerVariable, self.DemonicPower)
--         --copy victims state
--         local victim = self.victim
--         local victimPos = victim:GetPos()
--         local victimAngles = victim:EyeAngles()
--         local victimHealth = victim:Health()
--         local victimMaxHealth = 100
--         if SERVER then victimMaxHealth = victim:GetMaxHealth() end
--         --print(victimHealth, victimMaxHealth)
--         local weapons = victim:GetWeapons()
--         local activeWeapon = victim:GetActiveWeapon():GetClass()
--         local ammoCount = {}
--         for i = 1, 30 do
--           ammoCount[i] = victim:GetAmmoCount(i)
--         end

--         local corpse = FindCorpse(self.LastOwner)
--         if IsValid(corpse) then corpse:Remove() end

--         --kill victim and let the player spawn instead
--         victim:StripWeapons()
--         victim:SetPos(victim:GetPos() - victim:EyeAngles():Forward() * 30)
--         victim:TakeDamage(1000)

--         corpse = FindCorpse(victim)

--         if IsValid(corpse) then corpse:Remove() end

--         self.LastOwner:SpawnForRound(true)

--         --give the player the same state as the victim
--         self.LastOwner:SetPos(victimPos)
--         self.LastOwner:SetEyeAngles(victimAngles)
--         self.LastOwner:SetHealth(victimHealth)

--         if SERVER then self.LastOwner:SetMaxHealth(victimMaxHealth) end

--         for k, v in pairs(weapons) do
--           --print(v)
--           local wep = self.LastOwner:Give(v:GetClass(), true)
--           if IsValid(wep) then
--             wep:SetClip1(v:Clip1())
--             wep:SetClip2(v:Clip2())
--           end
--           --self.LastOwner:PickupObject(v)
--         end

--         for i = 1, 30 do
--           --print(ammoCount[i])
--           self.LastOwner:GiveAmmo(ammoCount[i], i)
--         end

--         self.LastOwner:SelectWeapon(activeWeapon)
--         --SendFullStateUpdate()
--         self.killedVictim = true
--         self.PossessedVictim = nil
--         victim.PossessedBy = nil
--         victim.ForcedAttack = nil
--       end

--       --trigger movement via the standard movebuttons and let the player move until he is at 0 demonPower but only trigger movement if he is 20+
--       if self:GetNWBool(self.DemonModeActivatedVariable) and (self.forward or self.backward or self.left or self.right or self.crouching or self.jumping) and (self.DemonicPower >= moveCost:GetInt() or self.IsMoving) then self.MovePressed = true end
--       if not self.IsMoving and self.MovePressed then
--         self.IsMoving = true
--         --print("moving started")
--       elseif self.IsMoving and not self.MovePressed then
--         self.IsMoving = false
--         --print("moving ended")
--       end

--       self.MovePressed = false
--       if self.IsMoving then
--         self.viewAngles = Angle(self.viewAngles.p + self.MouseY / 30, self.viewAngles.y - self.MouseX / 30, 0)
--         self.viewAngles.p = math.Clamp(self.viewAngles.p, -89, 89)
--         ucmd:SetViewAngles(self.viewAngles)
--         --ucmd:SetViewAngles(self.viewAngles)
--         --ucmd:SetMouseX(self.demonMove:GetMouseX())
--         --ucmd:SetMouseY(self.demonMove:GetMouseY())
--         ucmd:SetForwardMove(self.movementForward)
--         ucmd:SetSideMove(self.sidewarsMovement)
--         ucmd:SetUpMove(self.upMove)
--         if self.crouching and not ucmd:KeyDown(IN_DUCK) then ucmd:SetButtons(ucmd:GetButtons() + IN_DUCK) end
--         if self.jumping and not ucmd:KeyDown(IN_JUMP) then ucmd:SetButtons(ucmd:GetButtons() + IN_JUMP) end
--         --self.DemonicPower = self.DemonicPower - 0.4
--         self:SetNWFloat(self.DemonicPowerVariable, self.DemonicPower)
--       else
--         self.viewAngles = ucmd:GetViewAngles()
--       end

--       if self.DemonicPower < 1 then
--         --print("moving canceled")
--         self.MovePressed = false
--         self.IsMoving = false
--       end
--       --print(ucmd:GetViewAngles())
--     end
--   end)

--   if CLIENT then
--     surface.CreateFont("HealthAmmo", {
--       font = "Trebuchet24",
--       size = 24,
--       weight = 750
--     })

--     surface.CreateFont("StartHint", {
--       font = "Trebuchet24",
--       size = 24,
--       weight = 750
--     })

--     surface.CreateFont("UseHintCaption", {
--       font = "Trebuchet24",
--       size = 24,
--       weight = 750
--     })

--     surface.CreateFont("UseHint", {
--       font = "Trebuchet24",
--       size = 18,
--       weight = 750
--     })
--   end

--   hook.Add("HUDPaint", "Demon_HUD" .. self:GetOwner():Nick(), function()
--     if IsValid(self) and IsValid(self.LastOwner) and self:GetNWBool(self.trappedVariable) and IsValid(self:GetNWEntity(self.victimVariable)) and LocalPlayer() == self.LastOwner and self:GetNWEntity(self.victimVariable):Alive() then
--       if not self:GetNWBool(self.DemonModeActivatedVariable) then
--         ShadowedText("Press R (Reload) to start taking control over your victim!", "StartHint", ScrW() / 2, ScrH() / 2 - 50, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
--       else
--         local width = 200 / 1.5
--         --draw.RoundedBox( 8, ScrW() / 2 - 200, 50 - (26 / 2), self.DemonicMaxPower, 26 , Color(20, 20, 5, 222) )
--         --draw.RoundedBox( 8, ScrW() / 2 - 200, 50 - (26 / 2), self:GetNWFloat(self.DemonicPowerVariable), 26 , Color(205, 155, 0, 255) )

--         --ShadowedText(tostring(math.floor(self:GetNWFloat(self.DemonicPowerVariable))) .. " / " .. tostring(self.DemonicMaxPower), "HealthAmmo", ScrW() / 2 , 50 - (26 / 2), COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT)
--         draw.RoundedBox(8, 50 + ScrW() / 7 - (self.DemonicMaxPower / 2), ScrH() / 2 - ScrH() / 14 - 40, self.DemonicMaxPower, 26, Color(20, 20, 5, 222))
--         draw.RoundedBox(8, 50 + ScrW() / 7 - (self.DemonicMaxPower / 2), ScrH() / 2 - ScrH() / 14 - 40, self:GetNWFloat(self.DemonicPowerVariable), 26, Color(205, 155, 0, 255))
--         ShadowedText(tostring(math.floor(self:GetNWFloat(self.DemonicPowerVariable))) .. " / " .. tostring(self.DemonicMaxPower), "HealthAmmo", 50 + ScrW() / 7, ScrH() / 2 - ScrH() / 14 - 40, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT)

--         --draw hintbox
--         draw.RoundedBox(8, 50, ScrH() / 2 - ScrH() / 14, ScrW() / 3.5, ScrH() / 7, Color(20, 20, 5, 222))
--         draw.RoundedBox(8, 50, ScrH() / 2 - ScrH() / 14, ScrW() / 3.5, 42, Color(20, 20, 5, 240))

--         ShadowedText("Avaiable Commands", "UseHintCaption", 50 + ScrW() / 7, ScrH() / 2 - ScrH() / 14 + 20, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

--         local dp = self:GetNWFloat(self.DemonicPowerVariable)
--         ShadowedText("Move Keys", "UseHint", 50 + 20, ScrH() / 2 - ScrH() / 14 + 60, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT)
--         ShadowedText("Move and control the camera", "UseHint", 50 + ScrW() / 7, ScrH() / 2 - ScrH() / 14 + 60, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT)
--         ShadowedText(tostring(moveCost:GetInt()) .. " Power/s", "UseHint", 50 + ScrW() / 3.5 - 20, ScrH() / 2 - ScrH() / 14 + 60, dp >= moveCost:GetInt() and COLOR_GREEN or COLOR_RED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)
--         ShadowedText("Left Click", "UseHint", 50 + 20, ScrH() / 2 - ScrH() / 14 + 95, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT)
--         ShadowedText("Attack", "UseHint", 50 + ScrW() / 7, ScrH() / 2 - ScrH() / 14 + 95, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT)
--         ShadowedText(tostring(attackCost:GetInt()) .. " Power", "UseHint", 50 + ScrW() / 3.5 - 20, ScrH() / 2 - ScrH() / 14 + 95, dp >= attackCost:GetInt() and COLOR_GREEN or COLOR_RED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)
--         ShadowedText("R", "UseHint", 50 + 20, ScrH() / 2 - ScrH() / 14 + 130, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT)
--         ShadowedText("Kill your victim and play instead", "UseHint", 50 + ScrW() / 7, ScrH() / 2 - ScrH() / 14 + 130, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT)
--         ShadowedText(tostring(takeOverCost:GetInt()) .. " Power", "UseHint", 50 + ScrW() / 3.5 - 20, ScrH() / 2 - ScrH() / 14 + 130, dp >= takeOverCost:GetInt() and COLOR_GREEN or COLOR_RED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)
--       end
--     end
--   end)

--   hook.Add("PlayerPostThink", "Demon_CopyVictimsInventory" .. self:GetOwner():Nick(), function(ply)
--     if IsValid(self) and IsValid(self.LastOwner) and self:GetNWBool(self.trappedVariable) and IsValid(self:GetNWEntity(self.victimVariable)) and not self.Timer and self:GetNWBool(self.DemonModeActivatedVariable) then
--       self.Timer = true

--       timer.Create("Demon_GainDemonicPower" .. self.LastOwner:Nick(), 0.05, 0, function()
--         if IsValid(self) and IsValid(self.LastOwner) and self:GetNWBool(self.trappedVariable) and IsValid(self:GetNWEntity(self.victimVariable)) and self:GetNWEntity(self.victimVariable):Alive() then
--           --print("timer", self.IsMoving, self.DemonicPower)
--           if SERVER and not self.IsMoving then
--             self.DemonicPower = math.min(self.DemonicPower + (demonicPowerRegen:GetInt() * 0.05), 400)
--             self:SetNWFloat(self.DemonicPowerVariable, self.DemonicPower)
--           end

--           if SERVER and self.IsMoving then
--             self.DemonicPower = math.min(self.DemonicPower - (moveCost:GetInt() * 0.05), 400)
--             self:SetNWFloat(self.DemonicPowerVariable, self.DemonicPower)
--           end
--         end
--       end)
--     end
--   end)

--   local newWeapon = self:GetOwner():GetWeapons()[2]
--   if SERVER and IsValid(newWeapon) then self:GetOwner():SelectWeapon(newWeapon:GetClass()) end
--   if SERVER then self:GetOwner():DropWeapon(self) end
-- end

-- function SWEP:Think()
--   self:SetNoDraw(true)

--   if IsValid(self:GetOwner()) and not self.deployed then
--     self.LastOwner = self:GetOwner()
--     self.DemonicPowerVariable = "DemonicPower" .. self:GetOwner():Nick()
--     self.trappedVariable = "trapped" .. self:GetOwner():Nick()
--     self.DemonModeActivatedVariable = "DemonModeActivated" .. self:GetOwner():Nick()
--     self.victimVariable = "victim" .. self:GetOwner():Nick()

--     self:SetNWBool(self.DemonModeActivatedVariable, false)
--     self:SetNWBool(self.trappedVariable, false)

--     self.deployed = true
--   end
-- end

-- function SWEP:Deploy()
--   if not self.deployed then
--     self.deployed = true
--     self.LastOwner = self:GetOwner()
--     self.DemonicPowerVariable = "DemonicPower" .. self:GetOwner():Nick()
--     self.trappedVariable = "trapped" .. self:GetOwner():Nick()
--     self.DemonModeActivatedVariable = "DemonModeActivated" .. self:GetOwner():Nick()
--     self.victimVariable = "victim" .. self:GetOwner():Nick()
--     self:SetNWBool(self.DemonModeActivatedVariable, false)
--     self:SetNWBool(self.trappedVariable, false)
--   end
-- end

-- function SWEP:OnDrop()
--   self:SetNoDraw(true)

--   if IsValid(self.PossessedVictim) then
--     self.PossessedVictim.PossessedBy = nil
--     self.PossessedVictim.ForcedAttack = nil
--   end
-- end

-- if SERVER then
--   hook.Add("EntityTakeDamage", "gmcore.DemonicPossession.AttributeDamage", function(target, dmginfo)
--     if dmginfo:GetDamage() <= 0 then return end

--     local attacker = dmginfo:GetAttacker()

--     if not IsValid(attacker) or not attacker:IsPlayer() then return end
--     if not IsValid(target) or not target:IsPlayer() then return end

--     if IsValid(attacker.PossessedBy) and attacker.ForcedAttack then
--       dmginfo:SetAttacker(attacker.PossessedBy)
--       attacker.ForcedAttack = false
--     end
--   end)

--   hook.Add("TTTEndRound", "gmcore.DemonicPossession.CleanupRound", function()
--     for _, ply in player.Iterator() do
--       ply.PossessedBy = nil
--       ply.ForcedAttack = nil
--     end
--   end)
-- end
