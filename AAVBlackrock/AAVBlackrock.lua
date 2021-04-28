--[[

Originally created by Zwacky - adapted and improved by Jammin
Jammin#8283 on discord for any problems

]]--

atroxArenaViewer = LibStub("AceAddon-3.0"):NewAddon("atroxArenaViewer", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("atroxArenaViewer", false)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")


local libS = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local libBase64 = LibStub("LibBase64-1.0")

local M -- AAV_MatchStub
local T -- AAV_PlayStub
local timer -- playback timer
local currentstate = 1
local exportnum = 0
local currentbracket = nil
local tempbuffs = {} -- used for determining new buffs
local tempdebuffs = {} -- used for determining new debuffs
local exceptauras = { -- these auras won't be tracked
	32727,	-- Arena Preparation
}
--Anticheat variables
local lastcdused = {}
local diff = 0


-------------------------
-- GLOBALS
-------------------------
AAV_VERSIONMAJOR = 2
AAV_VERSIONMINOR = 2
AAV_VERSIONBUGFIX = 2
AAV_UPDATESPEED = 60
AAV_AURAFULLINDEXSTEP = 1
AAV_INITOFFTIME = 0.5
AAV_MANATRESHOLD = 5
AAV_MINIMUM_COOLDOWN = 5
AAV_AURA_LONGLASTING = 180
AAV_MAX_AURASVISIBLE = 11

AAV_GUI_VERTICALFRAMEDISTANCE = 140
AAV_GUI_MAXCOMBATTEXTOBJECTS = 25
AAV_GUI_MAXUSEDSKILLSOBJECTS = 12
AAV_GUI_HEALTHBARHEIGHT = 16
AAV_GUI_MANABARHEIGHT = 5
AAV_GUI_UPDATEFRAME = CreateFrame("Frame")

AAV_COMBATTEXT_PERSISTENCE = 2.0
AAV_COMBATTEXT_FADETIME = 0.8
AAV_COMBATTEXT_CRITTIME = 0.5
AAV_COMBATTEXT_FRAMESPEED = 40
AAV_COMBATTEXT_ALPHASPEED = 3
AAV_COMBATTEXT_CRITSPEED = 30
AAV_COMBATTEXT_SCROLLINGTEXTFONTSIZE = 12
AAV_COMBATTEXT_SCROLLINGTEXTCRITPLUS = 26

AAV_USEDSKILL_PERSISTENCE = 6.0
AAV_USEDSKILL_FRAMESPEED = 60
AAV_USEDSKILL_ICONSPEED = 150
AAV_USEDSKILL_FADEINSPEED = 10
AAV_USEDSKILL_FADEOUTSPEED = 0.5
AAV_USEDSKILL_FADEOUTTIME = 2.0
AAV_USEDSKILL_FADEINTIME = 1
AAV_USEDSKILL_ICONSIZE = 25
AAV_USEDSKILL_ICONMARGIN = 3
AAV_USEDSKILL_ICONBUFFSIZE = 15

AAV_CROWD_FADEOUTTIME = 0.2
AAV_CROWD_FADEOUTSPEED = 10
AAV_CROWD_FADEINTIME = 0.5
AAV_CROWD_FADEINSPEED = 10

AAV_CC_ICONSIZE = 15
AAV_CC_ICONMARGIN = 1
AAV_CC_ICONSPEED = 150
AAV_CC_FADEINTIME = 0.5
AAV_CC_FADEINSPEED = 10
AAV_CC_FADEOUTTIME = 0.25
AAV_CC_FADEOUTSPEED = 10
AAV_CC_MAXLISTING = 5

AAV_DETAIL_ENTRYHEIGHT = 20
AAV_DETAIL_ENTRYWIDTH = 560


AAV_COMM_MAPS = {
	[1] = L.ARENA_NAGRAND,
	[2] = L.ARENA_LORDAERON,
	[3] = L.ARENA_BLADEEDGE,
	[4] = L.ARENA_DALARAN,
	[5] = L.ARENA_VALOR,
}

StaticPopupDialogs["AAV_EXPORT_DIALOG"] = {
	text = "Copy this export string.",
	button1 = "OK",
	hasEditBox = true,
	OnShow = function (s, d)
		s.editBox:SetText(atroxArenaViewer:getRecursiveExport(atroxArenaViewerData.data[exportnum]))
		s.editBox:HighlightText(0)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}
StaticPopupDialogs["AAV_IMPORT_DIALOG"] = {
	text = "Paste Match String",
	button1 = "Import",
	button2 = "Cancel",
	hasEditBox = true,
	OnAccept = function(s, d)
		local finaldata
		local str = s.editBox:GetText()
		local finalData = atroxArenaViewer:importMatch(str)
		if(finalData) then
		print("|cffe392c5<AAV>|r Sucessfully Imported Match")
		local matchid = atroxArenaViewer:getNewMatchID()
			atroxArenaViewerData.data[matchid] = atroxArenaViewerData.data[matchid] or {}
			atroxArenaViewerData.data[matchid] = finalData
		end
	  end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}



function atroxArenaViewer:OnInitialize()
	
	atroxArenaViewerData = atroxArenaViewerData or {
		defaults = {
			profile = {
				update = 0.1,
				interval = 0.1,
				minimapx = -54.6,
				minimapy = 58.8,
				healthdisplay = 3, -- deficit percentage
				shortauras = true, -- don't exceed debuff buff bar
				slidercds = AAV_CDSKILLS,
				announceCheaters = true,
			}
		}
	}
	
	atroxArenaViewerData.current = {
		inArena = false,
		inFight = false,
		entered = 0,
		time = 0,
		move = 0,
		record = true,
		interval = 0.1,
		update = 0.1,
	}
    
    local minimap = AAV_Gui:createMinimapIcon(self)
    
    print("|cffe392c5<AAV Blackrock Version>|r v"..AAV_VERSIONMAJOR.."."..AAV_VERSIONMINOR.."."..AAV_VERSIONBUGFIX.. " " .. L.AAV_LOADED)

	
    
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
    
	--OPTIONS
	local options = {
		type = "group",
		name = "AAVBlackrock",
		args = {
			GeneralOptions = {
				type = 'group',
				--inline = true,
				name = "General Settings",
				desc = "General Options for AAV",
				set = setOption,
				get = getOption,
				order = 1,
				args = {
					healthdisplay = {
						type = 'group',
						inline = true,
						name = "Health Display",
						order = 1,
						args = {
							healthopt = {
								type = 'select',
								name = "Health Options",
								desc = "Choose the healthbar type you want to see on the player",
								values = AAV_HEALTHOPTIONS,
								order = 1,
							},
						},
					},
					shortauras = {
						type = 'group',
						inline = true,
						name = "Buffs and Debuffs",
						order = 2,
						args = {
							aurasopt = {
								type = 'toggle',
								name = "Don't Exceed Buffs and Debuffs",
								width = "double",
								desc = "Toggle if you want to exceed buffs and debuffs on the player",
								order = 1,
							},
						},
					},
					announceCheaters = {
						type = 'group',
						inline = true,
						name = "Announcements",
						order = 3,
						args = {
							cheatsopt = {
								type = 'toggle',
								name = "Announce Cheaters in /say",
								width = "double",
								desc = "Toggle if you want to announce when a cheat has been detected with /say",
								order = 1,
							},
						},
					},
				},
			},
			slidercds = {
				type = 'group',
				--inline = true,
				name = "Slider Options",
				desc = "Options for the slider when replaying a game",
				set = setOption,
				get = getOption,
				order = 2,
				args = {
					header = {
						type = 'header',
						name = "Slider Cooldowns",
						order = 1,
					},
					general = {
						type = 'group',
						inline = true,
						name = "General spells",
						order = 2,
						args = {
							trinket = {
								type = 'toggle',
								name = AAV_Util:SpellTexture(42292).."PvP Trinket/Every Man for Himself",
								desc = function ()
									GameTooltip:SetHyperlink(GetSpellLink(42292));
								end,
								descStyle = "custom",
								order = 1,
							},
						}
					},
					druid = {
						type = 'group',
						inline = true,
						name = "|cffFF7D0ADruid|r",
						order = 4,
						args = getArgs({61336,50334,53312,22812,17116,22842,29166,33357}),
					},
					paladin = {
						type = 'group',
						inline = true,
						name = "|cffF58CBAPaladin|r",
						order = 7,
						args = getArgs({498,64205,1044,642,10278,6940,10308,31884,54428,20216,31821,20066}),
					},
					rogue = {
						type = 'group',
						inline = true,
						name = "|cffFFF569Rogue|r",
						order = 9,
						args = getArgs({1766,51722,2094,14185,26669,8643,11305,26889,31224,57934,14177,13877,13750,51690,51713,36554}),
					},
					warrior	= {
						type = 'group',
						inline = true,
						name = "|cffC79C6EWarrior|r",
						order = 12,
						args = getArgs({72,2565,676,20230,5246,871,18499,1719,23920,3411,55694,46924,12975,46968}),
					},
					priest	= {
						type = 'group',
						inline = true,
						name = "|cffFFFFFFPriest|r",
						order = 8,
						args = getArgs({6346,10890,34433,48173,64843,64901,48158,33206,10060,14751,47585,15487,64044}),
					},
					shaman	= {
						type = 'group',
						inline = true,
						name = "|cff0070DEShaman|r",
						order = 10,
						args = getArgs({8177,32182,2825,51514,58582,59159,16166,51533,30823,16188,16190,57994}),
					},
					mage = {
						type = 'group',
						inline = true,
						name = "|cff69CCF0Mage|r",
						order = 6,
						args = getArgs({12051,1953,45438,2139,66,42917,43012,42945,43039,55342,12043,11129,44572,31687,11958,12472}),
					},
					dk	= {
						type = 'group',
						inline = true,
						name = "|cffC41F3BDeath Knight|r",
						order = 3,
						args = getArgs({47476,48707,51052,48792,48743,47568,49028,49016,49039,49203,51271,49206}),
					},
					hunter = {
						type = 'group',
						inline = true,
						name = "|cffABD473Hunter|r",
						order = 5,
						args = getArgs({781,3045,5384,19263,53271,60192,14311,13809,49012,19503,23989,34490,19577,19574}),
					},
					warlock = {
						type = 'group',
						inline = true,
						name = "|cff9482C9Warlock|r",
						order = 11,
						args = getArgs({17928,54785,50589,47860,48020,18708,59672,17962,59172}),
					},
				},
			},
		}
	}
	AceConfig:RegisterOptionsTable("AAVBlackrock_options", options)
	AceConfigDialog:AddToBlizOptions("AAVBlackrock_options", "AAVBlackrock")
	


end

function atroxArenaViewer:changeRecording()
	if (atroxArenaViewerData.current.record == true) then
		if (atroxArenaViewerData.current.inArena == false) then
			atroxArenaViewerData.current.record = false
			print(L.CMD_DISABLE_RECORDING)
		else
			print("Aktion in der Arena nicht möglich.")
		end
		--if (atroxArenaViewerData.current.inArena == true) then self:handleEvents("stop") end -- [#18] removed
	else
		atroxArenaViewerData.current.record = true
		--if (atroxArenaViewerData.current.inArena == true) then self:handleEvents("start") end -- [#18] removed
		print(L.CMD_ENABLE_RECORDING)
	end
end


function atroxArenaViewer:onUpdate(elapsed)
	-- update combat text movements
	if (T) then
		T:onUpdate(elapsed * (atroxArenaViewerData.current.interval * 10))
	end
	
	return
end


----
-- status 1 = in queue, in arena: message board; 2 = entered
function atroxArenaViewer:UPDATE_BATTLEFIELD_STATUS(event, status)
	if (atroxArenaViewerData.current.record and M) then	
		if (status == 1 and atroxArenaViewerData.current.inArena) then		
			local found
			for i=0,1 do
				found = false
				local teamName, oldRating, newRating, teamSkill = GetBattlefieldTeamInfo(i)
				if (teamName ~= "") then
					for j=1,3 do
						local name,_,ratiing = GetArenaTeam(j)
						if (name == teamName) then
							M:setTeams(0, teamName, ratiing, newRating - oldRating, teamSkill)
							found = true
							break
						end
					end
				end
				if not (found) then
					--local teamName, oldRating, newRating, teamSkill = GetBattlefieldTeamInfo(i)
					if (teamName ~= "") then
						M:setTeams(1, teamName, 0, newRating - oldRating, teamSkill)
					else
						M:setTeams(i, "Team " .. (i+1), 0, 0, 0)
					end
				end
			end
		end
	end
end

----
-- event to track the start of the arena match.
-- @param event
-- @param msg message to compare
function atroxArenaViewer:CHAT_MSG_RAID_BOSS_EMOTE(event, msg)
if (atroxArenaViewerData.current.record == true) then
			atroxArenaViewerData.current.entered = self:getCurrentTime()
			atroxArenaViewerData.current.time = GetTime()
			M:setBracket(self:getCurrentBracket())
			
			for i = 1, 5 do
				if (UnitExists("raid" .. i)) then
					local key, player = M:updateMatchPlayers(1, "raid" .. i)
				end
			end
			for i = 1, self:getCurrentBracket() do
				if (UnitExists("arena" .. i)) then
					local key, player = M:updateMatchPlayers(2, "arena"..i)
				end
			end
						
			self:handleEvents("register")
		end
currentstate = 8
end
function atroxArenaViewer:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)

	
	if (string.upper(msg) == string.upper(L.ARENA_START)) then
		if (atroxArenaViewerData.current.record == true) then
			atroxArenaViewerData.current.entered = self:getCurrentTime()
			atroxArenaViewerData.current.time = GetTime()
			M:setBracket(self:getCurrentBracket())

			
			for i = 1, 5 do
				if (UnitExists("raid" .. i)) then
					local key, player = M:updateMatchPlayers(1, "raid" .. i)
				end
			end
			
			self:handleEvents("register")
		end
		currentstate = 8
	elseif (msg == L.ARENA_60) then
		currentstate = 4
			for i = 1, self:getCurrentBracket() do
				if (UnitExists("arena" .. i)) then
					local key, player = M:updateMatchPlayers(2, "arena"..i)
				end
			end	
	elseif (msg == L.ARENA_45) then
		currentstate = 5
	elseif (msg == L.ARENA_30) then
		currentstate = 6
			for i = 1, self:getCurrentBracket() do
				if (UnitExists("arena" .. i)) then
					local key, player = M:updateMatchPlayers(2, "arena"..i)
				end
			end
	elseif (msg == L.ARENA_15) then
		currentstate = 7
			for i = 1, self:getCurrentBracket() do
				if (UnitExists("arena" .. i)) then
					local key, player = M:updateMatchPlayers(2, "arena"..i)
				end
			end
	end
end


function atroxArenaViewer:ZONE_CHANGED_NEW_AREA(event, unit)

	if (GetZonePVPInfo() == "arena") then
		CombatLogClearEntries() -- fixes combat log parse overflow problem
		self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
		self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")

		
		atroxArenaViewerData.current.inArena = true
		atroxArenaViewerData.current.entered = self:getCurrentTime()
		atroxArenaViewerData.current.time = GetTime()
		
		M = AAV_MatchStub:new()
		--Reset lastcdused & diff
		lastcdused = {}
		for a, b in pairs  (AAV_CHEATSKILS) do
			lastcdused[a] = {}
		end
		diff = 0
		
		self:RegisterEvent("ARENA_OPPONENT_UPDATE")
		
	else --save match
		if (atroxArenaViewerData.current.inArena) then
			
			self:handleEvents("unregister")
			self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
			self:UnregisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
			self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
			
			
			if (atroxArenaViewerData.current.record) then
				atroxArenaViewerData.data = atroxArenaViewerData.data or {}
				local matchid = self:getNewMatchID()
				
				atroxArenaViewerData.data[matchid] = atroxArenaViewerData.data[matchid] or {}
				
				M:setMatchEnd()
				M:saveToVariable(matchid)
			end
			atroxArenaViewerData.current.inArena = false
			atroxArenaViewerData.current.entered = 0
			atroxArenaViewerData.current.time = 0
			atroxArenaViewerData.current.move = 0
			
		end
	end
end

-----
function atroxArenaViewer:handleEvents(val)
	if (val == "register") then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("UNIT_HEALTH")
		self:RegisterEvent("UNIT_MANA")
		self:RegisterEvent("UNIT_AURA")
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		self:RegisterEvent("ARENA_OPPONENT_UPDATE")
		self:RegisterEvent("UNIT_NAME_UPDATE")
		atroxArenaViewerData.current.inFight = true
		
		
	--	print("[debug] REGISTERING all events")
	elseif (val == "unregister") then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("UNIT_HEALTH")
		self:UnregisterEvent("UNIT_MANA")
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
		self:UnregisterEvent("UNIT_NAME_UPDATE")
		self:UnregisterEvent("UNIT_AURA")
		
		atroxArenaViewerData.current.inFight = false
	--	print("[debug] unregistering all events")
		
	end
end
----
-- returns the player, null if not initialized.
-- @return T playstub
function atroxArenaViewer:getPlayer()
	return T
end

----
-- used to initialize the visible units when match starts.
-- @param val "raid" or "arena" specified
-- @param side 1 = left (self), 2 = right (enemies)
function atroxArenaViewer:initArenaMatchUnits(arr)
	local unit, side = arr[1], arr[2]
	local hp, hpmax, guid
	local buffs, debuffs = {}, {}
	local i, n = 1, 1
	
	if (UnitName(unit) == L.UNKNOWN or UnitClass(unit) == nil) then return end
	
	guid = M:getGUIDtoNumber(UnitGUID(unit))
	if (not guid) then return end
	
	-- BUFFS
	for n = 1, 40 do
		local _, _, icon, _, _, _, _, _, _, _, b = UnitBuff(unit, n) --spellid
		if (b and not self:isExcludedAura(spellId)) then
			if (string.find(string.lower(icon), "_mount_") == nil and string.lower(icon) ~= "inv_misc_key_14" and string.lower(icon) ~= "inv_misc_key_06") then
				table.insert(buffs, b)
			end
		else
			break
		end
	end
	
	-- DEBUFFS
	for n = 1, 40 do
		_, _, _, _, _, _, _, _, _, _, b = UnitDebuff(unit, n) --spellid
		if (b and not self:isExcludedAura(spellId)) then
			table.insert(debuffs, b)
		else
			break
		end
	end
	
	for k,v in pairs(buffs) do
		M:getBuffs(guid)[k] = true
	end
	for k,v in pairs(debuffs) do
		M:getDebuffs(guid)[k] = true
	end
	
	self:createMessage(self.getDiffTime(), "0," .. guid .. "," .. UnitHealth(unit) .. "," .. UnitHealthMax(unit) .. "," .. table.concat(buffs, ";") .. "," .. table.concat(debuffs, ";"))
end

function atroxArenaViewer:createMessage(tick, msg)
	if (atroxArenaViewerData.current.record) then
		M:createMessage(tick .. "," .. msg)
	end
end

----
-- queries the current zone and compares the text with the ones in the AAV_COMM_MAPS.
-- @return map id
function atroxArenaViewer:getCurrentMapId()
	for k,v in pairs(AAV_COMM_MAPS) do
		if (GetZoneText() == v) then
			return k
		end
	end
	return 0
end

----
-- monitors the change of mana in consideration of mana treshold (AAV_MANATRESHOLD).
-- @param event
-- @param unit
function atroxArenaViewer:UNIT_MANA(event, unit)
	
	local player = M:getDudesData()[UnitGUID(unit)]
	if (player) then --and (player.mana > (UnitMana(unit)/UnitManaMax(unit))) then
		
		local mana = math.floor((UnitMana(unit)/UnitManaMax(unit))*100)
		if not (mana > player.mana - AAV_MANATRESHOLD and mana < player.mana + AAV_MANATRESHOLD) then
			player.mana = mana
			local u = M:getGUIDtoNumber(UnitGUID(unit))
			if (u) then self:createMessage(self:getDiffTime(), "17," .. u .. "," .. mana) end
		end
	end
end

----
-- monitors the change of Health, inclusive Max HP.
-- Currently limited to raid and arena targets (no pets).
-- @param event
-- @param unit
function atroxArenaViewer:UNIT_HEALTH(event, unit)
	local sub = string.sub(unit,1,4)
	if (sub == "raid" or sub == "aren") then

		local target = M:getChangeInHealthFlags(unit)
		local u = M:getGUIDtoNumber(UnitGUID(unit))
		
		if (bit.band(target, 0x1) ~= 0 and u) then
			self:createMessage(self:getDiffTime(), "1," .. u .. "," .. UnitHealth(unit))
		end
		if (bit.band(target,0x2) ~= 0 and u) then
			self:createMessage(self:getDiffTime(), "2," .. u .. "," .. UnitHealthMax(unit))
		end
	end
end

function atroxArenaViewer:UNIT_AURA(event, unit)
	local n, m = 1, 1
	local sub = string.sub(unit,1,4)
	if (sub ~= "raid" and sub ~= "aren") then return end
	
	local id = M:getGUIDtoNumber(UnitGUID(unit))
	if (not id) then return end
	
	for n = 1, 40 do
		local _, _, _, _, _, btime, _, _, _, _, bspellid = UnitBuff(unit, n)
		local _, _, _, _, _, dtime, _, _, _, _, dspellid = UnitDebuff(unit, n)
		
		if (not bspellid and not dspellid) then break end
		
		if (bspellid) then tempbuffs[bspellid] = true end
		if (dspellid) then tempdebuffs[dspellid] = true end
		
		if (bspellid and not M:getBuffs(id)[bspellid]) then
			-- create new buff
			M:getBuffs(id)[bspellid] = true
			
			if (not btime) then btime = 0 end
			self:createMessage(self:getDiffTime(), "13," .. id .. "," .. bspellid .. ",1," .. btime)
		end
		if (dspellid and not M:getDebuffs(id)[dspellid]) then
			-- create new debuff
			M:getDebuffs(id)[dspellid] = true
			
			if (not dtime) then dtime = 0 end
			self:createMessage(self:getDiffTime(), "13," .. id .. "," .. dspellid .. ",2," .. dtime)
		end
	end
	
	for k,v in pairs(M:getBuffs(id)) do
		if (not tempbuffs[k]) then
			--remove
			self:createMessage(self:getDiffTime(), "14," .. id .. "," .. k .. ",1")
			M:getBuffs(id)[k] = nil
		end
	end
	for k,v in pairs(M:getDebuffs(id)) do
		if (not tempdebuffs[k]) then
			--remove
			self:createMessage(self:getDiffTime(), "14," .. id .. "," .. k .. ",2")
			M:getDebuffs(id)[k] = nil
		end
	end
	
	for k,v in pairs(tempbuffs) do
		tempbuffs[k] = nil
	end
	for k,v in pairs(tempdebuffs) do
		tempdebuffs[k] = nil
	end
	
end

function atroxArenaViewer:UNIT_NAME_UPDATE(event, unit)

	if (UnitIsPlayer(unit)) then
		if (not M) then return end
		local sourceGUID = UnitGUID(unit)
		
		M:getDudesData()[sourceGUID].name = UnitName(unit)
	end
end

function atroxArenaViewer:ARENA_OPPONENT_UPDATE(event, unit, type)
	local u = M:getGUIDtoNumber(UnitGUID(unit))
	local arenaUnits = {}
	for i=1, 5 do
		arenaUnits["arena" .. i] = "playerUnit"
		arenaUnits["arenapet" .. i] = "arena" .. i
	end
	if (type == "seen") then
		if (arenaUnits[unit] == "playerUnit") then

			local key, player = M:updateMatchPlayers(2, unit)
		end
		
	elseif (type == "unseen") then
		-- lost track (stealth)
		if (u) then self:createMessage(self:getDiffTime(), "18," .. u .. ",1") end
		
	elseif (type == "destroyed") then
		-- has left the arena
		if (u) then self:createMessage(self:getDiffTime(), "18," .. u .. ",3") end
		
	end
end

--HACK FOR PENANCE BECAUSE BLACKROCK'S core
function atroxArenaViewer:UNIT_SPELLCAST_CHANNEL_START(event, unit)
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)	
	local arenaUnits = {}
	local time = 0
	for i=1, 5 do
		arenaUnits["arena" .. i] = "playerUnit"
		arenaUnits["arenapet" .. i] = "arena" .. i
	end
	if(spell and spell=="Penance") then
		eventType = 10
			local sourceGUID = UnitGUID(unit)
			local source = M:getGUIDtoNumber(sourceGUID)
			local spellId = 53007
			local target, destTarget = M:getGUIDtoTarget(sourceGUID), ""
			if (target) then destTarget = M:getGUIDtoNumber(UnitGUID(target .. "target")) end
			if (not destTarget) then destTarget = source end
			local casttime = (endTime - startTime)
			local _, duration, _ = GetSpellCooldown(GetSpellInfo(53007))
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. destTarget .. "," .. spellId .. "," .. time)

	end
