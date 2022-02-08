/*--------------------------------------------------
	=============== Autorun File ===============
	*** Copyright (c) 2012-2018 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
--------------------------------------------------*/
------------------ Addon Information ------------------
local Name = "FNaF Security Breach - Gamemode"
local PublicAddonName = Name
local AddonName = Name
local AddonType = "SNPC"
local AutorunFile = "autorun/vj_fnafsb_gm_autorun.lua"
-------------------------------------------------------

local VJExists = file.Exists("lua/autorun/vj_base_autorun.lua","GAME")
if VJExists == true then
	include('autorun/vj_controls.lua')

	if !VJ_FNAF_COREINSTALLED then
		return
	end

	VJ_FNAF_GM_INSTALLED = true

	local vCat = Name
	VJ.AddNPC("(Gamemode) Scavenger Hunt","sent_vj_fnafsb_gamemode",vCat)
	VJ.AddNPC("Player Bot","npc_vj_fnafsb_bot",vCat)

	VJ.AddConVar("vj_fnafsb_gm_count", 3, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
	VJ.AddConVar("vj_fnafsb_gm_itemcount", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
	VJ.AddConVar("vj_fnafsb_gm_staffcount", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
	VJ.AddConVar("vj_fnafsb_gm_botcount", 6, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
	VJ.AddConVar("vj_fnafsb_gm_plyenemy", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY})

	FNAF_GM = {}
	FNAF_GM.Characters = {}
	FNAF_GM.Weapons = {}
	
	if CLIENT then
		FNAF_GM.ClientInitialize = function(self)
			if !IsValid(self) then
				print("Could not initialize client-side GM code!")
				return
			end
			self.PlayerMusic = {}
			self.FoundTable = {}
			self.Enemies = {}
			self.Classes = {}
			for _,v in pairs(ents.FindByClass("npc_vj_fnaf*")) do
				if !v.VJ_FNaF_StaffBot && !v.VJ_FNAFSB_Bot && !v.VJ_FNaF_IsFreddy then
					table.insert(self.Enemies,v)
				end
			end
			local ply = LocalPlayer()
			for i = 1,self:GetNW2Int("EnemyCount") do
				local class = ply:GetNW2String("VJ_FNaF_GM_Enemy"..i)
				table.insert(self.Classes,{Class = class,Spotted = false})
				table.insert(self.FoundTable,{Ent = ents.FindByClass(class)[1],Spotted = false})
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

			hook.Add("Think","VJ_FNaFSB_GMThink",function()
				if !IsValid(self) then
					hook.Remove("Think","VJ_FNaFSB_GMThink")
					return
				end
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
						if self.OverrideTrack && tbl.CurrentTrack != self.OverrideTrack then
							tbl.NextTrackT = 0
							self.PlayerMusic[index].CurrentTrack = self.OverrideTrack
							self.PlayerMusic[index].Tracks = {self.OverrideTrack}
							-- print("STOPPED CURRENT TRACK")
						end
						if SysTime() > tbl.NextTrackT then
							if tbl.Music then tbl.Music:Stop() end
							local song = VJ_PICK(tbl.Tracks)
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
			end)

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
				local stamina = ply:GetNW2Float("VJ_FNaFSB_Stamina")
				local staminaMax = 100
				local players = #player.GetAll()
				-- for _,v in pairs(ents.FindByClass("npc_vj_fnaf*")) do
				-- 	if !v.VJ_FNaF_StaffBot && !v.VJ_FNAFSB_Bot && !v.VJ_FNaF_IsFreddy then
				-- 		local canAdd = true
				-- 		for _,n in ipairs(self.FoundTable) do
				-- 			if n && n.Ent == v then
				-- 				canAdd = false
				-- 				break
				-- 			end
				-- 		end
				-- 		if !canAdd then continue end
				-- 		table.insert(self.FoundTable,{Ent = v,Spotted = false})
				-- 	end
				-- end

				local smooth = 8
				local bposX = 10
				local bposY = 10
				local bX = 325
				local bY = 155
				draw.RoundedBox(smooth,bposX,bposY,bX,bY,Color(0,0,0,200))

				draw.SimpleText("Enemies - " .. monsters,"VJ_FNaFSB",bposX +10,bposY +5,Color(255,0,0))
				draw.SimpleText("Gifts - " .. remaining .. "/" .. items,"VJ_FNaFSB",bposX +10,bposY +40,Color(192,189,0))
				draw.SimpleText("Survivors - " .. players_alive .. "/" .. (players +botsOriginal),"VJ_FNaFSB",bposX +10,bposY +75,Color(0,163,192))
				draw.SimpleText("Stamina - " .. stamina .. "/" .. staminaMax,"VJ_FNaFSB",bposX +10,bposY +110,Color(22,192,0))
				
				if stamina <= staminaMax *0.3 then
					local rate = stamina <= 0 && 10 or 6
					local posX = ScrW() *0.15
					local posY = ScrH() *0.01
					local sizeX = ScrH() *0.1
					local sizeY = ScrH() *0.1
					surface.SetDrawColor(255,0,0,math.abs(math.sin(CurTime() *rate) *255))
					surface.SetMaterial(Material("hud/cpthazama/fnafsb/stamina.png"))
					surface.DrawTexturedRect(posX,posY,sizeX,sizeY)
				end

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
						local customTrack = FNAF_GM.GetCharacterData(v.Class).Override
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
	end

	FNAF_GM.AddCharacter = function(name,class,ovSong,filter) -- str Public Name, str Class, str Override Song, table Entities that it can't co-exist with
		table.insert(FNAF_GM.Characters,{Name = name,Class = class,Override = ovSong, Filter = filter})
	end

	FNAF_GM.GetCharacterData = function(class)
		for _,v in pairs(FNAF_GM.Characters) do
			if v.Class == class then
				return v
			end
		end
		return false
	end

	FNAF_GM.AddCharacter(
		"Glamrock Chica",
		"npc_vj_fnafsb_chica",
		nil,
		{"npc_vj_fnafsb_chica_shattered"}
	)
	FNAF_GM.AddCharacter(
		"Roxanne Wolf",
		"npc_vj_fnafsb_roxy",
		nil,
		{"npc_vj_fnafsb_roxy_shattered"}
	)
	FNAF_GM.AddCharacter(
		"Montegomery Gator",
		"npc_vj_fnafsb_monty",
		nil,
		{"npc_vj_fnafsb_monty_shattered"}
	)
	FNAF_GM.AddCharacter(
		"Glamrock Bonnie",
		"npc_vj_fnafsb_bonnie",
		nil,
		{}
	)
	FNAF_GM.AddCharacter(
		"Vanessa A.",
		"npc_vj_fnafsb_vanessa",
		nil,
		{}
	)
	FNAF_GM.AddCharacter(
		"Little Music Man (Withered)",
		"npc_vj_fnafsb_lmm",
		nil,
		{}
	)
	FNAF_GM.AddCharacter(
		"Moon-Drop",
		"npc_vj_fnafsb_moondrop",
		nil,
		{"npc_vj_fnafsb_staff_nightmare_nm","npc_vj_fnafvr_nm"}
	)
	FNAF_GM.AddCharacter(
		"Endo-Skeleton",
		"npc_vj_fnafsb_endo",
		nil,
		{}
	)
	FNAF_GM.AddCharacter(
		"Blob-Skeleton",
		"npc_vj_fnafsb_endo_blob",
		nil,
		{}
	)
	FNAF_GM.AddCharacter(
		"Burntrap",
		"npc_vj_fnafsb_burntrap",
		nil,
		{}
	)
	FNAF_GM.AddCharacter(
		"Glamrock Chica (Shattered)",
		"npc_vj_fnafsb_chica_shattered",
		nil,
		{"npc_vj_fnafsb_chica"}
	)
	FNAF_GM.AddCharacter(
		"Roxanne Wolf (Shattered)",
		"npc_vj_fnafsb_roxy_shattered",
		nil,
		{"npc_vj_fnafsb_roxy"}
	)
	FNAF_GM.AddCharacter(
		"Montegomery Gator (Shattered)",
		"npc_vj_fnafsb_monty_shattered",
		nil,
		{"npc_vj_fnafsb_monty"}
	)
	FNAF_GM.AddCharacter(
		"Nightmarionne (Possessed Form)",
		"npc_vj_fnafsb_staff_nightmare_nm",
		nil,
		{"npc_vj_fnafvr_nm"}
	)

	if CLIENT then
		hook.Add("PopulateToolMenu", "VJ_ADDTOMENU_FNAF_SB_GM", function()
			spawnmenu.AddToolMenuOption("DrVrej", "SNPC Configures", "FNaF Security Breach - Gamemode", "FNaF Security Breach - Gamemode", "", "", function(Panel)
				if !game.SinglePlayer() && !LocalPlayer():IsAdmin() then
					Panel:AddControl("Label", {Text = "#vjbase.menu.general.admin.not"})
					Panel:AddControl( "Label", {Text = "#vjbase.menu.general.admin.only"})
					return
				end
				Panel:AddControl("Label", {Text = "#vjbase.menu.general.admin.only"})
				Panel:AddControl("Button", {Text = "#vjbase.menu.general.reset.everything", Command = "vj_fnafsb_gm_count 2\nvj_fnafsb_gm_itemcount 8"})
				Panel:AddControl("Slider", {Label = "Max Animatronics Count", min = 1, max = 10, Command = "vj_fnafsb_gm_count"})
				Panel:AddControl("Slider", {Label = "Max Presents Count", min = 5, max = 50, Command = "vj_fnafsb_gm_itemcount"})
				Panel:AddControl("Slider", {Label = "Max Bots", min = 0, max = 64, Command = "vj_fnafsb_gm_botcount"})
				Panel:AddControl("Slider", {Label = "Max S.T.A.F.F. Count", min = 0, max = 35, Command = "vj_fnafsb_gm_staffcount"})
				Panel:AddControl("CheckBox", {Label = "Allow Player Enemies", Command = "vj_fnafsb_gm_plyenemy"})
			end)
		end)
	end
	
-- !!!!!! DON'T TOUCH ANYTHING BELOW THIS !!!!!! -------------------------------------------------------------------------------------------------------------------------
	AddCSLuaFile(AutorunFile)
	VJ.AddAddonProperty(AddonName,AddonType)
else
	if (CLIENT) then
		chat.AddText(Color(0,200,200),PublicAddonName,
		Color(0,255,0)," was unable to install, you are missing ",
		Color(255,100,0),"VJ Base!")
	end
	timer.Simple(1,function()
		if not VJF then
			if (CLIENT) then
				VJF = vgui.Create("DFrame")
				VJF:SetTitle("ERROR!")
				VJF:SetSize(790,560)
				VJF:SetPos((ScrW()-VJF:GetWide())/2,(ScrH()-VJF:GetTall())/2)
				VJF:MakePopup()
				VJF.Paint = function()
					draw.RoundedBox(8,0,0,VJF:GetWide(),VJF:GetTall(),Color(200,0,0,150))
				end

				local VJURL = vgui.Create("DHTML",VJF)
				VJURL:SetPos(VJF:GetWide()*0.005, VJF:GetTall()*0.03)
				VJURL:Dock(FILL)
				VJURL:SetAllowLua(true)
				VJURL:OpenURL("https://sites.google.com/site/vrejgaming/vjbasemissing")
			elseif (SERVER) then
				timer.Create("VJBASEMissing",5,0,function() print("VJ Base is Missing! Download it from the workshop!") end)
			end
		end
	end)
end
