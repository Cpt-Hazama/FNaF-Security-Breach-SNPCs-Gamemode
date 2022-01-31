AddCSLuaFile("shared.lua")
include('shared.lua')
/*-----------------------------------------------
	*** Copyright (c) 2012-2021 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/
ENT.Model = {"models/player/kleiner.mdl"}
local testList = player_manager.AllValidModels()
for _,v in pairs(testList) do
	table.insert(ENT.Model,v)
end
ENT.StartHealth = 100
ENT.HullType = HULL_HUMAN
ENT.Behavior = VJ_BEHAVIOR_PASSIVE
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY"} -- NPCs with the same class with be allied to each other
ENT.FriendsWithAllPlayerAllies = true
ENT.EntitiesToNoCollide = {"npc_vj_fnafsb_bot"}
-- ENT.IdleAlwaysWander = true
ENT.FollowPlayer = false
-- ENT.NoWeapon_UseScaredBehavior = false

ENT.InvestigateSoundDistance = 0
ENT.BloodColor = "Red"
ENT.BecomeEnemyToPlayer = false
ENT.HasMeleeAttack = false
ENT.CombatFaceEnemy = false
ENT.DisableWeapons = true
ENT.CallForHelp = false
ENT.Weapon_NoSpawnMenu = true -- If set to true, the NPC weapon setting in the spawnmenu will not be applied for this SNPC
ENT.HasGrenadeAttack = false -- Should the SNPC have a grenade attack?

ENT.DisableFindEnemy = true
ENT.AlertFriendsOnDeath = false
ENT.DisableCallForBackUpOnDamageAnimation = true
ENT.CallForBackUpOnDamage = false

-- ENT.AnimTbl_IdleStand = {ACT_HL2MP_IDLE}
-- ENT.AnimTbl_Walk = {ACT_HL2MP_WALK}
-- ENT.AnimTbl_Run = {ACT_HL2MP_RUN}
-- ENT.AnimTbl_TakingCover = {ACT_HL2MP_IDLE_CROUCH}
-- ENT.AnimTbl_MoveToCover = {ACT_HL2MP_WALK_CROUCH}
-- ENT.AnimTbl_ScaredBehaviorStand = {ACT_HL2MP_IDLE_CROUCH}
ENT.AnimTbl_AlertFriendsOnDeath = {nil}

ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5

ENT.CurrentItem = NULL
ENT.CurrentCheckPos = Vector(0,0,0)
ENT.NextCheckPosT = 0
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:GetSightDirection()
	local att = self:LookupAttachment("eyes")
	if self:GetModel() == "models/error.mdl" then self:Remove() return end
	return att && self:GetAttachment(att).Ang:Forward() or self:GetForward()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnReleasedFromJumpscare(ent)
	self:SetEnemy(ent)
	self:VJ_TASK_COVER_FROM_ENEMY("TASK_RUN_PATH")
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize()
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_JUMP))
	if self:GetModel() == "models/error.mdl" then
		self:Remove()
		-- self:SetModel("models/player/kleiner.mdl")
		return
	end
	-- self.AnimTbl_IdleStand = {ACT_HL2MP_IDLE}
	-- self.AnimTbl_ScaredBehaviorStand = {ACT_HL2MP_IDLE_CROUCH}

	self.DisableWeapons = true
	self:Give("weapon_vj_fnafsb_fazlight")
	self:CapabilitiesRemove(CAP_USE_WEAPONS)
	self:CapabilitiesRemove(CAP_WEAPON_RANGE_ATTACK1)
	self:CapabilitiesRemove(CAP_MOVE_SHOOT)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:IsAbleToShootWeapon(checkDistance, checkDistanceOnly, enemyDist)
	return false
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DoChangeWeapon(wep, invSwitch)
	wep = wep or nil -- The weapon to give or setup | Setting it nil will only setup the current active weapon
	invSwitch = invSwitch or false -- If true, it will not delete the previous weapon!
	local curWep = self:GetActiveWeapon()
	
	-- if self.DisableWeapons == true && IsValid(curWep) then -- Not suppose to have a weapon!
	-- 	curWep:Remove()
	-- 	return NULL
	-- end
	
	if wep != nil then -- Only remove and actually give the weapon if the function is given a weapon class to set
		if invSwitch == true then
			self:SelectWeapon(wep)
			VJ_EmitSound(self, {"physics/metal/weapon_impact_soft1.wav","physics/metal/weapon_impact_soft2.wav","physics/metal/weapon_impact_soft3.wav"}, 70)
			curWep = wep
		else
			if IsValid(curWep) && self:GetWeaponState() != VJ_WEP_STATE_ANTI_ARMOR && self:GetWeaponState() != VJ_WEP_STATE_MELEE then
				curWep:Remove()
			end
			curWep = self:Give(wep)
			self.WeaponInventory.Primary = curWep
		end
	end
	
	if IsValid(curWep) then -- If we are given a new weapon or switching weapon, then do all of the necessary set up
		self.CurrentWeaponAnimation = -1
		if invSwitch == true && curWep.IsVJBaseWeapon == true then curWep:Equip(self) end
		self:SetupWeaponHoldTypeAnims(curWep:GetHoldType())
		self:CustomOnDoChangeWeapon(curWep, self.CurrentWeaponEntity, invSwitch)
		self.CurrentWeaponEntity = curWep
	end
	return curWep
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DecideXY()
	local moveData = self:GetMoveDirection(true)
	self:SetPoseParameter("move_x",moveData.x)
	self:SetPoseParameter("move_y",moveData.y)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:GetMoveDirection(ignoreZ)
	if not self:IsMoving() then return Vector(0,0,0) end
	local waypoint = self:GetCurWaypointPos() or self:GetPos()
	local dir = (waypoint -self:GetPos())
	if ignoreZ then dir.z = 0 end
	return (self:GetAngles() -dir:Angle()):Forward()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnThink_AIEnabled()
	self:DecideXY()
	if self:IsMoving() && self:GetPos():Distance(self:GetCurWaypointPos()) > 75 then
		self:FaceCertainPosition(self:GetCurWaypointPos())
	end
	self.NextWeaponAttackT = CurTime() +500

	if !IsFNaFGamemode() then
		if IsValid(self:GetEnemy()) && !self:IsMoving() then
			self:VJ_TASK_COVER_FROM_ENEMY("TASK_RUN_PATH")
		end
		return
	end

	-- if !IsValid(self:GetEnemy()) then
		if !IsValid(self.CurrentItem) then
			if CurTime() > self.NextCheckPosT then
				local checkPos = VJ_FNaF_FindHiddenNavArea(false,false)
				if checkPos == false then return end
				if checkPos == nil then return end
				self.CurrentCheckPos = checkPos
				self:SetLastPosition(self.CurrentCheckPos)
				self:VJ_TASK_GOTO_LASTPOS(math.random(1,4) == 1 && "TASK_WALK_PATH" or "TASK_RUN_PATH")
				local pathTime = self:GetPathTimeToGoal()
				-- if pathTime <= 0.25 then
				-- 	self.CurrentCheckPos = nil
				-- 	self.NextCheckPosT = 0
				-- end
				self.NextCheckPosT = CurTime() +pathTime +math.Rand(2,4)
			end
			for _,v in pairs(ents.FindInSphere(self:GetPos(),700)) do
				if v.VJ_FNaFSB_Item && self:Visible(v) then
					self.CurrentItem = v
					break
				end
			end
		else
			self:SetLastPosition(self.CurrentItem:GetPos())
			self:VJ_TASK_GOTO_LASTPOS("TASK_RUN_PATH")
			if self.CurrentItem:GetPos():Distance(self:GetPos()) <= 100 then
				self.CurrentItem:Use(self)
			end
		end
	-- else
		-- self.NextCheckPosT = CurTime() +1
	-- end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Between(a,b)
	local waypoint = self:GetCurWaypointPos()
	local ang = (waypoint -self:GetPos()):Angle()
	local dif = math.AngleDifference(self:GetAngles().y,ang.y)
	return dif < a && dif > b
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:FootStepSoundCode(CustomTbl)
	if self.HasSounds == false or self.HasFootStepSound == false or self.MovementType == VJ_MOVETYPE_STATIONARY then return end
	if self:IsOnGround() && self:GetGroundEntity() != NULL then
		if self:IsMoving() && CurTime() > self.FootStepT && self:GetInternalVariable("m_flMoveWaitFinished") <= 0 then
			self:CustomOnFootStepSound()
			local CurSched = self.CurrentSchedule
			if self.DisableFootStepOnRun == false && ((VJ_HasValue(self.AnimTbl_Run,self:GetMovementActivity())) or (CurSched != nil  && CurSched.MoveType == 1)) /*(VJ_HasValue(VJ_RunActivites,self:GetMovementActivity()) or VJ_HasValue(self.CustomRunActivites,self:GetMovementActivity()))*/ then
				self:FootStep()
				self.FootStepT = CurTime() + self.FootStepTimeRun
				return
			elseif self.DisableFootStepOnWalk == false && (VJ_HasValue(self.AnimTbl_Walk,self:GetMovementActivity()) or (CurSched != nil  && CurSched.MoveType == 0)) /*(VJ_HasValue(VJ_WalkActivites,self:GetMovementActivity()) or VJ_HasValue(self.CustomWalkActivites,self:GetMovementActivity()))*/ then
				self:FootStep()
				self.FootStepT = CurTime() + self.FootStepTimeWalk
				return
			end
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
ENT.FootSteps = {
	[MAT_ANTLION] = {
		"physics/flesh/flesh_impact_hard1.wav",
		"physics/flesh/flesh_impact_hard2.wav",
		"physics/flesh/flesh_impact_hard3.wav",
		"physics/flesh/flesh_impact_hard4.wav",
		"physics/flesh/flesh_impact_hard5.wav",
		"physics/flesh/flesh_impact_hard6.wav",
	},
	[MAT_BLOODYFLESH] = {
		"physics/flesh/flesh_impact_hard1.wav",
		"physics/flesh/flesh_impact_hard2.wav",
		"physics/flesh/flesh_impact_hard3.wav",
		"physics/flesh/flesh_impact_hard4.wav",
		"physics/flesh/flesh_impact_hard5.wav",
		"physics/flesh/flesh_impact_hard6.wav",
	},
	[MAT_CONCRETE] = {
		"player/footsteps/concrete1.wav",
		"player/footsteps/concrete2.wav",
		"player/footsteps/concrete3.wav",
		"player/footsteps/concrete4.wav",
	},
	[MAT_DIRT] = {
		"player/footsteps/dirt1.wav",
		"player/footsteps/dirt2.wav",
		"player/footsteps/dirt3.wav",
		"player/footsteps/dirt4.wav",
	},
	[MAT_FLESH] = {
		"physics/flesh/flesh_impact_hard1.wav",
		"physics/flesh/flesh_impact_hard2.wav",
		"physics/flesh/flesh_impact_hard3.wav",
		"physics/flesh/flesh_impact_hard4.wav",
		"physics/flesh/flesh_impact_hard5.wav",
		"physics/flesh/flesh_impact_hard6.wav",
	},
	[MAT_GRATE] = {
		"player/footsteps/metalgrate1.wav",
		"player/footsteps/metalgrate2.wav",
		"player/footsteps/metalgrate3.wav",
		"player/footsteps/metalgrate4.wav",
	},
	[MAT_ALIENFLESH] = {
		"physics/flesh/flesh_impact_hard1.wav",
		"physics/flesh/flesh_impact_hard2.wav",
		"physics/flesh/flesh_impact_hard3.wav",
		"physics/flesh/flesh_impact_hard4.wav",
		"physics/flesh/flesh_impact_hard5.wav",
		"physics/flesh/flesh_impact_hard6.wav",
	},
	[74] = { -- Snow
		"player/footsteps/sand1.wav",
		"player/footsteps/sand2.wav",
		"player/footsteps/sand3.wav",
		"player/footsteps/sand4.wav",
	},
	[MAT_PLASTIC] = {
		"physics/plaster/drywall_footstep1.wav",
		"physics/plaster/drywall_footstep2.wav",
		"physics/plaster/drywall_footstep3.wav",
		"physics/plaster/drywall_footstep4.wav",
	},
	[MAT_METAL] = {
		"player/footsteps/metal1.wav",
		"player/footsteps/metal2.wav",
		"player/footsteps/metal3.wav",
		"player/footsteps/metal4.wav",
	},
	[MAT_SAND] = {
		"player/footsteps/sand1.wav",
		"player/footsteps/sand2.wav",
		"player/footsteps/sand3.wav",
		"player/footsteps/sand4.wav",
	},
	[MAT_FOLIAGE] = {
		"player/footsteps/grass1.wav",
		"player/footsteps/grass2.wav",
		"player/footsteps/grass3.wav",
		"player/footsteps/grass4.wav",
	},
	[MAT_COMPUTER] = {
		"physics/plaster/drywall_footstep1.wav",
		"physics/plaster/drywall_footstep2.wav",
		"physics/plaster/drywall_footstep3.wav",
		"physics/plaster/drywall_footstep4.wav",
	},
	[MAT_SLOSH] = {
		"player/footsteps/slosh1.wav",
		"player/footsteps/slosh2.wav",
		"player/footsteps/slosh3.wav",
		"player/footsteps/slosh4.wav",
	},
	[MAT_TILE] = {
		"player/footsteps/tile1.wav",
		"player/footsteps/tile2.wav",
		"player/footsteps/tile3.wav",
		"player/footsteps/tile4.wav",
	},
	[85] = { -- Grass
		"player/footsteps/grass1.wav",
		"player/footsteps/grass2.wav",
		"player/footsteps/grass3.wav",
		"player/footsteps/grass4.wav",
	},
	[MAT_VENT] = {
		"player/footsteps/duct1.wav",
		"player/footsteps/duct2.wav",
		"player/footsteps/duct3.wav",
		"player/footsteps/duct4.wav",
	},
	[MAT_WOOD] = {
		"player/footsteps/wood1.wav",
		"player/footsteps/wood2.wav",
		"player/footsteps/wood3.wav",
		"player/footsteps/wood4.wav",
		"player/footsteps/woodpanel1.wav",
		"player/footsteps/woodpanel2.wav",
		"player/footsteps/woodpanel3.wav",
		"player/footsteps/woodpanel4.wav",
	},
	[MAT_GLASS] = {
		"physics/glass/glass_sheet_step1.wav",
		"physics/glass/glass_sheet_step2.wav",
		"physics/glass/glass_sheet_step3.wav",
		"physics/glass/glass_sheet_step4.wav",
	}
}
--
function ENT:FootStep()
	if self.HasSounds == false or self.HasFootStepSound == false or self.MovementType == VJ_MOVETYPE_STATIONARY then return end
	if !self:IsOnGround() then return end
	if !self:IsMoving() then return end
	local tr = util.TraceLine({
		start = self:GetPos(),
		endpos = self:GetPos() +Vector(0,0,-150),
		filter = {self}
	})
	if tr.Hit && self.FootSteps[tr.MatType] then
		VJ_EmitSound(self,VJ_PICK(self.FootSteps[tr.MatType]),self.FootStepSoundLevel,self:VJ_DecideSoundPitch(self.FootStepPitch1,self.FootStepPitch2))
	end
	if self:WaterLevel() > 0 && self:WaterLevel() < 3 then
		VJ_EmitSound(self,"player/footsteps/wade" .. math.random(1,8) .. ".wav",self.FootStepSoundLevel,self:VJ_DecideSoundPitch(self.FootStepPitch1,self.FootStepPitch2))
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:SetAnimData(idle,crouch,crouch_move,walk,run,fire,reload,jump)
	if type(idle) == "string" then idle = VJ_SequenceToActivity(self,idle) end
	if type(crouch) == "string" then crouch = VJ_SequenceToActivity(self,crouch) end
	if type(crouch_move) == "string" then crouch_move = VJ_SequenceToActivity(self,crouch_move) end
	if type(walk) == "string" then walk = VJ_SequenceToActivity(self,walk) end
	if type(run) == "string" then run = VJ_SequenceToActivity(self,run) end
	if type(fire) == "string" then fire = VJ_SequenceToActivity(self,fire) end
	if type(reload) == "string" then reload = VJ_SequenceToActivity(self,reload) end
	if type(jump) == "string" then jump = VJ_SequenceToActivity(self,jump) end

	self.WeaponAnimTranslations[ACT_IDLE] 							= idle
	self.WeaponAnimTranslations[ACT_WALK] 							= walk
	self.WeaponAnimTranslations[ACT_RUN] 							= run
	self.WeaponAnimTranslations[ACT_IDLE_ANGRY] 					= idle
	self.WeaponAnimTranslations[ACT_WALK_AIM] 						= walk
	self.WeaponAnimTranslations[ACT_WALK_CROUCH] 					= crouch_move
	self.WeaponAnimTranslations[ACT_WALK_CROUCH_AIM] 				= crouch_move
	self.WeaponAnimTranslations[ACT_RUN_AIM] 						= run
	self.WeaponAnimTranslations[ACT_RUN_CROUCH] 					= crouch_move
	self.WeaponAnimTranslations[ACT_RUN_CROUCH_AIM] 				= crouch_move
	self.WeaponAnimTranslations[ACT_RANGE_ATTACK1] 					= idle
	self.WeaponAnimTranslations[ACT_GESTURE_RANGE_ATTACK1] 			= fire
	self.WeaponAnimTranslations[ACT_RANGE_ATTACK1_LOW] 				= crouch
	self.WeaponAnimTranslations[ACT_RELOAD]							= "vjges_" .. VJ_GetSequenceName(self,reload)
	self.WeaponAnimTranslations[ACT_COVER_LOW] 						= crouch
	self.WeaponAnimTranslations[ACT_RELOAD_LOW] 					= "vjges_" .. VJ_GetSequenceName(self,reload)
	self.WeaponAnimTranslations[ACT_JUMP] 							= jump
	self.WeaponAnimTranslations[ACT_LAND] 							= -1
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnSetupWeaponHoldTypeAnims(htype)
	self.CurrentHoldType = htype
	local idle = ACT_HL2MP_IDLE
	local walk = ACT_HL2MP_WALK
	local crouch_move = ACT_HL2MP_WALK_CROUCH
	local run = ACT_HL2MP_RUN
	local fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST
	local crouch = ACT_HL2MP_IDLE_CROUCH
	local reload = ACT_HL2MP_GESTURE_RELOAD_PISTOL
	if htype == "ar2" && self:GetActiveWeapon().CS_HType != "mach" then
		idle = ACT_HL2MP_IDLE_AR2
		walk = ACT_HL2MP_WALK_AR2
		crouch_move = ACT_HL2MP_WALK_CROUCH_AR2
		run = ACT_HL2MP_RUN_AR2
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2
		crouch = ACT_HL2MP_IDLE_CROUCH_AR2
		reload = ACT_HL2MP_GESTURE_RELOAD_AR2
		jump = ACT_HL2MP_JUMP_AR2
	elseif htype == "smg" && self:GetActiveWeapon().CS_HType != "mac" then
		idle = ACT_HL2MP_IDLE_SMG1
		walk = ACT_HL2MP_WALK_SMG1
		crouch_move = ACT_HL2MP_WALK_CROUCH_SMG1
		run = ACT_HL2MP_RUN_SMG1
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1
		crouch = ACT_HL2MP_IDLE_CROUCH_SMG1
		reload = ACT_HL2MP_GESTURE_RELOAD_SMG1
		jump = ACT_HL2MP_JUMP_SMG1
	elseif htype == "shotgun" then
		idle = ACT_HL2MP_IDLE_SHOTGUN
		walk = ACT_HL2MP_WALK_SHOTGUN
		crouch_move = ACT_HL2MP_WALK_CROUCH_SHOTGUN
		run = ACT_HL2MP_RUN_SHOTGUN
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN
		crouch = ACT_HL2MP_IDLE_CROUCH_SHOTGUN
		reload = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN
		jump = ACT_HL2MP_JUMP_SHOTGUN
	elseif htype == "rpg" then
		idle = ACT_HL2MP_IDLE_RPG
		walk = ACT_HL2MP_WALK_RPG
		crouch_move = ACT_HL2MP_WALK_CROUCH_RPG
		run = ACT_HL2MP_RUN_RPG
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG
		crouch = ACT_HL2MP_IDLE_CROUCH_RPG
		reload = ACT_HL2MP_GESTURE_RELOAD_RPG
		jump = ACT_HL2MP_JUMP_RPG
	elseif htype == "pistol" then
		idle = ACT_HL2MP_IDLE_REVOLVER
		walk = ACT_HL2MP_WALK_REVOLVER
		crouch_move = ACT_HL2MP_WALK_CROUCH_PISTOL
		run = ACT_HL2MP_RUN_REVOLVER
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL
		crouch = ACT_HL2MP_IDLE_CROUCH_PISTOL
		reload = ACT_HL2MP_GESTURE_RELOAD_PISTOL
		jump = ACT_HL2MP_JUMP_REVOLVER
	elseif htype == "dual" then
		idle = "idle_dual"
		walk = "walk_dual"
		crouch_move = "cwalk_dual"
		run = "run_dual"
		fire = "range_dual_r"
		crouch = "cidle_dual"
		reload = "reload_dual"
		jump = "jump_dual"
	elseif htype == "revolver" then
		idle = ACT_HL2MP_IDLE_REVOLVER
		walk = ACT_HL2MP_WALK_REVOLVER
		crouch_move = ACT_HL2MP_WALK_CROUCH_REVOLVER
		run = ACT_HL2MP_RUN_REVOLVER
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER
		crouch = ACT_HL2MP_IDLE_CROUCH_REVOLVER
		reload = ACT_HL2MP_GESTURE_RELOAD_REVOLVER
		jump = ACT_HL2MP_JUMP_REVOLVER
	elseif htype == "crossbow" then
		idle = ACT_HL2MP_IDLE_CROSSBOW
		walk = ACT_HL2MP_WALK_CROSSBOW
		crouch_move = ACT_HL2MP_WALK_CROUCH_CROSSBOW
		run = ACT_HL2MP_RUN_CROSSBOW
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW
		crouch = ACT_HL2MP_IDLE_CROUCH_CROSSBOW
		reload = ACT_HL2MP_GESTURE_RELOAD_CROSSBOW
		jump = ACT_HL2MP_JUMP_CROSSBOW
	elseif htype == "knife" then
		idle = ACT_HL2MP_IDLE_KNIFE
		walk = ACT_HL2MP_WALK_KNIFE
		crouch_move = ACT_HL2MP_WALK_CROUCH_KNIFE
		run = ACT_HL2MP_RUN_KNIFE
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		crouch = ACT_HL2MP_IDLE_CROUCH_KNIFE
		reload = ACT_HL2MP_GESTURE_RELOAD_KNIFE
		jump = ACT_HL2MP_JUMP_KNIFE
	elseif htype == "grenade" then
		idle = ACT_HL2MP_IDLE_GRENADE
		walk = ACT_HL2MP_WALK_GRENADE
		crouch_move = ACT_HL2MP_WALK_CROUCH_GRENADE
		run = ACT_HL2MP_RUN_GRENADE
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE
		crouch = ACT_HL2MP_IDLE_CROUCH_GRENADE
		reload = ACT_HL2MP_GESTURE_RELOAD_GRENADE
		jump = ACT_HL2MP_JUMP_GRENADE
	elseif htype == "melee" then
		idle = ACT_HL2MP_IDLE_MELEE
		walk = ACT_HL2MP_WALK_MELEE
		crouch_move = ACT_HL2MP_WALK_CROUCH_MELEE
		run = ACT_HL2MP_RUN_MELEE
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
		crouch = ACT_HL2MP_IDLE_CROUCH_MELEE
		reload = ACT_HL2MP_GESTURE_RELOAD_MELEE
		jump = ACT_HL2MP_JUMP_MELEE
	elseif htype == "melee_angry" then
		idle = "idle_melee_angry"
		walk = ACT_HL2MP_WALK_MELEE
		crouch_move = ACT_HL2MP_WALK_CROUCH_MELEE
		run = ACT_HL2MP_RUN_MELEE
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
		crouch = ACT_HL2MP_IDLE_CROUCH_MELEE
		reload = ACT_HL2MP_GESTURE_RELOAD_MELEE
		jump = ACT_HL2MP_JUMP_MELEE
	elseif htype == "melee2" then
		idle = ACT_HL2MP_IDLE_MELEE2
		walk = ACT_HL2MP_WALK_MELEE2
		crouch_move = ACT_HL2MP_WALK_CROUCH_MELEE2
		run = ACT_HL2MP_RUN_MELEE2
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2
		crouch = ACT_HL2MP_IDLE_CROUCH_MELEE2
		reload = ACT_HL2MP_GESTURE_RELOAD_MELEE2
		jump = ACT_HL2MP_JUMP_MELEE2
	elseif htype == "physgun" then
		idle = ACT_HL2MP_IDLE_PHYSGUN
		walk = ACT_HL2MP_WALK_PHYSGUN
		crouch_move = ACT_HL2MP_WALK_CROUCH_PHYSGUN
		run = ACT_HL2MP_RUN_PHYSGUN
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN
		crouch = ACT_HL2MP_IDLE_CROUCH_PHYSGUN
		reload = ACT_HL2MP_GESTURE_RELOAD_PHYSGUN
		jump = ACT_HL2MP_JUMP_PHYSGUN
	elseif htype == "ar2" && self:GetActiveWeapon().CS_HType == "mach" then
		idle = ACT_HL2MP_IDLE_SHOTGUN
		walk = ACT_HL2MP_WALK_SHOTGUN
		crouch_move = ACT_HL2MP_WALK_CROUCH_SHOTGUN
		run = ACT_HL2MP_RUN_SHOTGUN
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2
		crouch = ACT_HL2MP_IDLE_CROUCH_SHOTGUN
		reload = ACT_HL2MP_GESTURE_RELOAD_SMG1
		jump = ACT_HL2MP_JUMP_SHOTGUN
	elseif htype == "smg" && self:GetActiveWeapon().CS_HType == "mac" then
		idle = ACT_HL2MP_IDLE_REVOLVER
		walk = ACT_HL2MP_WALK_REVOLVER
		crouch_move = ACT_HL2MP_WALK_CROUCH_REVOLVER
		run = ACT_HL2MP_RUN_REVOLVER
		fire = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL
		crouch = ACT_HL2MP_IDLE_CROUCH_REVOLVER
		reload = ACT_HL2MP_GESTURE_RELOAD_REVOLVER
		jump = ACT_HL2MP_JUMP_REVOLVER
	end
	self:SetAnimData(idle,crouch,crouch_move,walk,run,fire,reload,jump)
	return true
end