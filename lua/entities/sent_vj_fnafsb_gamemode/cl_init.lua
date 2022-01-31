include('shared.lua')

if SERVER then return end

net.Receive("vj_fnafsb_gm_sound",function(len,ply)
	local snd = net.ReadString()
	local ply = net.ReadEntity()
	VJ_EmitSound(ply,snd)
end)

net.Receive("vj_fnafsb_gm_dat",function(len,ply)
	local npcs = net.ReadTable()
	local classes = net.ReadTable()
	local self = net.ReadEntity()
	self.Enemies = npcs
	self.Classes = classes
end)

surface.CreateFont("VJ_FNaFSB",{
	font = "Orbitron Black",
	size = 40,
})

ENT.PlayerMusic = {}

function ENT:Initialize()
	-- hook.Add("PlayerDeath","VJ_FNaFSB_SpawnMusic",function(ply)
	-- 	if !IsValid(self) then
	-- 		hook.Remove("PlayerDeath","VJ_FNaFSB_SpawnMusic")
	-- 		return
	-- 	end
	-- 	if ply.VJ_FNaFSB_Tracks then
	-- 		for _,v in SortedPairs(ply.VJ_FNaFSB_Tracks) do
	-- 			if v && IsValid(v.channel) then
	-- 				v.channel:Stop()
	-- 			end
	-- 		end
	-- 	end
	-- 	table.Empty(self.VJ_FNaFSB_Tracks)
	-- end)

	-- hook.Add("Think","VJ_FNaFSB_Think",function()
	-- 	if !IsValid(self) then
	-- 		hook.Remove("Think","VJ_FNaFSB_Think")
	-- 		return
	-- 	end
	-- 	local ply = LocalPlayer()
	-- 	if ply.VJ_FNaFSB_Tracks == nil or #ply.VJ_FNaFSB_Tracks <= 0 then
	-- 		ply.VJ_FNaFSB_Tracks = {}

	-- 		local function CreateTrack(song,ID)
	-- 			if song == false or song == nil then return end
	-- 			sound.PlayFile("sound/" .. song,"noplay noblock",function(soundchannel,errorID,errorName)
	-- 				if IsValid(soundchannel) then
	-- 					soundchannel:Play()
	-- 					soundchannel:EnableLooping(true)
	-- 					soundchannel:SetVolume(0)
	-- 					soundchannel:SetPlaybackRate(1)
	-- 					table.insert(ply.VJ_FNaFSB_Tracks,{ID=ID,channel=soundchannel})
	-- 				end
	-- 			end)
	-- 		end
	-- 	end

	-- 	local function StopTrack(song,vol)
	-- 		if vol then
	-- 			if IsValid(song) && song:GetState() == 1 then
	-- 				song:SetVolume(0)
	-- 			end
	-- 			return
	-- 		end
	-- 		song:Stop()
	-- 	end

	-- 	ply.VJ_FNaFSB_Tracks = ply.VJ_FNaFSB_Tracks or {}
	-- 	ply.VJ_FNaFSB_CurrentTrack = ply.VJ_FNaFSB_CurrentTrack or NULL

	-- 	if ply.VJ_FNaFSB_esiaTrackID != trackID && trackID != ply.VJ_FNaFSB_esiaTrackLastID then
	-- 		for _,v in ipairs(ply.VJ_FNaFSB_Tracks) do
	-- 			if v.class == ent:GetClass() && v.ID == trackID && IsValid(v.channel) then
	-- 				v.channel:SetVolume(0.75)
	-- 				ply.VJ_FNaFSB_esiaTrack = v.channel
	-- 				break
	-- 			end
	-- 		end
	-- 	end
	-- end)

	hook.Add("HUDPaint","VJ_FNaFSB_GMHUD",function()
		if !IsValid(self) then
			hook.Remove("HUDPaint","VJ_FNaFSB_GMHUD")
			return
		end

		local ply = LocalPlayer()
		-- local monsterTbl = {}
		local monsters = self:GetNW2Int("EnemyCount")
		local items = self:GetNW2Int("ItemCount")
		local remaining = self:GetNW2Int("Remaining")
		local players_alive = self:GetNW2Int("PlayerCount")
		local botsOriginal = self:GetNW2Int("BotStartCount")
		local players = #player.GetAll()
		-- for _,v in pairs(ents.FindByClass("npc_vj_fnafsb_*")) do
		-- 	if !v.VJ_FNaF_StaffBot && !v.VJ_FNAFSB_Bot && !v.VJ_FNaF_IsFreddy then
		-- 		table.insert(monsterTbl,v)
		-- 	end
		-- end

		local smooth = 8
		local bposX = 10
		local bposY = 10
		local bX = 325
		local bY = 120
		draw.RoundedBox(smooth,bposX,bposY,bX,bY,Color(0,0,0,200))

		draw.SimpleText("Enemies - " .. monsters,"VJ_FNaFSB",bposX +10,bposY +5,Color(255,0,0))
		draw.SimpleText("Gifts - " .. remaining .. "/" .. items,"VJ_FNaFSB",bposX +10,bposY +40,Color(192,189,0))
		draw.SimpleText("Survivors - " .. players_alive .. "/" .. (players +botsOriginal),"VJ_FNaFSB",bposX +10,bposY +75,Color(0,163,192))

		if !self.Classes then return end
		for i,v in pairs(self.Classes) do
			local setPositions = {0.47,0.53,0.41,0.59,0.35,0.65,0.29,0.71,0.23,0.77}
			local posX = ScrW() *setPositions[i]
			local posY = ScrH() *0.03
			local sizeX = ScrH() *0.1
			local sizeY = ScrH() *0.1
			surface.SetDrawColor(255,0,0)
			surface.SetMaterial(Material("hud/cpthazama/fnafsb/portraits/background.png"))
			surface.DrawTexturedRect(posX -3,posY -3,sizeX +6,sizeY +6)

			surface.SetDrawColor(255,255,255)
			surface.SetMaterial(Material("hud/cpthazama/fnafsb/portraits/" .. v .. ".png"))
			surface.DrawTexturedRect(posX,posY,sizeX,sizeY)
		end
	end)
end

function ENT:Draw()
	return false
end

function ENT:OnRemove()
	for _,v in pairs(self.PlayerMusic) do
		if v.Music then
			v.Music:Stop()
		end
	end
end

function ENT:Think()
	for _,v in pairs(player.GetAll()) do
		local found = false
		for _,ply in pairs(self.PlayerMusic) do
			if ply.Player == v then
				found = true
				break
			end
		end
		if !found then
			local index = #self.PlayerMusic +1
			self.PlayerMusic[index] = {Player = v,Music = nil}
			sound.PlayFile("sound/music/background.mp3","noplay noblock",function(soundchannel,errorID,errorName)
				if IsValid(soundchannel) then
					soundchannel:Play()
					soundchannel:EnableLooping(true)
					soundchannel:SetVolume(0.7)
					soundchannel:SetPlaybackRate(1)
					self.PlayerMusic[index].Music = soundchannel
				end
			end)
		end
	end
end