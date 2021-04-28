local L = LibStub("AceLocale-3.0"):GetLocale("atroxArenaViewer", true)

AAV_TableGui = {}
AAV_TableGui.__index = AAV_TableGui
local matchesFrame

local matchesTable
local specIconTable
local specRoleTable
local classIconTable
local currentShowType

----
--Initializes the frame that holds the matchesTable.
function AAV_TableGui:createMatchesFrame()

	local o = CreateFrame("Frame", "AAVMatches", UIParent)
	o:SetFrameStrata("HIGH")
	o:SetPoint("Center", 0, 0)
	
	o:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	  tile=1, tileSize=10, edgeSize=10, 
	  insets={left=3, right=3, top=3, bottom=3}
	})
	o:SetMovable(true)
	o:EnableMouse(true)
	o:SetScript("OnMouseDown", function(self, button ) o:StartMoving() end)
	o:SetScript("OnMouseUp", function(self, button ) o:StopMovingOrSizing() end)

	
	local m = CreateFrame("Frame", "$parentTitle", o)
	m:SetHeight(30)
	m:SetPoint("TOP", 0, 18)
	m:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
	  tile=1, tileSize=10, edgeSize=20, 
	  insets={left=3, right=3, top=3, bottom=3}, 
	})
	m:SetBackdropColor(0, 0, 0, 1) -- 0,0,0,1
	m:Show()
    m:SetMovable(true)
	m:SetScript("OnMouseDown", function(self, button) o:StartMoving() end)
	m:SetScript("OnMouseUp", function(self, button) o:StopMovingOrSizing() end)
	

	local ts = m:CreateFontString("$parentName", "ARTWORK", "GameFontNormal")
	ts:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	ts:SetText("AAV: Recorded Matches")
	ts:SetPoint("CENTER", m, 0, 0)
	ts:Show()
	m:SetWidth(ts:GetStringWidth() + 25)
		
	
	local btn = CreateFrame("Button", "$parentCloseButton", o)
	btn:SetHeight(32)
	btn:SetWidth(32)
	
	btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
	
	btn:SetPoint("TOPRIGHT" , o, "TOPRIGHT", 0, 0)
	btn:SetScript("OnClick", function (s, b, d)
		o:Hide()
	end)
	
	matchesFrame = o
end