end
function atroxArenaViewer:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical = select(1, ...)
	local eventType, msg

	local source = M:getGUIDtoNumber(sourceGUID)
	local dest = M:getGUIDtoNumber(destGUID)
	if (not absorbed) then absorbed = 0 end
	
	-- TYPE 3
	if (type == "SWING_DAMAGE") then
		eventType = 3
		if (not critical) then critical = 0 end
		if (source and dest and amount) then -- dont track damage from unknown sources and destinations
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. dest .. "," .. amount .. "," .. critical)
			M:addStats(1, sourceGUID, amount + absorbed)
		end
	elseif (type == "SPELL_DAMAGE") then
		eventType = 4
		if (not critical) then critical = 0 end
		if (source and dest and amount) then -- dont track damage from unknown sources and destinations
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. dest .. "," .. amount .. "," .. critical)
			M:addStats(1, sourceGUID, amount + absorbed)
		end
	elseif (type == "SPELL_PERIODIC_DAMAGE") then
		eventType = 5
		if (not critical) then critical = 0 end
		if (source and dest and amount) then -- dont track damage from unknown sources and destinations
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. dest .. "," .. amount .. "," .. critical)
			M:addStats(1, sourceGUID, amount + absorbed)
		end
	elseif (type == "RANGE_DAMAGE") then
		eventType = 6
		if (not critical) then critical = 0 end
		if (source and dest and amount) then -- dont track damage from unknown sources and destinations
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. dest .. "," .. amount .. "," .. critical)
			M:addStats(1, sourceGUID, amount + absorbed)
		end
	elseif (type == "SPELL_HEAL") then
		eventType = 7
		if (not critical) then critical = 0 end
		if (source and dest and amount) then -- dont track damage from unknown sources and destinations
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. dest .. "," .. amount .. "," .. critical)
			M:addStats(2, sourceGUID, amount - overkill)
		end
	elseif (type == "SPELL_PERIODIC_HEAL") then
		eventType = 8
		if (not critical) then critical = 0 end
		if (source and dest and amount) then -- dont track damage from unknown sources and destinations
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. dest .. "," .. amount .. "," .. critical)
			M:addStats(2, sourceGUID, amount - overkill)
		end
	elseif (type == "SPELL_CAST_START") then
		eventType = 9
		if (source) then
			local target, destTarget = M:getGUIDtoTarget(sourceGUID), ""
			if (target) then destTarget = M:getGUIDtoNumber(UnitGUID(target .. "target")) end
			if (not destTarget) then destTarget = source end
			local _, _, _, _, _, _, casttime = GetSpellInfo(spellId)
			local _, duration, _ = GetSpellCooldown(spellId)
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. destTarget .. "," .. spellId .. "," .. casttime .. "," .. duration)
		end
	elseif (type == "SPELL_CAST_SUCCESS") then
		eventType = 10
		if (source) then
			if (not dest) then dest = -1 end
			local time = 0
			local theTime = self:getDiffTime()
			local isCdHacking = 0
			-- ANTICHEAT CDHACK
			if (AAV_CHEATSKILS[spellId]) then 
				if (not lastcdused[tonumber(spellId)][source]) then lastcdused[tonumber(spellId)][source] = 0 end
				diff = tonumber(theTime) - lastcdused[spellId][source]
				if (diff < AAV_CCSKILS[tonumber(spellId)] and lastcdused[tonumber(spellId)][source] ~= 0) then
					if (atroxArenaViewerData.defaults.profile.announceCheaters) then
						local spellname = GetSpellInfo(spellId)
						SendChatMessage("CHEAT DETECTED: "..M:getDudesData()[sourceGUID].name.." cast "..spellname.." with a "..diff.." second cooldown, impossible without the use of a CD Hack" ,"SAY")
					else
						print("|cFFFF0000<AAV> Cheat Detector Triggered:|r CD Hack - Check the Addon after the game to learn more")
					end
					isCdHacking = 1				

				end
				lastcdused[tonumber(spellId)][source] = theTime
			end
			GetSpellCooldown(spellId)
			if(isCdHacking == 0) then
				self:createMessage(theTime, eventType .. "," .. source .. "," .. dest .. "," .. spellId .. "," .. time)
			else
				self:createMessage(theTime, eventType .. "," .. source .. "," .. dest .. "," .. spellId .. "," .. time..","..diff)
				M:setCheatDetection(isCdHacking)
			end
		end
	elseif (type == "SPELL_CAST_FAILED") then
		-- cant be tracked from others
		
	elseif (type == "SPELL_INTERRUPT") then
		eventType = 12
		if (source and dest) then
			self:createMessage(self:getDiffTime(), eventType .. "," .. source .. "," .. dest .. "," .. spellId .. "," .. amount)
		end
	elseif (type == "SPELL_AURA_APPLIED") then
		--[[
		eventType = 13
		if (source and dest) then
			local time = 0
			local target
			if (amount == "BUFF") then amount = 1 else amount = 2 end -- buffs = 1, debuffs = 2
			
			if (AAV_IMPORTANTSKILLS[spellId]) then -- check importantskill
				local target = M:getGUIDtoTarget(destGUID)
				if (target) then 
					for i=1,40 do
						spid = 0
						if (amount == 1) then 
							_, _, _, _, _, time, _, _, _, _, spid = UnitBuff(target, i)
						elseif (amount == 2) then
							_, _, _, _, _, time, _, _, _, _, spid = UnitDebuff(target, i)
						end
						if (spid == spellId) then break end -- spell found
					end
				end
			end
			
			if (not time) then time = 0 end
			self:createMessage(self:getDiffTime(), eventType .. "," .. dest .. "," .. spellId .. "," .. amount .. "," .. time)
		end
		--]]
	elseif (type == "SPELL_AURA_REMOVED") then
		--[[
		eventType = 14
		if (source and dest) then
			if (amount == "BUFF") then amount = 1 else amount = 2 end -- buffs = 1, debuffs = 2
			self:createMessage(self:getDiffTime(), eventType .. "," .. dest .. "," .. spellId .. "," .. amount)
		end
		--]]
	elseif (type == "SPELL_AURA_REFRESH") then
		eventType = 15
		--[[
		if (source and dest) then
			if (amount == "BUFF") then amount = 1 else amount = 2 end -- buffs = 1, debuffs = 2
			self:createMessage(self:getDiffTime(), eventType .. "," .. dest .. "," .. spellId .. "," .. amount)
		end
		--]]
	elseif (type == "UNIT_DIED") then
		eventType = 16
		-- 17 MANA
	end
	
