
local L = LibStub("AceLocale-3.0"):GetLocale("atroxArenaViewer", true)

AAV_Gui = {}
AAV_Gui.__index = AAV_Gui

local currentPlayerFrame -- Fix this later (TODO)
local currentPlayerObject = {} -- Fix this later (TODO)

function AAV_Gui:createPlayerFrame(obj, bracket)
	if (not bracket) then
		return
	end
	
	currentPlayerObject = obj -- Fix this later (TODO)
	-- ROOT FRAME
	local o = CreateFrame("Frame", "Root", UIParent)
	o:SetFrameStrata("HIGH")
	o:SetWidth(560)
	o:SetPoint("Center", 0, 0)
	self:setPlayerFrameSize(o, bracket)
	--MATCH PLAYER
	local f = CreateFrame("Frame", "MatchPlayer", o)
	f:SetFrameStrata("HIGH")
	f:SetWidth(560)
	f:SetPoint("TOPLEFT", o, "TOPLEFT", 0, 0)
	currentPlayerFrame = f:GetParent() -- Fix this later (TODO)
	self:setPlayerFrameSize(f, bracket)
	
	o:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
	  tile=1, tileSize=10, edgeSize=10, 
	  insets={left=3, right=3, top=3, bottom=3}
	})
	o:SetMovable(true)
	o:EnableMouse(true)
	o:SetScript("OnMouseDown", o.StartMoving)
	o:SetScript("OnMouseUp", o.StopMovingOrSizing)
	o:Show()
	
	local m = CreateFrame("Frame", "$parentMapText", o)
	m:SetHeight(30)
	m:SetPoint("TOP", 0, 18)
	m:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
	  tile=1, tileSize=10, edgeSize=20, 
	  insets={left=3, right=3, top=3, bottom=3}, 
	})
	m:SetBackdropColor(0, 0, 0, 1)
	
	local mt = m:CreateFontString("$parentName", "ARTWORK", "GameFontNormal")
	mt:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	mt:SetText("???")
	mt:SetPoint("CENTER", m, 0, 0)
	mt:Show()
	
	--CLOSE BUTTON
	local btn = CreateFrame("Button", "PlayerCloseButton", o)
	btn:SetHeight(32)
	btn:SetWidth(32)
	
	btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

	btn:SetPoint("TOPRIGHT" , o, "TOPRIGHT", 0, 0)
	btn:SetScript("OnClick", function (s, b, d)
		obj:hidePlayer(s:GetParent())
		obj:hideMovingObjects()
		obj:setOnUpdate("stop")
	end)
	btn:Show()
	
	--BACK BUTTON
	local backbtn = CreateFrame("Button", "PlayerBackButton", f, "UIPanelButtonTemplate")
	backbtn:SetHeight(25)
	backbtn:SetWidth(40)
	backbtn:SetText("Back")
	backbtn:SetPoint("TOPLEFT" , o, "TOPLEFT", 7, -7)
	backbtn:SetScript("OnClick", function (s, b, d)
		obj:hidePlayer((s:GetParent()):GetParent())
		obj:hideMovingObjects()
		obj:setOnUpdate("stop")
		AAV_TableGui:showMatchesFrame()
	end)
	backbtn:Show()
	
	--REPLAY BUTTON
	local replay = CreateFrame("BUTTON", "$parentViewreplay", f, "UIPanelButtonTemplate")
	replay:SetPoint("BOTTOMRIGHT", -190, 15)
	replay:SetWidth(140)
	replay:SetHeight(25)
	replay:Show()
	replay:SetText("Replay from 0.00")
	
	--PAUSE BUTTON
	local pause = CreateFrame("BUTTON", "$parentPlayButton", f, "UIPanelButtonTemplate")
	pause:SetPoint("BOTTOMLEFT", 5, 70)
	pause:SetWidth(45)
	pause:SetHeight(25)
	pause:SetText("Pause")
	pause:Show()
	
	
	return o, f, mt, replay, pause
end

function AAV_Gui:setPlayerFrameSize(frame, bracket)
	frame:SetHeight(110 + (AAV_GUI_VERTICALFRAMEDISTANCE * tonumber(bracket)))
end

