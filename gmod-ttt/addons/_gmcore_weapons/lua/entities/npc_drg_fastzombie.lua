--This isn't actually completed to the level that I wanted, however, I got sick of letting it collect dust so I'm pushing what's working out for public use

if !DrGBase then return end
AddCSLuaFile()

sound.Add( {
		name = "DRG.FZ.Hit",
		channel = CHAN_BODY,
		volume = 1.0,
		level = 60,
		sound = { "npc/fast_zombie/claw_strike1.wav", "npc/fast_zombie/claw_strike2.wav", "npc/fast_zombie/claw_strike3.wav" }
} )
sound.Add( {
		name = "DRG.FZ.Miss",
		channel = CHAN_BODY,
		volume = 1.0,
		level = 60,
		sound = { "npc/fast_zombie/claw_miss1.wav", "npc/fast_zombie/claw_miss2.wav" }
} )
sound.Add( {
		name = "DRG.FZ.Walk",
		channel = CHAN_BODY,
		volume = 1.0,
		level = 60,
		sound = { "npc/fast_zombie/foot1.wav", "npc/fast_zombie/foot2.wav", "npc/fast_zombie/foot3.wav", "npc/fast_zombie/foot4.wav" }
} )
sound.Add( {
		name = "DRG.FZ.Alert",
		channel = CHAN_BODY,
		volume = 1.0,
		level = 90,
		sound = { "npc/fast_zombie/fz_alert_close1.wav" }
} )

ENT.Base = "drgbase_nextbot"
ENT.PrintName = "Fast Zombie"
ENT.Category = "DrGBase"
ENT.Models = {"models/zombie/fast.mdl"}
ENT.BloodColor = BLOOD_COLOR_GREEN

ENT.OnDamageSounds = {"npc/fast_zombie/idle1.wav", "npc/fast_zombie/idle2.wav", "npc/fast_zombie/idle3.wav"} --The fast zombie has no damage or death sound
ENT.OnDeathSounds = {"npc/fast_zombie/wake1.wav"}

ENT.SpawnHealth = 100

ENT.RangeAttackRange = 60
ENT.MeleeAttackRange = 30
ENT.ReachEnemyRange = 30
ENT.AvoidEnemyRange = 0

ENT.Factions = {FACTION_ZOMBIES}

ENT.UseWalkframes = true

--ENT.EyeBone = "ValveBiped.Bip01_Spine4"
--ENT.EyeOffset = Vector(7.5, 0, 5)

ENT.PossessionEnabled = false

if SERVER then
		function ENT:CustomInitialize()
				self:SetDefaultRelationship(D_HT)
				self:SetBodygroup(1, 1)
		end

		-- AI --
		function ENT:OnMeleeAttack(enemy)
				--self:EmitSound("Zombie.Attack")
				self:PlayActivityAndMove(ACT_MELEE_ATTACK1, 1, self.FaceEnemy)
		end

		function ENT:OnRangedAttack(enemy)
				
		end

		function ENT:OnReachedPatrol()
				self:Wait(math.random(3, 7))
		end
		function ENT:OnIdle()
				self:AddPatrolPos(self:RandomPos(1500))
		end

		-- Damage --
		function ENT:OnDeath(dmg, delay, hitgroup)
				if hitgroup ~= HITGROUP_HEAD then
				self:SetBodygroup(1, 0)
				local headcrab = ents.Create("npc_headcrab_fast")
				if not IsValid(headcrab) then return end
				headcrab:SetPos(self:EyePos())
				headcrab:SetAngles(self:GetAngles())
				headcrab:Spawn()
				end
		end

		-- Animations/Sounds --
		function ENT:OnNewEnemy()
				self:EmitSound("DRG.FZ.Alert")
		end

		function ENT:OnAnimEvent()
				if self:IsAttacking() and self:GetCycle() > 0.3 then
						self:Attack( {
								damage = 10,
								type = DMG_SLASH,
								viewpunch = Angle(20, math.random(-10, 10), 0)
								}, 
								function(self, hit)
										if #hit > 0 then
												self:EmitSound("DRG.FZ.Hit")
										else 
												self:EmitSound("DRG.FZ.Miss") 
										end
								end
						)
				else 
						self:EmitSound("DRG.FZ.Walk")
				end
		end
end

DrGBase.AddNextbot(ENT)