end

----
-- check function whether omitted spellid is in the exceptauras table.
-- @param spellid
-- @return true if it's excluded and unwanted spell
function atroxArenaViewer:isExcludedAura(spellid)
	for k,v in pairs(exceptauras) do
		if (spellId == v) then 
			return true
		end
	end
	return false
end

function atroxArenaViewer:getNewMatchID()
	local max = 0
	for k,v in pairs(atroxArenaViewerData.data) do
		if (tonumber(k) > max) then
			max = k
		end
	end
	return max + 1
end

function atroxArenaViewer:getCurrentBracket()
	for i=1,2 do
		local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
		if (status == "active" and teamSize > 0) then
			currentbracket = teamSize
			break
		end
	end
	return currentbracket
end

function atroxArenaViewer:getCurrentTime()
	return date("%m/%d/%y %H:%M:%S")
end

function atroxArenaViewer:getDiffTime()
	return math.ceil((GetTime() - atroxArenaViewerData.current.time)*100)/100
end



function atroxArenaViewer:createPlayer(num)
	local i = 1
	
	if (not T) then T = AAV_PlayStub:new() end
	
	T:hidePlayer(T.player)
	T:setOnUpdate("start")
	
	T:setMatchData(num)
	
	if (not T:getMatchData(1)) then
		return
	end
	
	T:createPlayer(atroxArenaViewerData.data[num].bracket, atroxArenaViewerData.data[num].elapsed, false)
	
	print("|cffe392c5<AAV>|r Start playing: " .. AAV_COMM_MAPS[atroxArenaViewerData.data[num].map] .. " at " .. atroxArenaViewerData.data[num].startTime)