----
-- @return b statusbar HP
-- @return c frame icon
-- @return cr frame combattext range
-- @return br frame buff range
-- @return dr frame debuff range
function AAV_Gui:createEntityBar(parent, v, y)
	local anchor, offx, manauser
	
	if (v.team==1) then anchor = "TOPLEFT" else anchor = "TOPRIGHT" end
	if (v.team==1) then offx = 55 else offx = 325 end
	
	manauser = AAV_Util:determineManaUser(v.class)
	
	-- FRAME
	local a = CreateFrame("Frame", "$parentEntity" .. v.team .. y, parent)
	a:SetWidth(180)
	a:SetHeight(15)
	a:SetPoint("TOPLEFT", parent, offx, -70-(y * AAV_GUI_VERTICALFRAMEDISTANCE))
	a:Show()
	
	-- ICON
	local c = CreateFrame("Frame", "$parentClazz", a)
	--c:SetFrameStrata("MEDIUM")
	c:SetWidth(30)
	c:SetHeight(30)
	
	local t = c:CreateTexture(nil)
	
	if (not v.class or v.class == "Unknown") then
		t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark.blp")
	else
		t:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\" .. v.class .. ".tga")
	end
	t:SetAllPoints(c)
	c.texture = t
	c:SetPoint("TOPLEFT", a:GetName(), 0, 15)
	c:Show()

	
	
	-- HEALTH BAR
	local b = CreateFrame("STATUSBAR", "$parentAAVHealthBar", a)
	b:SetWidth(135)
	if (manauser) then b:SetHeight(AAV_GUI_HEALTHBARHEIGHT - AAV_GUI_MANABARHEIGHT) else b:SetHeight(AAV_GUI_HEALTHBARHEIGHT) end
	b:SetStatusBarTexture("Interface\\Addons\\AAVBlackrock\\res\\bartexture.tga")
	--b:SetStatusBarColor(AAV_Util:getTargetColor(v, false))
	b:SetMinMaxValues(0, UnitHealth("player"))
	b:SetPoint("TOPLEFT", a:GetName(), 30, 1)
	b:Show()
	
	local bback = b:CreateTexture(nil)
	bback:SetTexture(0.0, 0.0, 0.0)
	bback:SetAllPoints(b)
	b.texture = bback
	
	-- MANA BAR
	local m = CreateFrame("STATUSBAR", "$parentManaBar", a)
	m:SetWidth(135)
	m:SetHeight(AAV_GUI_MANABARHEIGHT)
	m:SetStatusBarTexture("Interface\\Addons\\AAVBlackrock\\res\\bartexture.tga")
	--m:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	m:SetMinMaxValues(0,100)
	
	if (manauser) then m:SetStatusBarColor(0.5333333333333333, 0.5333333333333333, 1) end
	
	m:SetMinMaxValues(0,100)
	m:SetPoint("BOTTOMLEFT", a:GetName(), "TOPLEFT", 30, -(AAV_GUI_HEALTHBARHEIGHT - 1))
	if (manauser) then m:Show() else m:Hide() end
	
	local mback = m:CreateTexture(nil)
	mback:SetTexture(0.0, 0.0, 0.0)
	mback:SetAllPoints(m)
	m.texture = mback
	
	
	-- COMBAT TEXT
	local cr = CreateFrame("Frame", "$parentCombatRange", parent)
	cr:SetFrameStrata("HIGH")
	cr:SetWidth(70)
	cr:SetHeight(50)
	if (v.team == 1) then cr:SetPoint("BOTTOMLEFT", b, "BOTTOMRIGHT", -5, 0) end
	if (v.team == 2) then cr:SetPoint("BOTTOMRIGHT", b, "BOTTOMLEFT", -10, 0) end
	cr:Show()
	
	-- PLAYER NAME
	local n = c:CreateFontString("$parentName", "ARTWORK", "GameFontNormal")
	n:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	n:SetText(v.name)
	n:SetPoint("CENTER", b, 0, 15)
	n:Show()
	
	-- SKILL
	local sr = CreateFrame("Frame", "$parentSkillRange", parent)
	sr:SetFrameStrata("HIGH")
	sr:SetWidth(a:GetWidth())
	sr:SetHeight(30)
	sr:SetPoint("BOTTOMLEFT", a, "TOPLEFT", 0, 15)
	sr:Show()
	
	
	return a, b, c, cr, n, sr, m
end

function AAV_Gui:createAuraRanges(parent)
	-- BUFF
	local br = CreateFrame("Frame", "$parentBuffRange", parent)
	br:SetFrameStrata("HIGH")
	br:SetWidth(parent:GetWidth())
	br:SetHeight(AAV_USEDSKILL_ICONBUFFSIZE)
	br:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -2)
	br:Show()
	
	-- DEBUFF
	local dr = CreateFrame("Frame", "$parentDebuffRange", parent)
	dr:SetFrameStrata("HIGH")
	dr:SetWidth(parent:GetWidth())
	dr:SetHeight(AAV_USEDSKILL_ICONBUFFSIZE)
	dr:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -(AAV_USEDSKILL_ICONBUFFSIZE+2))
	dr:Show()
	
	return br, dr
end

function AAV_Gui:createCooldown(parent)
	
	local f = CreateFrame("Frame", "$parentCooldown", parent)
	f:SetWidth(40)
	f:SetHeight(15)
	f:SetAlpha(1)
	f:Show()
	
	-- ICON
	local ic = CreateFrame("Frame", "$parentCooldownText", f)
	ic:SetWidth(AAV_CC_ICONSIZE)
	ic:SetHeight(AAV_CC_ICONSIZE)
	ic:SetPoint("LEFT", f, 0, 0)
	ic:Show()
	
	-- TEXT
	local n = ic:CreateFontString("$parentName", "ARTWORK", "GameFontNormal")
	n:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	n:SetText("?")
	n:SetPoint("LEFT", f, AAV_CC_ICONSIZE + 2, 0)
	n:Show()
	
	-- TEXTURE
	local t = ic:CreateTexture(nil)
	t:SetAllPoints(ic)
	--t:SetTexture(0.0, 0.0, 0.0)
	t:Show()
	ic.texture = t
	
	
	return f, ic, n
	
end

function AAV_Gui:createCooldownRanges(parent, team)
	local cb = CreateFrame("Frame", "$parentCDBar", parent)
	cb:SetFrameStrata("HIGH")
	cb:SetWidth(45)
	cb:SetHeight(100)
	if (team == 1) then cb:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", 0, -52 + AAV_CC_ICONSIZE) end
	if (team == 2) then cb:SetPoint("BOTTOMLEFT", parent, "TOPRIGHT", 0, -52 + AAV_CC_ICONSIZE) end
	cb:Show()
	
	return cb
end

function AAV_Gui:createBarHealthText(parent)
	local a = parent:CreateFontString("$parentHPText","ARTWORK","GameFontNormal")
	a:SetFont("Fonts\\FRIZQT__.TTF", 10)
	a:SetText("100%")
	a:SetPoint("CENTER", parent:GetName(), 0, 1)
	a:Show()
	
	return a
end

