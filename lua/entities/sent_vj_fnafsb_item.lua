/*--------------------------------------------------
	*** Copyright (c) 2012-2021 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
--------------------------------------------------*/
AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName 		= "Gamemode Item"
ENT.Author 			= "Cpt. Hazama"
ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
ENT.Purpose 		= "Gives a lot of health when taken."
ENT.Instructions 	= "Don't change anything."
ENT.Category		= "Five Nights at Freddy's"

ENT.Spawnable = false
ENT.AdminOnly = false

ENT.VJ_FNaFSB_Item = true
---------------------------------------------------------------------------------------------------------------------------------------------
if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if !SERVER then return end

function ENT:Initialize()
	self:SetModel("models/items/tf_gift.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetPos(self:GetPos() +Vector(0,0,4))

	local StartLight1 = ents.Create("light_dynamic")
	StartLight1:SetKeyValue("brightness", "1")
	StartLight1:SetKeyValue("distance", "75")
	-- StartLight1:SetKeyValue("style", 5)
	StartLight1:SetLocalPos(self:GetPos() +self:OBBCenter())
	StartLight1:SetLocalAngles(self:GetAngles())
	StartLight1:Fire("Color", "255 255 255")
	StartLight1:SetParent(self)
	StartLight1:Spawn()
	StartLight1:Activate()
	StartLight1:SetParent(self)
	StartLight1:Fire("TurnOn", "", 0)
	self:DeleteOnRemove(StartLight1)
	
	local phys = self:GetPhysicsObject()
	if phys and IsValid(phys) then
		phys:Wake()
	end

	self.Loop = CreateSound(self,"cpthazama/fnaf_sb/music_box.wav") -- music/mannrobics.wav
	self.Loop:SetSoundLevel(65)
	self.Loop:Play()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Think()
	self.Loop:Play()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:PhysicsCollide(data, physobj)
	self:EmitSound("physics/cardboard/cardboard_box_impact_soft"..math.random(1,5)..".wav")
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Use(activator, caller)
	self:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1,7) .. ".wav", 65, 80)
	for _,v in pairs(ents.FindByClass("sent_vj_fnafsb_gamemode")) do
		if IsValid(v) then
			v:SetNW2Int("Remaining",v:GetNW2Int("Remaining") -1)
			PrintMessage(HUD_PRINTCENTER,(activator:IsPlayer() && activator:Nick() or "A Bot") .. " has picked up a Gift! " .. v:GetNW2Int("Remaining") .. "/" .. v:GetNW2Int("ItemCount") .. " Gifts remaining.")
			-- PrintMessage(HUD_PRINTCENTER,"A Gift has been picked up! " .. v:GetNW2Int("Remaining") .. "/" .. v:GetNW2Int("ItemCount") .. " Gifts remaining.")
			break
		end
	end
	for _,v in RandomPairs(ents.FindInSphere(self:GetPos(),1000)) do
		if v:IsNPC() && !v.VJ_FNaF_StaffBot && !v.VJ_FNAFSB_Bot && !IsValid(v:GetEnemy()) && v.VJ_TASK_GOTO_LASTPOS then
			v:SetLastPosition(self:GetPos())
			v:VJ_TASK_GOTO_LASTPOS("TASK_WALK_PATH")
			break
		end
	end
	self:EmitSound("cpthazama/fnaf_sb/sfx_io_prize_box_popopen.wav",70)
	if activator:IsPlayer() then
		net.Start("vj_fnafsb_gm_sound")
			net.WriteEntity(activator)
			net.WriteString("^cpthazama/fnafsb/vanessa/fx_vanny/Vanny_MusicBox_0" .. math.random(1,8) .. ".wav")
		net.Send(activator)
		local r = math.random(1,5)
		local gm = GetFNaFGamemode()
		if gm != false then
			if r == 1 then
				gm:GiveWeapon(activator,VJ_PICK({"weapon_vj_fnafsb_blaster","weapon_vj_fnafsb_fazcam","weapon_vj_fnafsb_fazwatch"}))
			else
				activator:SetArmor(math.Clamp(activator:Armor() +25,0,100))
				-- local e = ents.Create("item_battery")
				-- e:SetPos(activator:GetPos() +activator:OBBCenter())
				-- e:Spawn()
			end
		end
	end

	self:Remove()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnTakeDamage(dmginfo)
	self:GetPhysicsObject():AddVelocity(dmginfo:GetDamageForce() * 0.1)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnRemove()
	self.Loop:Stop()
end