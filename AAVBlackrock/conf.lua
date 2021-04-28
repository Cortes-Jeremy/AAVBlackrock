
local L = LibStub("AceLocale-3.0"):GetLocale("atroxArenaViewer", true)

-- Slash commands
SLASH_ATROXARENAVIEWER1 = "/aav"
SLASH_ATROXARENAVIEWER2 = "/AAV"
SlashCmdList["ATROXARENAVIEWER"] = function(msg)
	msg = string.lower(msg or "")
	
	local self = _G["atroxArenaViewer"]
	
	print("> /aav " .. msg)
	
	if (msg == "import") then
		StaticPopup_Show("AAV_IMPORT_DIALOG")
		
	elseif (msg == "ui") then
		if(AAV_TableGui:isMatchesFrameShowing()) then
			AAV_TableGui:hideMatchesFrame()
		else
			AAV_TableGui:showMatchesFrame()
		end
	
	elseif (msg == "record") then
		self:changeRecording()
		
	elseif (msg == "options") then
		InterfaceOptionsFrame_OpenToCategory("AAVBlackrock")
		
--[[	elseif (msg == "play") then
		if (atroxArenaViewerData.data) then
			print(L.CONF_DESCR_PLAY)
			for k,v in pairs(atroxArenaViewerData.data) do
				print("   " .. k .. " - " .. v.map .. " at " .. v.startTime)
			end
		else
			print(L.NO_MATCHES_FOUND)
		end
	elseif (string.find(msg, 'play%s%d*')) then
		local num = tonumber(string.sub(msg, 6))
		if (num and atroxArenaViewerData.data[num]) then
			self:createPlayer(num)
			self:playMatch(num)
		else
			print(L.ERROR_WRONG_INPUT)
		end
	elseif (msg == "delete") then
		if (atroxArenaViewerData.data) then
			print(L.CONF_DESCR_DELETE)
			for k,v in pairs(atroxArenaViewerData.data) do
				print("   " .. k .. " - " .. v.map .. " at " .. v.startTime)
			end
		else
			print(L.NO_MATCHES_FOUND)
		end ]]--
	elseif (msg == "delete all") then
		numOfMatches = #atroxArenaViewerData.data
		for i = 1, numOfMatches do
			parent:deleteMatch(1) 
		end
--[[	elseif (string.find(msg, 'delete%s%d*')) then
		local num = tonumber(string.sub(msg, 8))
		if (num) then			
			self:deleteMatch(num)
			print(L.CONF_MATCH_DELETED)
		else
			print(L.ERROR_WRONG_INPUT)
		end ]]--
	else
	
		print(L.CONF_HELP_LINE1)
		print(L.CONF_HELP_LINE2)
		print(L.CONF_HELP_LINE3)
		print(L.CONF_HELP_LINE4)
		print(L.CONF_HELP_LINE5)
		print(L.CONF_HELP_LINE6)

	end
	
end