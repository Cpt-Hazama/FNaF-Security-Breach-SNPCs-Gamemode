ENT.Base 			= "base_anim"
ENT.Type 			= "anim"
ENT.PrintName 		= ""
ENT.Author 			= "Cpt. Hazama"
ENT.Contact 		= ""
ENT.Purpose 		= ""
ENT.Instructions 	= ""
ENT.Category		= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

if SERVER then return end

net.Receive("vj_fnafsb_gm_sound",function(len,ply)
	local snd = net.ReadString()
	local ply = net.ReadEntity()
	if !IsValid(ply) then return end
	VJ_EmitSound(ply,snd)
end)

net.Receive("vj_fnafsb_gm_dat",function(len,ply)
	local npcs = net.ReadTable()
	local classes = net.ReadTable()
	local ind = net.ReadInt(14)
	local self = Entity(ind)
end)

surface.CreateFont("VJ_FNaFSB",{
	font = "Orbitron Black",
	size = 40,
})

ENT.SpecialTracks = {
	["npc_vj_fnafsb_staff_nightmare_nm"] = "cpthazama/fnaf_sb/gamemode/music/Sleep_No_More.mp3"
}

function ENT:Initialize()
	self.PlayerMusic = {}
	self.FoundTable = {}
	self.Enemies = {}
	self.Classes = {}
	for _,v in pairs(ents.FindByClass("npc_vj_fnafsb_*")) do
		if !v.VJ_FNaF_StaffBot && !v.VJ_FNAFSB_Bot && !v.VJ_FNaF_IsFreddy then
			table.insert(self.Enemies,v)
		end
	end
	local ply = LocalPlayer()
	for i = 1,GetConVar("vj_fnafsb_gm_count"):GetInt() do
		table.insert(self.Classes,{Class = ply:GetNW2String("VJ_FNaF_GM_Enemy" .. i),Spotted = false})
	end

	hook.Add("PreDrawHalos","VJ_FNaFSB_RenderFX",function()
		if !IsValid(self) then
			hook.Remove("PreDrawHalos","VJ_FNaFSB_RenderFX")
			return
		end
		local ply = LocalPlayer()

		if ply.IsControlingNPC then
			local tbl = {}
			local col = Color(255,65,65)
			for _,v in pairs(ents.GetAll()) do
				local invT = v:GetNW2Int("VJ_FNaF_SpotT",0)
				if invT == 0 then continue end
				if CurTime() < invT then
					table.insert(tbl,v)
				end
			end
			halo.Add(tbl,col,5,5,3,true,true)
		end
	end)

	---------------------------------------------------------------------------------------------------------------------------------------------------------

	local function InViewCone(self,ent)
		if ent:GetClass() == "obj_vj_bullseye" then return false end
		local me = self
		local vec = me:GetPos() -ent:GetPos()
		local len = vec:Length()
		local width = me:BoundingRadius() *0.5
		local cosi = math.abs(math.cos(math.acos(len /math.sqrt(len *len +width *width)) +(me:GetFOV() or 45) *(math.pi /180)))
		vec:Normalize()

		local tr = util.TraceLine({
			start = me:EyePos(),
			endpos = ent:GetPos() +ent:OBBCenter(),
			filter = me,
			-- mask = MASK_SOLID_BRUSHONLY,
		})

		return (vec:Dot(ent:EyeAngles():Forward()) > cosi && tr.Entity == ent)
	end

	hook.Add("HUDPaint","VJ_FNaFSB_GMHUD",function()
		if !IsValid(self) then
			hook.Remove("HUDPaint","VJ_FNaFSB_GMHUD")
			return
		end

		local ply = LocalPlayer()
		local monsters = self:GetNW2Int("EnemyCount")
		local items = self:GetNW2Int("ItemCount")
		local remaining = self:GetNW2Int("Remaining")
		local players_alive = self:GetNW2Int("PlayerCount")
		local botsOriginal = self:GetNW2Int("BotStartCount")
		local players = #player.GetAll()
		for _,v in pairs(ents.FindByClass("npc_vj_fnafsb_*")) do
			if !v.VJ_FNaF_StaffBot && !v.VJ_FNAFSB_Bot && !v.VJ_FNaF_IsFreddy then
				local canAdd = true
				for _,n in ipairs(self.FoundTable) do
					if n && n.Ent == v then
						canAdd = false
						break
					end
				end
				if !canAdd then continue end
				table.insert(self.FoundTable,{Ent = v,Spotted = false})
			end
		end

		local smooth = 8
		local bposX = 10
		local bposY = 10
		local bX = 325
		local bY = 120
		draw.RoundedBox(smooth,bposX,bposY,bX,bY,Color(0,0,0,200))

		draw.SimpleText("Enemies - " .. monsters,"VJ_FNaFSB",bposX +10,bposY +5,Color(255,0,0))
		draw.SimpleText("Gifts - " .. remaining .. "/" .. items,"VJ_FNaFSB",bposX +10,bposY +40,Color(192,189,0))
		draw.SimpleText("Survivors - " .. players_alive .. "/" .. (players +botsOriginal),"VJ_FNaFSB",bposX +10,bposY +75,Color(0,163,192))

		local monsterTbl = self.FoundTable
		local setSpotted = false
		if monsterTbl then
			for i,v in pairs(monsterTbl) do
				if IsValid(v.Ent) && v.Spotted != true && InViewCone(ply,v.Ent) then
					v.Spotted = true
					setSpotted = v.Ent:GetClass()
					break
				end
			end
		end
		if !self.Classes then return end
		for i,v in pairs(self.Classes) do
			if setSpotted == v.Class then
				v.Spotted = true
				local customTrack = self.SpecialTracks[v.Class]
				if customTrack then
					self.OverrideTrack = customTrack
				end
			end
			if ply:GetNW2Bool("FNaFSB_Death") == true then
				v.Spotted = true
			end
			local setPositions = {0.47,0.53,0.41,0.59,0.35,0.65,0.29,0.71,0.23,0.77}
			local posX = ScrW() *setPositions[i]
			local posY = ScrH() *0.03
			local sizeX = ScrH() *0.1
			local sizeY = ScrH() *0.1
			surface.SetDrawColor(255,0,0)
			surface.SetMaterial(Material("hud/cpthazama/fnafsb/portraits/background.png"))
			surface.DrawTexturedRect(posX -3,posY -3,sizeX +6,sizeY +6)

			surface.SetDrawColor(255,255,255)
			surface.SetMaterial(Material("hud/cpthazama/fnafsb/portraits/" .. ((v.Spotted == false && "unknown") or v.Class) .. ".png"))
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
			local dir = "sound/cpthazama/fnaf_sb/gamemode/music/set" .. math.random(1,3) .. "/"
			local files = file.Find(dir .. "*.mp3","GAME")
			local fixedFiles = {}
			for _,v in pairs(files) do
				table.insert(fixedFiles,dir .. v)
			end
			self.PlayerMusic[index] = {Player = v,Music = nil,CurrentTrack = nil,Tracks = fixedFiles,NextTrackT = 0}
		else
			local index = 0
			for i,ply in pairs(self.PlayerMusic) do
				if ply.Player == v then
					index = i
					break
				end
			end
			if index == 0 then return end
			local tbl = self.PlayerMusic[index]
			-- if self.OverrideTrack && tbl.CurrentTrack != self.OverrideTrack then
			-- 	tbl.NextTrackT = 0
			-- 	self.PlayerMusic[index].CurrentTrack = self.OverrideTrack
			-- end
			if SysTime() > tbl.NextTrackT then
				if tbl.Music then tbl.Music:Stop() end
				local song = self.OverrideTrack or VJ_PICK(tbl.Tracks)
				-- print("Started new " .. song)
				sound.PlayFile(song,"noplay noblock",function(soundchannel,errorID,errorName)
					if IsValid(soundchannel) then
						soundchannel:Play()
						soundchannel:EnableLooping(false)
						soundchannel:SetVolume(0.7)
						soundchannel:SetPlaybackRate(1)
						self.PlayerMusic[index].Music = soundchannel
						self.PlayerMusic[index].CurrentTrack = song
					end
				end)
				self.PlayerMusic[index].NextTrackT = SysTime() +VJ_SoundDuration(song)
			end
		end
	end
end