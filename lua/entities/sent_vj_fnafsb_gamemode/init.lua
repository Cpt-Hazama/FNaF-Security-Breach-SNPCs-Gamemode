AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

util.AddNetworkString("vj_fnafsb_gm_sound")
util.AddNetworkString("vj_fnafsb_gm_dat")

ENT.MaxEnemies = 10
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:GiveWeapon(ent,wep)
	ent.VJ_CanBePickedUpWithOutUse = true
	ent.VJ_CanBePickedUpWithOutUse_Class = wep
	ent:Give(wep)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Loadout(v)
	v:Spawn()
	v:StripWeapons()
	v.DidLoadout = true
	timer.Simple(0,function()
		v:SetHealth(100)
		v:SetArmor(100)
		v:SetWalkSpeed(100)
		v:SetRunSpeed(230)
		v:SetJumpPower(150)
		v:SetLadderClimbSpeed(30)
		self:GiveWeapon(v,"weapon_vj_fnafsb_fazlight")
	end)
	self:SetNW2Int("PlayerCount",self:GetNW2Int("PlayerCount") +1)

	self:PlayerSetMsg(v,"You are a Survivor. Find all the Gifts to win!")
	self:PlayerNWSound(v,"cpthazama/fnaf_sb/gamemode/Bell1.wav")
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Initialize()
	self:SetPos(Entity(1):GetPos() +Vector(0,0,15))

	game.CleanUpMap(false,{self:GetClass(),"npc_vj_fnafsb_bot"})

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

	self:SetNW2Int("ItemCount",0)
	self:SetNW2Int("EnemyCount",0)

	self.EnemyCount = math.Clamp(GetConVar("vj_fnafsb_gm_count"):GetInt(),1,self.MaxEnemies)
	self.ItemCount = GetConVar("vj_fnafsb_gm_itemcount"):GetInt()
	self.BotCount = GetConVar("vj_fnafsb_gm_botcount"):GetInt()
	self.End = false
	self.Items = {}
	self.Enemies = {}
	self.EnemiesStoredClasses = {}
	self.EnemyClasses = {
		{Spawned = false, Class = VJ_PICK({"npc_vj_fnafsb_chica","npc_vj_fnafsb_chica_shattered"})},
		{Spawned = false, Class = VJ_PICK({"npc_vj_fnafsb_roxy","npc_vj_fnafsb_roxy_shattered"})},
		{Spawned = false, Class = VJ_PICK({"npc_vj_fnafsb_monty","npc_vj_fnafsb_monty_shattered"})},
		{Spawned = false, Class = "npc_vj_fnafsb_bonnie"},
		{Spawned = false, Class = "npc_vj_fnafsb_vanessa"},
		{Spawned = false, Class = "npc_vj_fnafsb_lmm"},
		{Spawned = false, Class = "npc_vj_fnafsb_moondrop"},
		{Spawned = false, Class = "npc_vj_fnafsb_endo"},
		{Spawned = false, Class = "npc_vj_fnafsb_endo_blob"},
		{Spawned = false, Class = "npc_vj_fnafsb_burntrap"}
	}

	self:SetNW2Int("Remaining",self.ItemCount)

	for i = 1,self.ItemCount do
		local item = ents.Create("sent_vj_fnafsb_item")
		item:SetPos(VJ_FNaF_FindHiddenNavArea(false,false))
		item:Spawn()
		table.insert(self.Items,item)
		self:DeleteOnRemove(item)
		self:SetNW2Int("ItemCount",self:GetNW2Int("ItemCount") +1)
	end

	local staffCount = GetConVar("vj_fnafsb_gm_staffcount"):GetInt()
	if staffCount > 0 then
		-- self.Staff = {}
		for i = 1,staffCount do
			local item = ents.Create(VJ_PICK({"npc_vj_fnafsb_staff","npc_vj_fnafsb_staff_security"}))
			item:SetPos(VJ_FNaF_FindHiddenNavArea(true,false))
			item:Spawn()
			-- table.insert(self.Staff,item)
			self:DeleteOnRemove(item)
		end
	end

	local bots = 0
	for i = 1,self.BotCount do
		local item = ents.Create("npc_vj_fnafsb_bot")
		local points = ents.FindByClass("info_player_start")
		item:SetPos(VJ_PICK(points):GetPos() +Vector(0,0,4))
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

	for _,v in pairs(player.GetAll()) do
		self:Loadout(v)
	end

	for i = 1,self.EnemyCount do
		local function PickEnemy()
			local tbl = {}
			for i,v in pairs(self.EnemyClasses) do
				if v.Spawned == false then
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
		local pos = VJ_FNaF_FindHiddenNavArea(true,false)
		if pos == false then
			SafeRemoveEntity(enemy)
			enemy = ents.Create(PickEnemy())
			pos = VJ_FNaF_FindHiddenNavArea(true,false)
			if !IsValid(enemy) then return end
		end
		enemy:SetPos(pos)
		enemy:SetAngles(Angle(0,math.random(0,360),0))
		enemy:Spawn()
		enemy.IdleAlwaysWander = true
		enemy.GodMode = true
		enemy.VJ_NPC_Class = {"CLASS_FNAF_ANIMATRONIC"}
		table.insert(self.Enemies,enemy)
		table.insert(self.EnemiesStoredClasses,enemy:GetClass())
		self:DeleteOnRemove(enemy)
		self:SetNW2Int("EnemyCount",self:GetNW2Int("EnemyCount") +1)
		-- self:PlayerMsg(enemy:GetName() .. " has appeared in the area!")
	end

    net.Start("vj_fnafsb_gm_dat")
		net.WriteTable(self.Enemies)
		net.WriteTable(self.EnemiesStoredClasses)
		net.WriteEntity(self)
    net.Broadcast()

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
	local remaining = self:GetNW2Int("Remaining")
	local players_alive = 0
	for _,v in pairs(ents.GetAll()) do
		if (v:IsPlayer() && v:GetMoveType() != MOVETYPE_OBSERVER) or v.VJ_FNAFSB_Bot then
			if v:IsPlayer() then
				if math.random(1,2) == 1 then self:SetPos(v:GetPos()) end -- Prevent HUD from soft-locking
				if GetConVar("ai_ignoreplayers"):GetInt() == 1 then continue end
				local wep = v:GetActiveWeapon()
				if IsValid(wep) && wep:GetClass() != "weapon_vj_fnafsb_fazlight" then
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
		v.DidLoadout = false
	end
end