function AAV_Gui:createSeekerBar(parent, elapsed)
	
	local f = CreateFrame("Frame", "$parentSeekerBarBack", parent)
	--f:SetFrameStrata("LOW")
	f:SetWidth(435)
	f:SetHeight(12)
	
	local t = f:CreateTexture(nil)
	--t:SetTexture(0.0, 0.0, 0.0)
	t:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\Smooth.tga")
	t:SetVertexColor(0.4313, 0.4313, 0.4313)
	t:SetAllPoints(f)
	f.texture = t
	
	--c:SetAllPoints(parent)
	f:SetPoint("BOTTOMLEFT", parent:GetName(), 55, 75)
	f:Show()
	
	
	
	local a = CreateFrame("STATUSBAR", "$parentSeekerBar", f)
	--a:SetFrameStrata("MEDIUM")
	a:SetWidth(f:GetWidth())
	a:SetHeight(f:GetHeight())
	a:SetStatusBarTexture("Interface\\Addons\\AAVBlackrock\\res\\Smooth.tga")
	a:SetStatusBarColor(1, 1, 1)
	a:SetMinMaxValues(0, elapsed)
	a:SetValue(0)
	a:SetPoint("BOTTOMLEFT", parent, 55, 75)
	--a:SetPoint("TOPLEFT", speedframe, 0, 0)
	a:Show()
	
  
	
	local left = CreateFrame("FRAME", nil, a)
	left:SetHeight(12)
	left:SetWidth(12)
	left:SetPoint("BOTTOMLEFT", a, -5, 0)
	left:Show()
	
	local t = left:CreateTexture(nil)
	t:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\playerleft.tga")
	t:SetAllPoints(left)
	left.texture = t
	
	
	local speedval = parent:CreateFontString("$parentSpeedTitle", "ARTWORK", "GameFontNormal")
	speedval:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	speedval:SetJustifyH("LEFT")
	speedval:SetPoint("BOTTOMLEFT", parent, 15, 20)
	speedval:Show()
	
	local slider = CreateFrame("SLIDER", "$parentSpeed", parent, "OptionsSliderTemplate")
	slider:SetHeight(15)
	slider:SetWidth(100)
	slider:SetMinMaxValues(0, 300)
	slider:SetValue(100)
	slider:SetValueStep(10)
	getglobal(slider:GetName() .. 'Low'):SetText("");
	getglobal(slider:GetName() .. 'High'):SetText("");
	--getglobal(slider:GetName() .. 'Text'):SetText('Speed');
	slider:SetPoint("LEFT", speedval, "RIGHT", 5, -2)
	slider:Show()
	
	local speed = parent:CreateFontString("$parentSpeedValue", "ARTWORK", "GameFontNormal")
	speed:SetText("100%")
	speed:SetJustifyH("LEFT")
	speed:SetPoint("LEFT", slider, "RIGHT", 5, 0)
	speed:Show()
	
	--[[
	parent:SetScript("OnMouseWheel", function(arg)
		local min, max = slider:GetMinMaxValues()
		if (arg == 1 and slider:GetValue() < max) then slider:SetValue(slider:GetValueStep()) end
		if (arg == -1 and slider:GetValue() > min) then slider:SetValue(slider:GetValueStep()) end
	end)
	--]]
	
	return a, f, slider, speedval, speed
end

function AAV_Gui:createStatsFrame(parent)
	local stats = CreateFrame("Frame", "$parentStats", parent)
	stats:SetHeight(parent:GetHeight())
	stats:SetWidth(parent:GetWidth())
	stats:SetPoint("TOPLEFT", 0, -10)
	
	local ddone = stats:CreateFontString("$parentDamageDone", "ARTWORK", "GameFontNormal")
	ddone:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	ddone:SetJustifyH("CENTER")
	ddone:SetPoint("TOPLEFT", stats, 200, -20)
	ddone:SetText(L.DETAIL_DAMAGEDONE)
	--ddone:SetTextColor()
	ddone:Show()
	
	local hdmg = stats:CreateFontString("$parentDamageDone", "ARTWORK", "GameFontNormal")
	hdmg:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	hdmg:SetJustifyH("CENTER")
	hdmg:SetPoint("TOPLEFT", ddone, 70, 0)
	hdmg:SetText(L.DETAIL_HIGHDAMAGE)
	--hdmg:SetTextColor()
	hdmg:Show()
	
	local hdone = stats:CreateFontString("$parentDamageDone", "ARTWORK", "GameFontNormal")
	hdone:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	hdone:SetJustifyH("CENTER")
	hdone:SetPoint("TOPLEFT", hdmg, 70, 0)
	hdone:SetText(L.DETAIL_HEALDONE)
	--hdone:SetTextColor()
	hdone:Show()
	
	local rating = stats:CreateFontString("$parentDamageDone", "ARTWORK", "GameFontNormal")
	rating:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	rating:SetJustifyH("CENTER")
	rating:SetPoint("TOPLEFT", hdone, 70, -12)
	rating:SetText(L.DETAIL_RATING)
	--rating:SetTextColor()
	rating:Show()
	
	local mmr = stats:CreateFontString("$parentDamageDone", "ARTWORK", "GameFontNormal")
	mmr:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	mmr:SetJustifyH("CENTER")
	mmr:SetPoint("TOPLEFT", rating, 80, 0)
	mmr:SetText(L.DETAIL_MMR)
	--mmr:SetTextColor()
	mmr:Show()
	
	return stats
end

function AAV_Gui:createDetailTeam(parent, num, bracket)
	
	local team = parent:CreateFontString("$parentDamageDone", "ARTWORK", "GameFontNormal")
	team:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	team:SetJustifyH("LEFT")
	team:SetPoint("TOPLEFT", rating, 0, 0)
	--mmr:SetTextColor()
	team:Show()	
