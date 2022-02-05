AddCSLuaFile("shared.lua")
include('shared.lua')

util.AddNetworkString("vj_fnafsb_gm_sound")
util.AddNetworkString("vj_fnafsb_gm_dat")

local math_Clamp = math.Clamp

ENT.MaxEnemies = 10
--
local staminaMax = 100
local staminaDrain = 1
local staminaDrainT = 0.1
local staminaRegen = 1
local staminaRegenT = 0.5
local staminaRegenDelay = 5
--
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:GiveWeapon(ent,wep)
	ent.VJ_CanBePickedUpWithOutUse = true
	ent.VJ_CanBePickedUpWithOutUse_Class = wep
	ent:Give(wep)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Loadout(v)
	v:SetNW2Bool("FNaFSB_Death",false)
	-- v:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	v:Spawn()
	-- v:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	-- VJ_SetClearPos(v,v:GetPos())
	v:StripWeapons()
	v.DidLoadout = true
	self:SetPos(v:EyePos())
	timer.Simple(0,function()
		local controlled = false
		if #player.GetAll() > 2 && GetConVar("vj_fnafsb_gm_plyenemy"):GetInt() == 1 then
			if math.random(1,#player.GetAll()) == 1 then
				for _,ent in RandomPairs(self.Enemies) do
					if !ent.VJ_IsBeingControlled then
						ent:SetNW2Bool("FNaFSB_Death",true)
						self:PlayerSetMsg(v,"You are an Enemy. Find and kill all of the Survivors to win!")
						local obj = ents.Create("obj_vj_npccontroller")
						obj.VJCE_Player = v
						obj:SetControlledNPC(ent)
						obj:Spawn()
						obj:StartControlling()
						v:SetEyeAngles(ent:GetAngles())
						obj.VJC_Player_CanExit = false
						obj.VJC_Player_DrawHUD = false
						controlled = true
						-- print("Set " .. v:Nick() .. " as controlled")
						break
					end
				end
			end
		end
		if controlled then
			-- self:SetNW2Int("PlayerCount",self:GetNW2Int("PlayerCount") -1)
			return
		end
		v.VJ_FNaF_WSpeed = v:GetWalkSpeed()
		v.VJ_FNaF_RSpeed = v:GetRunSpeed()
		v.VJ_FNaF_JumpPower = v:GetJumpPower()
		v.VJ_FNaF_ClimbSpeed = v:GetLadderClimbSpeed()
		v:SetHealth(100)
		v:SetArmor(100)
		v:SetWalkSpeed(100)
		v:SetRunSpeed(230)
		v:SetJumpPower(150)
		v:SetLadderClimbSpeed(30)
		v.VJ_FNaF_Stamina = 80
		v.VJ_FNaF_NextStaminaDrainT = CurTime()
		v.VJ_FNaF_NextStaminaRegenT = CurTime()
		v.VJ_FNaF_NextStaminaRegenDelayT = CurTime()
		self:GiveWeapon(v,"weapon_vj_fnafsb_fazlight")
	end)
	self:SetNW2Int("PlayerCount",self:GetNW2Int("PlayerCount") +1)

	self:PlayerSetMsg(v,"You are a Survivor. Find all the Gifts to win!")
	self:PlayerNWSound(v,"cpthazama/fnaf_sb/gamemode/Bell1.wav")
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Initialize()
	self:SetPos(Entity(1):GetPos() +Vector(0,0,15))

	self:SetModel("models/props_junk/popcan01a.mdl")
	self:DrawShadow(false)
	self:SetNoDraw(true)
	self:SetNotSolid(true)
	if InFNaFGamemode() then
		PrintMessage(HUD_PRINTTALK,"Only one gamemode entity can be spawned at a time!")
		self:Remove()
	end
	if !navmesh then
		PrintMessage(HUD_PRINTTALK,"No Nav-Mesh detected! It is required for item/enemy spawning!")
		self:Remove()
		return
	end

	PrintMessage(HUD_PRINTCENTER,"FNaF Gamemode is Initializing, please be patient!")

	game.CleanUpMap(false,{self:GetClass(),"npc_vj_fnafsb_bot","sent_vj_ply_spawnpoint"})

	self:SetNW2Int("ItemCount",0)
	self:SetNW2Int("EnemyCount",0)

	self.EnemyCount = math_Clamp(GetConVar("vj_fnafsb_gm_count"):GetInt(),1,self.MaxEnemies)
	self.ItemCount = GetConVar("vj_fnafsb_gm_itemcount"):GetInt()
	self.BotCount = GetConVar("vj_fnafsb_gm_botcount"):GetInt()
	self.PlayerIndex = 1
	self.End = false
	self.Items = {}
	self.Enemies = {}
	self.EnemiesStoredClasses = {}
	self.EnemyClasses = {}
	for _,v in pairs(FNAF_GM.Characters) do
		-- print("Added " .. v.Name .. " to the enemy list")
		table.insert(self.EnemyClasses,{Spawned = false, Class = v.Class})
	end

	self:SetNW2Int("Remaining",self.ItemCount)

	for i = 1,self.EnemyCount do
		local function PickEnemy()
			local tbl = {}
			for i,v in pairs(self.EnemyClasses) do
				if v.Spawned == false then
					local canSpawn = true
					for _,v2 in pairs(self.EnemiesStoredClasses) do
						if VJ_HasValue(FNAF_GM.GetCharacterData(v2).Filter,v.Class) then
							canSpawn = false
							break
						end
					end
					if !canSpawn then continue end
					table.insert(tbl,v.Class)
				end
			end

			local selected = VJ_PICK(tbl)
			for _,v in pairs(self.EnemyClasses) do
				if v.Class == selected then
					v.Spawned = true
					break
				end
			end
			return selected
		end
		local selected = PickEnemy()
		local enemy = ents.Create(selected)
		if !IsValid(enemy) then
			enemy = ents.Create(PickEnemy())
		end
		local pos = VJ_FNaF_FindHiddenNavArea(true,true)
		if pos == false then
			SafeRemoveEntity(enemy)
			enemy = ents.Create(PickEnemy())
			pos = VJ_FNaF_FindHiddenNavArea(true,true)
			if !IsValid(enemy) then return end
		end
		local storedPos = pos
		enemy:SetPos(pos)
		enemy:SetAngles(Angle(0,math.random(0,360),0))
		enemy:Spawn()
		table.insert(self.Enemies,enemy)
		table.insert(self.EnemiesStoredClasses,enemy:GetClass())
		for i,v in pairs(player.GetAll()) do
			v:SetNW2String("VJ_FNaF_GM_Enemy" .. #self.Enemies,enemy:GetClass())
		end
		print("Spawmned " .. enemy:GetClass())
		enemy.IdleAlwaysWander = true
		enemy.GodMode = true
		enemy.CanKill = true
		enemy.VJ_NPC_Class = {"CLASS_FNAF_ANIMATRONIC"}
		self:DeleteOnRemove(enemy)
		self:SetNW2Int("EnemyCount",self:GetNW2Int("EnemyCount") +1)
		self:SetPos(pos)
		-- self:PlayerMsg(enemy:GetName() .. " has appeared in the area!")
	end

	for _,v in pairs(player.GetAll()) do
		self:Loadout(v)
	end

	local bots = 0
	for i = 1,self.BotCount do
		local item = ents.Create("npc_vj_fnafsb_bot")
		local points = ents.FindByClass("info_player_start")
		local offset = Vector(0,0,4)
		if #points <= 0 then
			points = player.GetAll()
			offset = VectorRand(-25,25)
		end
		offset.z = 4
		item:SetPos(VJ_PICK(points):GetPos() +offset)
		item:Spawn()
		self:DeleteOnRemove(item)
		self:SetNW2Int("PlayerCount",self:GetNW2Int("PlayerCount") +1)
		bots = bots +1

		local hookName = "VJ_FNaFSB_Remove" .. item:EntIndex()
		hook.Add("EntityRemoved",hookName,function(ent)
			if !IsValid(self) then
				hook.Remove("EntityRemoved",hookName)
				return
			end
			if ent == item then
				self:SetNW2Int("PlayerCount",self:GetNW2Int("PlayerCount") -1)
				hook.Remove("EntityRemoved",hookName)
			end
		end)
	end
	self:SetNW2Int("BotStartCount",bots)

	for i = 1,self.ItemCount do
		local item = ents.Create("sent_vj_fnafsb_item")
		item:SetPos(VJ_FNaF_FindHiddenNavArea(false,true))
		item:Spawn()
		table.insert(self.Items,item)
		self:DeleteOnRemove(item)
		self:SetNW2Int("ItemCount",self:GetNW2Int("ItemCount") +1)
	end

	local staffCount = GetConVar("vj_fnafsb_gm_staffcount"):GetInt()
	if staffCount > 0 then
		-- self.Staff = {}
		for i = 1,staffCount do
			local pickBot = math.random(1,40) == 1 && "npc_vj_fnafsb_staff_map" or VJ_PICK({"npc_vj_fnafsb_staff","npc_vj_fnafsb_staff_security"})
			local bot = ents.Create(pickBot)
			bot:SetPos(VJ_FNaF_FindHiddenNavArea(true,true))
			bot:Spawn()
			-- table.insert(self.Staff,bot)
			self:DeleteOnRemove(bot)
		end
	end

	hook.Add("ShouldCollide","VJ_FNaFSB_NoCollide",function(ent1,ent2)
		if !IsValid(self) then
			hook.Remove("ShouldCollide","VJ_FNaFSB_NoCollide")
			return
		end
		if ent1.VJ_FNAFSB_Bot && ent2:IsPlayer()
		or ent2.VJ_FNAFSB_Bot && ent1:IsPlayer()
		or ent1.VJ_FNAFSB_Bot && ent2.VJ_FNAFSB_Bot
		or ent2.VJ_FNAFSB_Bot && ent1.VJ_FNAFSB_Bot then
			return false
		end
		return true
	end)

	hook.Add("PlayerSpawn","VJ_FNaFSB_PlayerSpawn",function(ply)
		if !IsValid(self) then
			hook.Remove("PlayerSpawn","VJ_FNaFSB_PlayerSpawn")
			return
		end

		if ply:GetNW2Bool("FNaFSB_Death") then
			if GetConVar("ai_ignoreplayers"):GetInt() == 1 then return end
			timer.Simple(0.1,function()
				if !IsValid(self) then return end
				if !IsValid(ply) then return end
				local controlled = false
				if GetConVar("vj_fnafsb_gm_plyenemy"):GetInt() == 1 then
					for _,v in RandomPairs(self.Enemies) do
						if !v.VJ_IsBeingControlled then
							self:PlayerSetMsg(ply,"You are an Enemy. Find and kill all of the Survivors to win!")
							local obj = ents.Create("obj_vj_npccontroller")
							obj.VJCE_Player = ply
							obj:SetControlledNPC(v)
							obj:Spawn()
							obj:StartControlling()
							ply:SetEyeAngles(self:GetAngles())
							obj.VJC_Player_CanExit = false
							obj.VJC_Player_DrawHUD = false
							controlled = true
							break
						end
					end
				end
				timer.Simple(0.02,function()
					if controlled == false then
						local ent = VJ_PICK(self.Enemies)
						if !IsValid(ent) then
							for _,v in RandomPairs(player.GetAll()) do
								if v != ply then
									ent = v
									break
								end
							end
						end
						if !IsValid(ent) then return end
						self:PlayerSetMsg(ply,"You are a Spectator.")
						ply:Spectate(ent:IsPlayer() && OBS_MODE_IN_EYE or OBS_MODE_CHASE)
						ply:SpectateEntity(ent)
						ply:StripWeapons()
						hook.Add("Think","VJ_FNaFSB_Think",function()
							if !IsValid(ent) && IsValid(ply) then
								ply:KillSilent()
								ply:Respawn()
								hook.Remove("Think","VJ_FNaFSB_Think")
							end
						end)
					end
				end)
			end)
		end
	end)

	hook.Add("PlayerDeath","VJ_FNaFSB_PlayerDeath",function(ply)
		if !IsValid(self) then
			hook.Remove("PlayerDeath","VJ_FNaFSB_PlayerDeath")
			for _,v in pairs(player.GetAll()) do
				v:SetNW2Bool("FNaFSB_Death",false)
			end
			return
		end

		if GetConVar("ai_ignoreplayers"):GetInt() == 1 then return end
		self:PlayerNWSound(ply,"cpthazama/fnaf_sb/gamemode/Bell2.wav")
		self:SetNW2Int("PlayerCount",self:GetNW2Int("PlayerCount") -1)
		ply:SetNW2Bool("FNaFSB_Death",true)
	end)

	VJ_FNAF_GAMEMODEENTITY = self

	timer.Simple(0,function()
		if IsValid(self) then
			self.Start = true
		end
	end)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:PlayerNWSound(ply,snd)
    net.Start("vj_fnafsb_gm_sound")
		net.WriteString(snd)
		net.WriteEntity(ply)
    net.Send(ply)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:PlayerSetMsg(v,msg)
	v:ChatPrint(msg)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:PlayerMsg(msg)
	PrintMessage(HUD_PRINTTALK,msg)
	PrintMessage(HUD_PRINTCENTER,msg)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Think()
	if !self.Start then return end
	local remaining = self:GetNW2Int("Remaining")
	local players_alive = 0

	for _,v in pairs(ents.GetAll()) do
		if ((v:IsPlayer() && v:GetMoveType() != MOVETYPE_OBSERVER) or v.VJ_FNAFSB_Bot) && v:Health() > 0 then
			if v:IsPlayer() then
				self:SetPos(v:EyePos())
				if v:IsPlayer() then
					local wSpeed = 100
					local rSpeed = 230
					local jPower = 150
					local cSpeed = 30
					local isRunning = (v:KeyDown(IN_SPEED) && v:Alive() && v:IsOnGround())
					if isRunning then
						if CurTime() > v.VJ_FNaF_NextStaminaDrainT then
							v.VJ_FNaF_Stamina = math_Clamp(v.VJ_FNaF_Stamina -staminaDrain,0,staminaMax)
							v.VJ_FNaF_NextStaminaDrainT = CurTime() +staminaDrainT
						end
						v.VJ_FNaF_NextStaminaRegenDelayT = CurTime() +staminaRegenDelay
					else
						if CurTime() > v.VJ_FNaF_NextStaminaRegenT && CurTime() > v.VJ_FNaF_NextStaminaRegenDelayT then
							local mT = v:GetMoveType()
							if (mT == MOVETYPE_WALK or mT == MOVETYPE_LADDER) && v:GetVelocity():Length() <= 0 then
								staminaRegenT = staminaRegenT *0.5
							end
							v.VJ_FNaF_Stamina = math_Clamp(v.VJ_FNaF_Stamina +staminaRegen,0,staminaMax)
							v.VJ_FNaF_NextStaminaRegenT = CurTime() +staminaRegenT
						end
					end
					if v.VJ_FNaF_Stamina <= 0 then
						wSpeed = wSpeed -(wSpeed *0.3)
						rSpeed = rSpeed -(rSpeed *0.6)
						jPower = jPower -(jPower *0.6)
						cSpeed = cSpeed -(cSpeed *0.5)
					end
					v:SetWalkSpeed(math_Clamp(wSpeed,1,wSpeed))
					v:SetRunSpeed(math_Clamp(rSpeed,1,rSpeed))
					v:SetJumpPower(math_Clamp(jPower,1,jPower))
					v:SetLadderClimbSpeed(math_Clamp(cSpeed,1,cSpeed))
					v:SetNW2Float("VJ_FNaFSB_Stamina",v.VJ_FNaF_Stamina)
				end
				if GetConVar("ai_ignoreplayers"):GetInt() == 1 then continue end
				local wep = v:GetActiveWeapon()
				if IsValid(wep) && wep:GetClass() != "weapon_vj_fnafsb_fazlight" && v:GetNW2Bool("FNaFSB_Death",false) == false then
					v:AllowFlashlight(false)
				end
			end
			players_alive = players_alive +1
		end
	end

	if !self.End then
		if players_alive == 0 or remaining <= 0 then
			self:PlayerMsg(players_alive == 0 && "All Players have died, Animatronics win!" or "All Gifts have been found, Players win!")
			self.End = true
			self:Remove()
		end
	end
	self:NextThink(CurTime() +(0.069696968793869 +FrameTime()))
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnRemove()
	for _,v in pairs(player.GetAll()) do
		v:AllowFlashlight(true)
		v:SetWalkSpeed(v.VJ_FNaF_WSpeed)
		v:SetRunSpeed(v.VJ_FNaF_RSpeed)
		v:SetJumpPower(v.VJ_FNaF_JumpPower)
		v:SetLadderClimbSpeed(v.VJ_FNaF_ClimbSpeed)
		v.DidLoadout = false
		-- v:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	end
end