---
-- Shows the frames and the matchesTable, and initializes them if they are nil
function AAV_TableGui:showMatchesFrame()
	if (not matchesTable) then --All initialization
		AAV_TableGui:createMatchesFrame()
		AAV_TableGui:createMatchesTable()
		--self:generateSpecIconAndRoleTables()
		matchesTable.frame:SetBackdropColor(0.1,0.1,0.1,0.9);
		currentShowType = false

		local width, height = matchesTable.frame:GetSize()
		matchesTable.frame:SetPoint("CENTER",0,-15)
		matchesFrame:SetWidth(width)
		matchesFrame:SetHeight(height + 30)		
	end
	if(atroxArenaViewerData.data and atroxArenaViewerData.data[1] and matchesTable.data and matchesTable.data[1]) then
		-- Quick check to see if the table needs to be updated: if the table has the most recent game and the same number of rows as games recorded then no update required
		if (atroxArenaViewerData.data[1]["startTime"] ~= matchesTable.data[1].cols[1]["value"] or #atroxArenaViewerData.data ~= #matchesTable.data) then
			self:fillMatchesTable()
		end			
	else
		self:fillMatchesTable()
	end
	matchesFrame:Show() 
end

----
-- Tells if the table holding the matches result is showing.
function AAV_TableGui:isMatchesFrameShowing()
	return (matchesFrame and matchesFrame:IsShown())
end

----
-- Hides the matches result table.
function AAV_TableGui:hideMatchesFrame()
	if (matchesFrame) then matchesFrame:Hide() end
end

----
-- Causes the matches result table to be refreshed if it is showing.
function AAV_TableGui:RefreshFrameIfShowing()
	if(self:isMatchesFrameShowing()) then AAV_TableGui:showMatchesFrame() end
end

----
-- Initializes the matches frame table with only columns and OnClick effects. Called by showMatchesFrame().
function AAV_TableGui:createMatchesTable()
	local ScrollingTable = LibStub("ScrollingTable")
	local cols = {
		{
			["name"] = "Date",
		 	["width"] = 100,
			["sort"] = "asc",
		}, -- [1]
		{
			["name"] = "Duration",
			["width"] = 50,
		}, -- [2]
		{
			["name"] = "Map",
			["width"] = 100,
		}, -- [3]
		{
			["name"] = "",
			["width"] = 85,
			["align"] = "RIGHT",
		}, -- [4]
		{
			["name"] = "",
			["width"] = 25,
			["align"] = "RIGHT",
		}, -- [5]
		{
			["name"] = " ",
			["width"] = 85,
			["align"] = "LEFT",
		}, -- [6]
		{
			["name"] = "",
			["width"] = 35,
			["align"] = "CENTER",
		}, -- [7]
		{
			["name"] = "Click to Replay",
			["width"] = 125,
			["align"] = "CENTER",
		}, -- [8]
		{
			["name"] = "Result",
			["width"] = 50,		
		}, -- [9]
		{
			["name"] = "Rating",
			["width"] = 60,		
		}, -- [10]
		{
			["name"] = " ",
			["width"] = 50,		
		}, -- [11]
	}; 

	matchesTable = ScrollingTable:CreateST(cols, 15, 30, nil, matchesFrame);
	matchesTable:RegisterEvents({
		["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
			if (button == "RightButton") then
				--self:hideMatchesFrame()
			elseif (row and column and realrow and atroxArenaViewerData and atroxArenaViewerData.data and atroxArenaViewerData.data[realrow]) then
				if(column == #cols) then
					atroxArenaViewer:deleteMatch(realrow)
					self:showMatchesFrame()
				elseif(column== #cols-3)then
					atroxArenaViewer:replayMatch(atroxArenaViewerData.data[realrow].replay)
				else
					self:hideMatchesFrame()
					atroxArenaViewer:createPlayer(realrow)
					atroxArenaViewer:playMatch(realrow)
				end
			end
		end,
	});
end

----
-- Fills in the data in the matches results table. Called by showMatchesFrame().
function AAV_TableGui:fillMatchesTable()	
	local data = {}
	if(atroxArenaViewerData.data and atroxArenaViewerData.data[1]) then
		local deleteColor  = { ["r"] = 1.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 1.0 };
		local wonMatchColor = { ["r"] = 0.00, ["g"] = 1.0, ["b"] = 0.00, ["a"] = 1.0 };
		local lostMatchColor = { ["r"] = 1.0, ["g"] = 0.00, ["b"] = 0.00, ["a"] = 1.0 };
		local replayColor = { ["r"] = 1.00, ["g"] = 0.49, ["b"] = 0.04, ["a"] = 1.0 };
		local teamOne = {}
		local teamTwo = {}
		local cheatIcon = ""
		
		for row = 1, #atroxArenaViewerData.data do
			if not data[row] then
				data[row] = {};
			end
			data[row].cols = {};
			
			local startTime, elapsedStr, mapname, TeamUm, matchUp,TeamDois, matchResult, teamOneRating, replay, cheatDetected = self:determineMatchSummary(row)
			if(cheatDetected == 1) then cheatIcon = "\124TInterface\\FriendsFrame\\InformationIcon:22\124t" else cheatIcon= "" end

			data[row].cols[1] = { ["value"] = startTime };
			data[row].cols[2] = { ["value"] = elapsedStr };
			data[row].cols[3] = { ["value"] = mapname };
			data[row].cols[4] = { ["value"] = TeamUm };
			data[row].cols[5] = { ["value"] = matchUp };
			data[row].cols[6] = { ["value"] = TeamDois };
			data[row].cols[7] = { ["value"] = cheatIcon };
			data[row].cols[8] = { ["value"] = "ID: "..replay };
			data[row].cols[9] = { ["value"] = matchResult };
			data[row].cols[10] = { ["value"] = teamOneRating };
			data[row].cols[11] = { ["value"] = "DELETE" };
			
			if (matchResult and matchResult == "Won") then
				data[row].cols[9].color = wonMatchColor
				data[row].cols[10].color = wonMatchColor
			elseif (matchResult and matchResult == "Lost") then
				data[row].cols[9].color = lostMatchColor
				data[row].cols[10].color = lostMatchColor
			end
			data[row].cols[11].color = deleteColor
			data[row].cols[8].color = replayColor
		end
	else
		data[1] = {};
		data[1].cols = {};
		for i = 1, 10 do
			data[1].cols[i] = { ["value"] = "None" };
		end
	end
	matchesTable:SetData(data);
	matchesTable:SortData();
end

---
-- Returns the relavent information for match (num). 
-- @param num The match number.
function AAV_TableGui:determineMatchSummary(num)
	local elapsedStr, mapname, teamOneRating, TeamUm, matchUp, TeamDois, matchResult, diff, rating, idSortStr
	local teamdata = atroxArenaViewerData.data[num]["teams"]
	local matchdata = atroxArenaViewerData.data[num]["combatans"]["dudes"]
	local startTime = atroxArenaViewerData.data[num]["startTime"]
	local elapsed = atroxArenaViewerData.data[num].elapsed
	local replay = atroxArenaViewerData.data[num].replay
	local cheatDetected = atroxArenaViewerData.data[num].cheatDetected
	local healersList = {a = true, b = true, c = true}
	
	formatTime = function(time, s)
		if(string.len(time)<2) then
			time = s .. time
		end
		return time
	end
	
	elapsedStr = formatTime(math.floor(elapsed/60), "  ") .. " : " .. formatTime(elapsed%60, "0")

	
	if (type(atroxArenaViewerData.data[num]["map"])=="number") then
		if (AAV_COMM_MAPS[atroxArenaViewerData.data[num]["map"]]) then
			mapname = AAV_COMM_MAPS[atroxArenaViewerData.data[num]["map"]]
		else
			mapname = "Unknown"
		end
	else
		mapname = atroxArenaViewerData.data[num]["map"]
	end
	
	hasSpec = function(w)
		return (w.spec ~= nil and strlen(w.spec) > 0)
	end	

	local teamOne, teamTwo = {}, {}
	for k ,v in pairs(teamdata) do
		local team = k+1
		for c,w in pairs(matchdata) do
		if v.diff=="" then v.diff=0 end
			if (w.player == 1 and w.team == team) then
				if (v.diff and v.diff > 0) then diff = "+" .. tostring(v.diff) else diff = v.diff end
				if (not v.rating) then rating = "? (" .. diff .. ")" else rating = v.rating .. " (" .. diff .. ")" end
				if (w.class and hasSpec(w)) then idSortStr = w.class .. w.spec .. w.name .. c elseif (w.class) then idSortStr = w.class .. " " .. w.name .. c else idSortStr = "   " .. w.name .. c end
				if(w.class and hasSpec(w)) then
					idSortStr = specRoleTable[w.class .. " " .. w.spec] .. idSortStr
				elseif (w.ddone > w.hdone) then 
					idSortStr = "DAMAGER".. idSortStr 
				else 
					idSortStr = "HEALER" .. idSortStr
				end
				if (team == 1) then
					teamOne[idSortStr] = w
					if (not matchResult and v.diff and v.diff ~= 0) then 
						if(v.diff >=0) then matchResult = "Won" else matchResult = "Lost" end
					end
					if (v.rating and v.rating ~= "0") then
						teamOneRating = rating
					end
				elseif (team == 2) then
					teamTwo[idSortStr] = w
					if (not matchResult and v.diff and v.diff ~= 0) then 
						if(v.diff <=0) then matchResult = "Won" else matchResult = "Lost" end
					end
				end
			end
		end
	end
	
	sortNames = function(aTeam) -- Sorts the way the specs/names are displayed, so that DPS comes before healers, then alphabetically sorts through class, spec, name, and guid.
		local keys, sortedNames = {}, ""
		for k in pairs(aTeam) do keys[#keys+1] = k end
		table.sort(keys)
		for k, v in pairs(keys) do
			local w, icon = aTeam[v], nil
			if (atroxArenaViewerData.current.showBySpec and w.class and hasSpec(w)) then 
				icon = specIconTable[w.class .. " " .. w.spec]
			elseif(w.class) then
				AAV_TableGui:getClassColoredName(w.class)
				icon = classIconTable[w.class]
			else
				icon = w.name
			end
			sortedNames = sortedNames .. " " .. icon
		end
		return sortedNames
	end

	matchUp = "  vs  "
	TeamUm = sortNames(teamOne)
	TeamDois = sortNames(teamTwo)
	return startTime, elapsedStr, mapname, TeamUm or "?", matchUp or "?", TeamDois or "?", matchResult or "Lost", teamOneRating, replay or "?", cheatDetected
end

----
-- Brute force initializes the table that contains the spec icon and role of each spec.
function AAV_TableGui:generateSpecIconAndRoleTables()
	specIconTable = {}
	specRoleTable = {}
	for a = 1, 300 do
		local _, spec, _, icon, _, role, class = GetSpecializationInfoByID(a)
		if(spec and icon and class) then
			specIconTable[class .. " " .. spec] = "\124T" .. icon .. ":22\124t"
			specRoleTable[class .. " " .. spec] = role
		end
	end
end

----
-- Uses AAV_Util to get the color that each name should be, and is called if a character's spec is not recorded or if (not showBySpec).
function AAV_TableGui:getClassColoredName(player)
	--local r, g, b = AAV_Util:getTargetColor(player, true)
	classIconTable = {}
	if(player) then classIconTable[player] = "\124TInterface\\Addons\\AAVBlackrock\\res\\"..player..":30\124t" end
	--return "\124c" .. format("ff%02x%02x%02x", r * 255, g * 255, b * 255) .. player.name .. "\124r"
end