end



function AAV_Gui:createButtonDetail(parent)
	
	local detail = CreateFrame("BUTTON", "$parentViewDetail", parent, "UIPanelButtonTemplate")
	detail:SetPoint("BOTTOMRIGHT", -10, 15)
	detail:SetWidth(120)
	detail:SetHeight(25)
	detail:Show()
	
	return detail
end

function AAV_Gui:createTeamHead(parent)
	
	local head = parent:CreateFontString("$parentName", "ARTWORK", "GameFontNormal")
	head:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
	head:SetJustifyH("LEFT")
	head:SetTextColor(1, 1, 1)
	
	return head
end

function AAV_Gui:createDetailEntry(parent)

	local entry = CreateFrame("Frame", "$parentEntry", parent)
	entry:SetHeight(AAV_DETAIL_ENTRYHEIGHT)
	entry:SetWidth(AAV_DETAIL_ENTRYWIDTH)
	
	local icon = CreateFrame("Frame", "$parentIcon", entry)
	icon:SetWidth(20)
	icon:SetHeight(20)
	
	local t = icon:CreateTexture(nil)
	--t:SetTexture()
	t:SetAllPoints(icon)
	icon.texture = t
	icon:SetPoint("TOPLEFT", entry, 20, -5)
	icon:Show()
	
	local name = parent:CreateFontString("$parentName", "ARTWORK", "GameFontNormal")
	name:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	name:SetJustifyH("LEFT")
	name:SetParent(entry)
	name:SetPoint("BOTTOMLEFT", entry, 50, 0)
	name:SetTextColor(1, 1, 1)
	
	local dd = parent:CreateFontString("$parentDamage", "ARTWORK", "GameFontNormal")
	dd:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	dd:SetJustifyH("LEFT")
	dd:SetParent(entry)
	dd:SetPoint("BOTTOMLEFT", entry, 200, 0)
	dd:SetTextColor(1, 1, 1)
	
	local hd = parent:CreateFontString("$parentHighest", "ARTWORK", "GameFontNormal")
	hd:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	hd:SetJustifyH("LEFT")
	hd:SetParent(entry)
	hd:SetPoint("BOTTOMLEFT", dd, 70, 0)
	hd:SetTextColor(1, 1, 1)
	
	local h = parent:CreateFontString("$parentHeal", "ARTWORK", "GameFontNormal")
	h:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	h:SetJustifyH("LEFT")
	h:SetParent(entry)
	h:SetPoint("BOTTOMLEFT", hd, 70, 0)
	h:SetTextColor(1, 1, 1)
	
	local rc = parent:CreateFontString("$parentRating", "ARTWORK", "GameFontNormal")
	rc:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	rc:SetJustifyH("LEFT")
	rc:SetParent(entry)
	rc:SetPoint("BOTTOMLEFT", h, 70, 0)
	rc:SetTextColor(1, 1, 1)
	
	local mmr = parent:CreateFontString("$parentMMR", "ARTWORK", "GameFontNormal")
	mmr:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	mmr:SetJustifyH("LEFT")
	mmr:SetParent(entry)
	mmr:SetPoint("BOTTOMLEFT", rc, 80, 0)
	mmr:SetTextColor(1, 1, 1)

	return entry, icon, name, dd, hd, h, rc, mmr
end

function AAV_Gui:createStatusText(parent)
	local status = parent:CreateFontString("$parentStatus", "ARTWORK", "GameFontNormal")
	status:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	status:SetJustifyH("LEFT")
	status:SetPoint("BOTTOMLEFT", parent, 15, 20)
	status:Hide()
	
	return status
end

function AAV_Gui:createSeekerText(parent)
	local b = parent:CreateFontString("$parentTick", "ARTWORK", "GameFontNormal")
	b:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	b:SetText("00:00.0")
	b:SetJustifyH("LEFT")
	b:SetPoint("LEFT", parent:GetName(), parent:GetWidth() + 5, 0)
	b:Show()
	
	return b
end

----
-- Sets the GameTooltip with provided message
-- @param msg message string for the tooltip
-- @param color colorize the message
function AAV_Gui:SetGameTooltip(msg, color, parent)
	GameTooltip:SetOwner(parent, "ANCHOR_CURSOR", 200, 250)
	GameTooltip:SetText(msg)
	
end

----
-- @param parent
function AAV_Gui:createCombatText(parent)
	local f = parent:CreateFontString("$parentHPText","ARTWORK","GameFontNormal")
	f:Show()
	
	return f
end

----
-- @param parent
-- @param i for unique ussage in name
function AAV_Gui:createUsedSkill(parent, i)
	
	local f = CreateFrame("Frame", "$parentSkill" .. i, parent)
	f:SetWidth(AAV_USEDSKILL_ICONSIZE)
	f:SetHeight(AAV_USEDSKILL_ICONSIZE)
	f:SetAlpha(0)
	f:Show()
	
	-- texture
	local t = f:CreateTexture(nil)
	t:SetAllPoints(f)
	f.texture = t
	
	
	local b = CreateFrame("Frame", "$parentBox", parent)
	--b:SetAllPoints(f)
	b:SetWidth(AAV_USEDSKILL_ICONSIZE-1)
	b:SetHeight(AAV_USEDSKILL_ICONSIZE)
	b:Show()
	
	-- texture
	local tb = b:CreateTexture(nil)
	tb:SetAllPoints(b)
	b.texture = tb
	
	-- target color
	local tc = CreateFrame("Frame", "$parentColor", f)
	tc:SetPoint("TOP", f, 0, 5)
	tc:SetWidth(23)
	tc:SetHeight(5)
	-- texture
	local ttc = f:CreateTexture(nil)
	ttc:SetAllPoints(tc)
	tc.texture = ttc
	
	
	-- target
	local tar = CreateFrame("Frame", "$parentTarget", f)
	tar:SetPoint("TOP", f, 0, 6)
	tar:SetWidth(f:GetWidth())
	tar:SetHeight(12)
	tar:Hide()
	-- texture
	local tt = f:CreateTexture(nil)
	tt:SetAllPoints(tar)
	tt:SetTexCoord(0, 1, 0, 0.5);
	tt:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\TARGETBG.tga")
	tar.texture = tt
	--tar:SetFrameStrata("HIGH")
	
	
	
	
	return f, b, tar, tc