end

function atroxArenaViewer:deleteMatch(num)
	table.remove(atroxArenaViewerData.data, num)
end
function atroxArenaViewer:replayMatch(num)
	SendChatMessage(".replay "..num ,"SAY" ,nil ,"channel");
end

function atroxArenaViewer:exportMatch(num)
	exportnum = num
end

----
-- recursive function for export.
-- @param tab table
-- @param input if set then add skill legend
function atroxArenaViewer:getRecursiveExport(inTable)

-- Taken from WeakAuras: credit to Mirrored and the rest of their team
	local ret = "{\n";
	local function recurse(table, level)
		for i,v in pairs(table) do
			ret = ret..strrep("    ", level).."[";
			if(type(i) == "string") then
				ret = ret.."\""..i.."\"";
			else
				ret = ret..i;
			end
			ret = ret.."] = ";

			if(type(v) == "number") then
				ret = ret..v..",\n"
			elseif(type(v) == "string") then
				ret = ret.."\""..v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\""):gsub("\124", "\124\124").."\",\n"
			elseif(type(v) == "boolean") then
				if(v) then
					ret = ret.."true,\n"
				else
					ret = ret.."false,\n"
				end
			elseif(type(v) == "table") then
				ret = ret.."{\n"
				recurse(v, level + 1);
				ret = ret..strrep("    ", level).."},\n"
			else
				ret = ret.."\""..tostring(v).."\",\n"
			end
		end
	end

	if(inTable) then
		recurse(inTable, 1);
	end
	ret = ret.."}";
	
	local serialized = libS:Serialize(ret)
	local addedCheck = format("%s::%s", serialized, "Jammin")
	local compressed =  libC:Compress(addedCheck)
	local encoded = libBase64.Encode(compressed)

	return encoded
