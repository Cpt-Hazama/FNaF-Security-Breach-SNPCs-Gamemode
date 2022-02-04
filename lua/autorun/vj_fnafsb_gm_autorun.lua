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