end

function AAV_Gui:createAura(parent, i)
	local f = CreateFrame("Frame", "$parentAura", parent)
	f:SetWidth(AAV_USEDSKILL_ICONBUFFSIZE)
	f:SetHeight(AAV_USEDSKILL_ICONBUFFSIZE)
	f:Show()
	
	-- texture
	local t = f:CreateTexture(nil)
	t:SetAllPoints(f)
	f.texture = t
	
	return f, n
	
end

----
-- puts an X on the parent bar to indicate, that it's been interrupted.
-- @param parent skillused object, where the X is being put on
-- @param x the frame with the texture
function AAV_Gui:setInterruptOnBar(parent, x)
	x:SetParent(parent)
	x:SetAllPoints(parent)
end

----
-- creates an interrupt frame to indicate, that a skill's been interrupted.
-- @param parent a skillused object
-- @return frame 
function AAV_Gui:createInterruptFrame(parent)	
	
	local f = CreateFrame("Frame", "$parentX", parent)
	f:SetFrameStrata("HIGH")
	f:SetWidth(AAV_USEDSKILL_ICONSIZE)
	f:SetHeight(AAV_USEDSKILL_ICONSIZE)
	f:SetAllPoints(parent)
	f:Show()
	
	local t = f:CreateTexture(nil, "HIGH")
	t:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\X.tga")
	f.texture = t
	t:SetAllPoints(f)
	t:Show()
	
	return f
end