end

function atroxArenaViewer:getMatch()
	return T:getMatch()
end

----
-- plays the given match.
-- @param num matchid
function atroxArenaViewer:playMatch(num)
	local pre
	
	if (T:getCurrentMatchData()) then
		pre = AAV_Util:split(T:getCurrentMatchData(), ',')
		T:removeAllCC()
		T:removeAllCooldowns()
		T:setTickTime(tonumber(pre[1]))
		T:setMapText(T:getMatch()["map"])
		
		T:handleTimer("start")
	else
		print("Error - bad match data.")
	end
end

function atroxArenaViewer:evaluateMatchData()
	local done = false
	local post
	
	T:setTickTime(T:getTickTime() + atroxArenaViewerData.current.interval)
	T:updatePlayerTick()
	
	while not done do
		if (not T:getCurrentMatchData()) then
			T:handleTimer("stop")
			done = true
		else
			post = AAV_Util:split(T:getCurrentMatchData(), ',')
			if (not T:getCurrentMatchData() or (tonumber(post[1]) >= T:getTickTime())) then
				done = true
			else
				self:executeMatchData(T:getTick(), post)
				T:setTick(T:getTick() + 1)
			end
		end
	end
end

function atroxArenaViewer:executeMatchData(tick, data)
	local t = tonumber(data[2])
	
	-- init
	if (t == 0) then
		T:setBar(tonumber(data[3]), tonumber(data[4]))
		T:setMaxBar(tonumber(data[3]), tonumber(data[5]))
		--[[
		T:removeAllAuras(tonumber(data[3]))
		
		local buffs = AAV_Util:split(data[6], ";")
		
		if (buffs) then
			for k,v in pairs(buffs) do
				for c,w in pairs(buffs) do
					-- sexx
					T.entities[id]
				end
				T:addAura(tonumber(data[3]), tonumber(v), 1)
			end
		end
		
		local debuffs = AAV_Util:split(data[7], ";")
		if (debuffs) then
			for k,v in pairs(debuffs) do
				T:addAura(tonumber(data[3]), tonumber(v), 2)
			end
		end
		--]]
	-- current HP
	elseif (t == 1) then
		T:setBar(tonumber(data[3]), tonumber(data[4]))
		
	-- max HP
	elseif (t == 2) then
		T:setMaxBar(tonumber(data[3]), tonumber(data[4]))
		
	-- damage
	elseif (t == 3 or t == 4 or t == 5 or t == 6) then	
		T:addFloatingCombatText(tonumber(data[4]), tonumber(data[5]), tonumber(data[6]), 1)
		--T:addDamage(tonumber(data[4]), tonumber(data[5]))
		
	-- heal	
	elseif (t == 7 or t == 8) then
		T:addFloatingCombatText(tonumber(data[4]), tonumber(data[5]), tonumber(data[6]), 2)
		--T:addHeal(tonumber(data[4]), tonumber(data[5]))
		
	-- cast starts
	elseif (t == 9) then
		T:addSkillIcon(tonumber(data[3]), tonumber(data[5]), true, tonumber(data[4]), tonumber(data[6]))
		
	-- cast success
	elseif (t == 10) then
		T:addSkillIcon(tonumber(data[3]), tonumber(data[5]), false, tonumber(data[4]))
		
		if (tonumber(data[6]) and AAV_CCSKILS[tonumber(data[5])]) then
			T:addCooldown(tonumber(data[3]), tonumber(data[5]), AAV_CCSKILS[tonumber(data[5])])
		end
		
	elseif (t == 11) then
		-- cast interrupt, not implemented
		
	elseif (t == 12) then
		-- spell_interrupt
		T:interruptSkill(tonumber(data[3]), tonumber(data[4]), tonumber(data[5]), tonumber(data[6]))
		
	elseif (t == 13) then
		-- spell_aura_applied
		T:addAura(tonumber(data[3]), tonumber(data[4]), tonumber(data[5]))
		if (data[6] and tonumber(data[6]) > 0 and AAV_IMPORTANTSKILLS[tonumber(data[4])]) then
			T:addCC(tonumber(data[3]), tonumber(data[4]), tonumber(data[6]), AAV_IMPORTANTSKILLS[tonumber(data[4])])
		end
		
		if (AAV_BUFFSTOSKILLS[tonumber(data[4])]) then
			T:addSkillIcon(tonumber(data[3]), tonumber(data[4]), false, nil)
		end
		
	elseif (t == 14) then
		-- spell_aura_removed
		T:removeAura(tonumber(data[3]), tonumber(data[4]), tonumber(data[5]))
		if (AAV_IMPORTANTSKILLS[tonumber(data[4])]) then
			T:removeCC(tonumber(data[3]), tonumber(data[4]))
		end
		
	elseif (t == 15) then
		-- spell_aura_refreshed
		
	elseif (t == 16) then
		-- died
		
	elseif (t == 17) then
		-- mana changes
		T:setMana(tonumber(data[3]), tonumber(data[4]))
		
	elseif (t == 18) then
		-- visibility changes
		T:setVisibility(tonumber(data[3]), tonumber(data[4]))
		
	end
	
