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
	FNAF_GM.ClientInitialize(self)
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