function AAV_Gui:createMinimapIcon(parent, player)
	
	local button = CreateFrame("Button", nil, Minimap)
	button:SetFrameStrata("HIGH")
	button:SetWidth(31)
	button:SetHeight(31)
	button:RegisterForClicks("AnyUp")
	button:RegisterForDrag("RightButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	
	local x,y
	if (atroxArenaViewerData.defaults.profile.minimapx and atroxArenaViewerData.defaults.profile.minimapy) then
		x, y = atroxArenaViewerData.defaults.profile.minimapx, atroxArenaViewerData.defaults.profile.minimapy
	else
		x, y = -54.6, 58.8
	end
	button:SetPoint("CENTER", x, y)
	
	button:Show()

	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetWidth(53)
	overlay:SetHeight(53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")

	local icon = button:CreateTexture(nil, 'BACKGROUND')
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetTexture("Interface\\Icons\\Spell_Magic_MageArmor")
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	icon:SetPoint("TOPLEFT", 7, -5)

	local minimapShapes = {
		["ROUND"] = {true, true, true, true},
		["SQUARE"] = {false, false, false, false},
		["CORNER-TOPLEFT"] = {true, false, false, false},
		["CORNER-TOPRIGHT"] = {false, false, true, false},
		["CORNER-BOTTOMLEFT"] = {false, true, false, false},
		["CORNER-BOTTOMRIGHT"] = {false, false, false, true},
		["SIDE-LEFT"] = {true, true, false, false},
		["SIDE-RIGHT"] = {false, false, true, true},
		["SIDE-TOP"] = {true, false, true, false},
		["SIDE-BOTTOM"] = {false, true, false, true},
		["TRICORNER-TOPLEFT"] = {true, true, true, false},
		["TRICORNER-TOPRIGHT"] = {true, false, true, true},
		["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
		["TRICORNER-BOTTOMRIGHT"] = {false, true, true, true},
	}
	
	button:SetScript("OnDragStart", function(self, btn)
		self.dragging = true
		self:LockHighlight()
		icon:SetTexCoord(0, 1, 0, 1)
		self:SetScript('OnUpdate', function(self, btn)
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			px, py = px / scale, py / scale
			local deg = math.deg(math.atan2(py - my, px - mx)) % 360
			
			local angle = math.rad(deg)
			local x, y, q = math.cos(angle), math.sin(angle), 1
			if x < 0 then q = q + 1 end
			if y > 0 then q = q + 2 end
			local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
			local quadTable = minimapShapes[minimapShape]
			if quadTable[q] then
				x, y = x*80, y*80
			else
				local diagRadius = 103.13708498985 
				x = math.max(-80, math.min(x*diagRadius, 80))
				y = math.max(-80, math.min(y*diagRadius, 80))
			end
			self:SetPoint("CENTER", self:GetParent(), "CENTER", x, y)
			atroxArenaViewerData.defaults.profile.minimapx = x
			atroxArenaViewerData.defaults.profile.minimapy = y
		end)
		GameTooltip:Hide()
	end)
	
	button:SetScript("OnDragStop", function(self, btn)
		self.dragging = nil
		self:SetScript('OnUpdate', nil)
		icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
		self:UnlockHighlight()
	end)
	
	
	
	button:SetScript("OnEnter", function(self)
		if not self.dragging then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetText("atrox Arena Viewer")
			GameTooltip:AddLine("|cffe392c5Right-click|r to drag icon")
			GameTooltip:AddLine("|cffe392c5Left-click|r to open AAV")
			GameTooltip:Show()
		end
	end)
	
	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	local reset = function(tab) for k,v in pairs(tab) do tab[k] = nil end end
	
	-- MENU
	local menu = CreateFrame("Frame", "AAVMinimapMenu", UIParent, "UIDropDownMenuTemplate")
	local info = {}
	UIDropDownMenu_Initialize(menu, function(self, level)
		level = level or 1
		info.disabled	= false
		
		if (level == 1) then
			-- ENABLE RECORDING
			reset(info)
			info.text       = "Enable recording"
			info.notCheckable = false
			info.notClickable = false
			info.hasArrow	= false
			info.checked	= atroxArenaViewerData.current.record
			info.func       = function() parent:changeRecording() end
			
			UIDropDownMenu_AddButton(info, level)
			
			-- PLAY MATCH
			--[[info.text       = "Play match"
			info.notCheckable = true
			info.notClickable = false
			info.hasArrow	= true
			info.func		= nil
			
			UIDropDownMenu_AddButton(info, level)]]--	
						
			-- DELETE MATCH
			reset(info)
			info.text       = "Delete"
			info.notCheckable = true
			info.notClickable = false
			info.hasArrow	= true
			info.func		= nil
			
			UIDropDownMenu_AddButton(info, level)
			
			 --EXPORT MATCH
			reset(info)
			info.text       = "Export Match"
			info.notCheckable = true
			info.notClickable = false
			info.hasArrow	= true
			info.func       = nil
			
			UIDropDownMenu_AddButton(info, level)
			
			 --IMPORT MATCH
			reset(info)
			info.text       = "Import Match"
			info.notCheckable = true
			info.notClickable = false
			info.hasArrow	= false
			info.func       = function() StaticPopup_Show("AAV_IMPORT_DIALOG") end
			
			UIDropDownMenu_AddButton(info, level)
			
			-- OPTIONS
			reset(info)
			info.text       = "Options"
			info.notCheckable = true
			info.notClickable = false
			info.hasArrow	= false
			info.func       = function() InterfaceOptionsFrame_OpenToCategory("AAVBlackrock") end
			
			UIDropDownMenu_AddButton(info, level)
			
		end
		
		if (level == 2) then
			
	--[[		if (UIDROPDOWNMENU_MENU_VALUE == "Play match") then
				-- PLAY MATCH
				
				if (atroxArenaViewerData.data) then
					
					for i=1, math.ceil(#atroxArenaViewerData.data / 20) do
						reset(info)
						info.text = "Play Match " .. ((i-1) * 20)+1 .. "-" .. (i * 20)
						info.notCheckable = true
						info.notClickable = false
						info.hasArrow = true
						info.func = nil
						
						UIDropDownMenu_AddButton(info, level)
					end
					
				else
					reset(info)
					info.text = "none found"
					info.notCheckable = true
					info.notClickable = true
					info.hasArrow = false
					info.func = nil
					
					UIDropDownMenu_AddButton(info, level)
				end
				

				if (atroxArenaViewerData.data) then
					for k,v in pairs(atroxArenaViewerData.data) do
						info.text = k .. " - " .. v.map .. " (" .. v.startTime .. ")"
						info.notCheckable = true
						info.notClickable = false
						info.hasArrow = false
						info.func = function() parent:createPlayer(k) parent:playMatch(k) end
						
						UIDropDownMenu_AddButton(info, level)
					end
				else
					info.text = "none found"
					info.notCheckable = true
					info.notClickable = true
					info.hasArrow = false
					info.func = nil
					
					UIDropDownMenu_AddButton(info, level)
				end
				--]]
				
				
				if(UIDROPDOWNMENU_MENU_VALUE == "Delete") then
					--DELETE
					reset(info)
					info.text = "Delete All"
					info.notCheckable = true
					info.notClickable = false
					info.hasArrow = false
					info.func = function()
						while(#atroxArenaViewerData.data>0) do
							atroxArenaViewer:deleteMatch(#atroxArenaViewerData.data)					
						end
						AAV_TableGui:refreshMatchesFrame()
					end
					UIDropDownMenu_AddButton(info, level)
				
		--[[		elseif (UIDROPDOWNMENU_MENU_VALUE == "Options") then
					reset(info)
					info.text = "Buffs and Debuffs"
					info.notCheckable = true
					info.notClickable = true
					info.hasArrow = false
					info.func = nil
					info.r = 0.8901960784313725
					info.g = 0.5725490196078431
					info.b = 0.7725490196078431
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text = "Don't Exceed Buffs and Debuffs"
					info.notCheckable = false
					info.notClickable = false
					info.hasArrow = false
					info.checked = atroxArenaViewerData.defaults.profile.shortauras
					info.func = function() atroxArenaViewerData.defaults.profile.shortauras = not atroxArenaViewerData.defaults.profile.shortauras end
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.notCheckable = true
					info.notClickable = true
					info.text = ""
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text = "Health Bar Text"
					info.notCheckable = true
					info.notClickable = true
					info.hasArrow = false
					info.func = nil
					info.r = 0.8901960784313725
					info.g = 0.5725490196078431
					info.b = 0.7725490196078431
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text = "Percentage Health Value (100%)"
					info.notCheckable = false
					info.notClickable = false
					info.hasArrow = false
					info.checked = atroxArenaViewerData.defaults.profile.healthdisplay == 1
					info.func = function() 
						atroxArenaViewerData.defaults.profile.healthdisplay = 1 
						if (atroxArenaViewer:getPlayer()) then atroxArenaViewer:getPlayer():updateHealthtext() end 
					end
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text = "Absolute Health Value (20000)"
					info.notCheckable = false
					info.notClickable = false
					info.hasArrow = false
					info.checked = atroxArenaViewerData.defaults.profile.healthdisplay == 2
					info.func = function() 
						atroxArenaViewerData.defaults.profile.healthdisplay = 2 
						if (atroxArenaViewer:getPlayer()) then atroxArenaViewer:getPlayer():updateHealthtext() end 
					end
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text = "Deficit Health Value (-530/20000)"
					info.notCheckable = false
					info.notClickable = false
					info.hasArrow = false
					info.checked = atroxArenaViewerData.defaults.profile.healthdisplay == 3
					info.func = function() 
						atroxArenaViewerData.defaults.profile.healthdisplay = 3 
						if (atroxArenaViewer:getPlayer()) then atroxArenaViewer:getPlayer():updateHealthtext() end 
					end
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.notCheckable = true
					info.notClickable = true
					info.text = ""
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text = "Cheat Detector"
					info.notCheckable = true
					info.notClickable = true
					info.hasArrow = false
					info.func = nil
					info.r = 0.8901960784313725
					info.g = 0.5725490196078431
					info.b = 0.7725490196078431
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text       = "Announce Cheaters in /say"
					info.notCheckable = false
					info.notClickable = false
					info.hasArrow	= false
					info.checked = atroxArenaViewerData.defaults.profile.announceCheaters
					info.func = function() atroxArenaViewerData.defaults.profile.announceCheaters = not atroxArenaViewerData.defaults.profile.announceCheaters end
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.notCheckable = true
					info.notClickable = true
					info.text = ""
					
					UIDropDownMenu_AddButton(info, level)
					
					reset(info)
					info.text       = "Slider Options"
					info.notCheckable = true
					info.notClickable = false
					info.hasArrow	= true
					info.func = function() InterfaceOptionsFrame_OpenToCategory("AAVBlackrock") end
					
					UIDropDownMenu_AddButton(info, level) ]]--

			elseif (UIDROPDOWNMENU_MENU_VALUE == "Export Match") then	
			
				if (atroxArenaViewerData.data) then
				
					for i=1, math.ceil(#atroxArenaViewerData.data / 20) do
						reset(info)
						info.text = "Export Match " .. ((i-1) * 20)+1 .. "-" .. (i * 20)
						info.notCheckable = true
						info.notClickable = false
						info.hasArrow = true
						info.func = nil
						
						UIDropDownMenu_AddButton(info, level)
					end
					
				else
					reset(info)
					info.text = "none found"
					info.notCheckable = true
					info.notClickable = true
					info.hasArrow = false
					info.func = nil
					
					UIDropDownMenu_AddButton(info, level)
				end
				
				--[[
				if (atroxArenaViewerData.data) then
					for k,v in pairs(atroxArenaViewerData.data) do
						reset(info)
						info.text = k .. " - " .. v.map .. " (" .. v.startTime .. ")"
						info.notCheckable = true
						info.notClickable = false
						info.hasArrow = false
						info.func = function() parent:exportMatch(k) StaticPopup_Show("AAV_EXPORT_DIALOG") end
						
						UIDropDownMenu_AddButton(info, level)
					end
				else
					reset(info)
					info.text = "none found"
					info.notCheckable = true
					info.notClickable = true
					info.hasArrow = false
					info.func = nil
					
					UIDropDownMenu_AddButton(info, level)
				end
				--]]
			end
		end
		
		if (level == 3) then
			
			for i=1, math.ceil(#atroxArenaViewerData.data / 20) do
				
				if (UIDROPDOWNMENU_MENU_VALUE == "Export Match " .. ((i-1) * 20)+1 .. "-" .. (i * 20)) then
					
					if (atroxArenaViewerData.data) then
						for j=((i-1)*20)+1, (i*20) do
							if (not atroxArenaViewerData.data[j]) then break end
							reset(info);
							info.text = j .. " - " .. atroxArenaViewerData.data[j]["map"] .. " (" .. atroxArenaViewerData.data[j]["startTime"] .. ")"
							info.notCheckable = true
							info.notClickable = false
							info.hasArrow = false
							info.func = function() parent:exportMatch(j) StaticPopup_Show("AAV_EXPORT_DIALOG") end
							
							UIDropDownMenu_AddButton(info, level)
						end
					else
						reset(info)
						info.text = "none found"
						info.notCheckable = true
						info.notClickable = true
						info.hasArrow = false
						info.func = nil
						
						UIDropDownMenu_AddButton(info, level)
					end
					
				end
			end
			
			
		end
		
	end, "MENU")
	
    --ToggleDropDownMenu(1, nil, TomTomPingMenu, "cursor", 0, 0);
	
	button:SetScript("OnClick", function(button, clickType)
		if(clickType == "LeftButton") then
			if(AAV_TableGui:isMatchesFrameShowing()) then
				AAV_TableGui:hideMatchesFrame()
			else
				AAV_TableGui:showMatchesFrame()
				if (currentPlayerFrame and currentPlayerFrame:IsShown()) then
					currentPlayerObject:hidePlayer(currentPlayerFrame) -- Fix this later (TODO)
					currentPlayerObject:hideMovingObjects() -- Fix this later (TODO)
					currentPlayerObject:setOnUpdate("stop") -- Fix this later (TODO)
					isThereObject = false
				end
			end
		elseif (clickType == "RightButton") then
			ToggleDropDownMenu(1, nil, menu, button, 10, 10);
		end
	end)
	
	return button
end


function AAV_Gui:createCC(parent, id)
	
	-- FRAME
	local f = CreateFrame("FRAME", "$parentCC" .. id, parent)
	f:SetSize(30, 30)
	
	-- TEXTURE
	local t = f:CreateTexture(nil)
	f.texture = t
	t:SetAllPoints(f)
	t:Show()
	
	-- TIMER
	local n = f:CreateFontString("$parentName", "ARTWORK", "GameFontNormal")
	n:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	n:SetJustifyH("LEFT")
	n:SetPoint("BOTTOMLEFT", f, 3, 0)
	n:Show()
	
	return f, n
	
end
function AAV_Gui:createSliderCD(parent, timestamp, spellID, TeamID, elapsed, source)
	local percent = 1
	local name, rank, icon = GetSpellInfo(spellID)
	
	if(elapsed > 0) then
		 percent= timestamp/elapsed
	end
	
  -- ARROWFRAME
	local arrowframe = CreateFrame("Frame", "$parentCD"..spellID, parent)
	arrowframe:SetWidth(10)
	arrowframe:SetHeight(10)
	arrowframe:SetFrameStrata("HIGH")
	
	local actualpoint= math.floor(percent*parent:GetWidth())
	
	-- ARROWTEXTURE
	local arrowtex = arrowframe:CreateTexture(nil)
	arrowtex:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\arrowDOT.tga")
	arrowtex:SetAllPoints(arrowframe)
	arrowframe.texture = arrowtex
	arrowframe:Show()
	
	--ICON FRAME
	local iconframe = CreateFrame("Frame", "$parenticon", arrowframe)
	iconframe:SetWidth(16)
	iconframe:SetHeight(16)
	iconframe:SetFrameStrata("HIGH")
	iconframe:EnableMouse(true)
	iconframe:SetScript("OnEnter", function() 
		iconframe:SetScript("OnUpdate", function()
			AAV_Gui:SetGameTooltip(source , 0, iconframe)
		end)
	end)
	iconframe:SetScript("OnLeave", function() 
		GameTooltip:FadeOut()
		iconframe:SetScript("OnUpdate", nil)
	end)
	
	--ICON TEXTURE
	local icontex = iconframe:CreateTexture(nil)
	icontex:SetTexture(icon)
	icontex:SetAllPoints(iconframe)
	iconframe.texture = icontex
	iconframe:Show()	

	if(TeamID==0) then
		arrowframe:SetPoint("BOTTOMLEFT", parent, actualpoint, -8)
		iconframe:SetPoint("BOTTOMLEFT", parent, actualpoint-3, -25)
	else
		arrowframe:SetPoint("BOTTOMLEFT", parent, actualpoint, 12)
		iconframe:SetPoint("BOTTOMLEFT", parent, actualpoint-3, 20)
	end
	
	
	return arrowframe, arrrowtex
end
function AAV_Gui:createHackEntry(parent)
	local cheattext = parent:CreateFontString("$parentcheattext", "ARTWORK", "GameFontNormal")
	cheattext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	cheattext:SetJustifyH("LEFT")
	cheattext:SetParent(parent)
	cheattext:SetTextColor(1, 1, 1)
	cheattext:Show()
	return cheattext
end
function AAV_Gui:createHackFrame(parent, hackInfo)
	
	--HACKFRAME
	local hackframe = CreateFrame("ScrollFrame", "hackframe", parent)
	hackframe:SetWidth(200)
	hackframe:SetHeight(300)
	hackframe:SetPoint("RIGHT", 2 + hackframe:GetWidth(), 0)
	hackframe:EnableMouseWheel(true)
	hackframe:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
	  tile=1, tileSize=10, edgeSize=10, 
	  insets={left=3, right=3, top=3, bottom=3}
	})
	hackframe:Hide()
--	hackframe:SetMovable(true)
--	hackframe:EnableMouse(true)
--	hackframe:SetScript("OnMouseDown", hackframe.StartMoving)
--	hackframe:SetScript("OnMouseUp", hackframe.StopMovingOrSizing)
--	hackframe:Show()
	
	-- FRAME TITLE FRAME
	local frametitle = CreateFrame("Frame", "$parentTitle", hackframe)
	frametitle:SetHeight(30)
	frametitle:SetPoint("TOP", 0, 18)
	frametitle:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
	  tile=1, tileSize=10, edgeSize=20, 
	  insets={left=3, right=3, top=3, bottom=3}, 
	})
	frametitle:SetBackdropColor(0, 0, 0, 1)
	--FRAME TITLE TEXT
	local frametitletext = frametitle:CreateFontString("$parentTitletext", "ARTWORK", "GameFontNormal")
	frametitletext:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	frametitletext:SetText("Detected Cheats")
	frametitletext:SetPoint("CENTER", frametitle, 0, 0)
	frametitle:SetWidth(120)
	frametitletext:Show()
	
	--scrollbar 
	scrollbar = CreateFrame("Slider", nil, hackframe, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPLEFT", hackframe, "TOPRIGHT", 4, -16) 
	scrollbar:SetPoint("BOTTOMLEFT", hackframe, "BOTTOMRIGHT", 4, 16) 
	scrollbar:SetMinMaxValues(1, 200) 
	scrollbar:SetValueStep(1) 
	scrollbar.scrollStep = 1 
	scrollbar:SetValue(0) 
	scrollbar:SetWidth(16) 
	scrollbar:SetScript("OnValueChanged", 
	function (self, value) 
	self:GetParent():SetVerticalScroll(value) 
	end) 
	local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetAllPoints(scrollbar)
	scrollbg:SetTexture(0, 0, 0, 0.4)
	hackframe.scrollbar = scrollbar
	
	--content frame 
	local content = CreateFrame("Frame", nil, hackframe)
	content:SetSize(hackframe:GetWidth(),0)
	content:SetAllPoints()
	hackframe:SetScrollChild(content)
	hackframe.content = content 
	
	return hackframe, frametitletext
	
end