end
function atroxArenaViewer:CHAT_MSG_ADDON(event, prefix)
	if(prefix == "ARENASPEC") then
		if (atroxArenaViewerData.current.inArena) then
			
			self:handleEvents("unregister")
			self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
			self:UnregisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
			self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
			
			atroxArenaViewerData.current.inArena = false
			atroxArenaViewerData.current.entered = 0
			atroxArenaViewerData.current.time = 0
			atroxArenaViewerData.current.move = 0
			
		end
	end
end

function atroxArenaViewer:CHAT_MSG_SYSTEM(event, message)
	if(M) then
		local sub = string.sub(message,1,6)
		if(sub == "Replay") then
			local replay = string.sub(message,17)
			M:setReplay(replay)
		end
	end
end
function atroxArenaViewer:importMatch(encoded)
	if libBase64.IsBase64(encoded) then
		local decoded = libBase64.Decode(encoded)

		--Decompress the decoded data
		local decompressed, message = libC:Decompress(decoded)
		if(not decompressed) then
			print("|cffe392c5<AAV>|r error decompressing: " .. message)
			return 
		end
	
		-- Deserialize the decompressed data
		local serializedData, success, theCheck
		serializedData = AAV_Util:split(decompressed, "^^::") -- "^^" indicates the end of the AceSerializer string
		if (not serializedData[1] or serializedData[2] ~= "Jammin") then
			print("|cffe392c5<AAV>|r ERROR - String is invalid or corrupted!")
			print(serializedData[2])
			return 
		end
		
		serializedData[1] = format("%s%s", serializedData[1], "^^") --Add back the AceSerializer terminator
		
		local result, final = libS:Deserialize(serializedData[1])
		if (not result) then
			print("|cffe392c5<AAV>|r error deserializing " .. final)
			return 
		end
		
		-- STRING-TO_TABLE
		local strToTable = loadstring(format("%s %s", "return", final))
		if strToTable then
			message, finalData = pcall(strToTable)
		end
		
		if not finalData then
			print("|cffe392c5<AAV>|r Error converting lua string to table:", message)
			return 
		end
		return finalData
	end
	print("|cffe392c5<AAV>|r ERROR - String is corrupted or invalid")
	return
end
--OPTION FUNCTIONS
function getArgs(spellList)
	local args = {}
	for k,v in pairs(spellList) do
		if (AAV_CDSTONAMES[v]) then
			rawset(args, AAV_CDSTONAMES[v], spellArg(k, v))
		else
			print("Doesnt exist"..v)
		end
	end
	return args
end
function spellArg(order, spellID, ...)
	local spellname,_,icon = GetSpellInfo(spellID)
	if spellname ~= nil then
	return {
		type = 'toggle',
		name = "\124T"..icon..":24\124t"..spellname,							
		desc = function () 
			GameTooltip:SetHyperlink(GetSpellLink(spellID));
		end,
		descStyle = "custom",
		order = order,
	}
	end
end
function setOption(info, value)
	local name = info[#info]
	local parent = info[#info-2]
	if(parent ~= "slidercds") then
		atroxArenaViewerData.defaults.profile[info[#info-1]] = value
	elseif(parent == "slidercds") then
		for k,v in pairs(AAV_CDSTONAMES) do
			if(name == v) then
				atroxArenaViewerData.defaults.profile[parent][k] = value
			end
		end
	else
		print("AAV: Something went wrong, please contact Jammin on discord @ Jammin#8283")
	end
end

function getOption(info)
	local name = info[#info]
	local parent = info[#info-2]
	
	if(parent ~= "slidercds") then
		name = atroxArenaViewerData.defaults.profile[info[#info-1]]
	elseif(parent == "slidercds") then
		for k,v in pairs(AAV_CDSTONAMES) do
			if(name == v) then
				name = atroxArenaViewerData.defaults.profile[parent][k]
			end
		end
	else
		print("AAV: Something went wrong, please contact Jammin on discord @ Jammin#8283")
	end
	return name
end


