AAV_PlayerEntity = {}
AAV_PlayerEntity.__index = AAV_PlayerEntity

function AAV_PlayerEntity:new(parent, v, y, maxhp)
	
	local self = {}
	setmetatable(self, AAV_PlayerEntity)
	
	self.data = v
	self.parent = parent
	self.playerid = v.ID
	self.frame, self.bar, self.icon, self.crange, self.name, self.srange, self.mana = AAV_Gui:createEntityBar(parent, v, y, maxhp)
	self.text = AAV_Gui:createBarHealthText(self.bar)
	self.brange, self.drange = AAV_Gui:createAuraRanges(self.frame) -- objects
	self.cdrange = AAV_Gui:createCooldownRanges(self.frame, v.team) -- cooldown range
	self.team = team
	self.skills = {}
	self.buffs = {}
	self.debuffs = {}
	self.cooldowns = {}
	
	return self
end

----
-- hides all elements.
function AAV_PlayerEntity:hide()
	self.bar:Hide()
	self.icon:Hide()
	self.text:Hide()
	self.crange:Hide()
	self.srange:Hide()
	self.brange:Hide()
	self.drange:Hide()
	self.cdrange:Hide()
	self.mana:Hide()
end

----
-- shows all elements.
function AAV_PlayerEntity:show()
	self.bar:Show()
	self.icon:Show()
	self.text:Show()
	self.crange:Show()
	self.srange:Show()
	self.brange:Show()
	self.drange:Show()
	self.cdrange:Show()
	--self.mana:Show()
end

----
-- sets the opacity of all elements due to stealth or other events.
-- @param val opacity value
function AAV_PlayerEntity:setOpacity(val)
	self.bar:SetAlpha(val)
	self.icon:SetAlpha(val)
	self.mana:SetAlpha(val)
	--[[
	self.text:SetAlpha(val)
	self.crange:SetAlpha(val)
	self.srange:SetAlpha(val)
	self.brange:SetAlpha(val)
	self.drange:SetAlpha(val)
	--]]
end

----
-- reuses an existing PlayerEntity object and alters its information.
-- @param class player class
-- @param name player name
function AAV_PlayerEntity:setValue(class, name, maxhp, v)
	self.data = v
	self.icon.texture:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\" .. class .. ".tga")
	self.name:SetText(name)
	self.bar:SetMinMaxValues(0, maxhp)
	self.text:SetText("100%") -- ugly hack [#37]
	if (maxhp) then self.bar:SetValue(maxhp) end
	if (AAV_Util:determineManaUser(class)) then
		self.mana:Show()
		self.bar:SetHeight(AAV_GUI_HEALTHBARHEIGHT - AAV_GUI_MANABARHEIGHT)
		self.mana:SetValue(100)
		self.mana:SetStatusBarColor(0.5333333333333333, 0.5333333333333333, 1)
	else
		self.mana:Hide()
		self.bar:SetHeight(AAV_GUI_HEALTHBARHEIGHT)
	end
	
end

function AAV_PlayerEntity:setHealthBarText()
	
	local txt = "???"
	local min, max = self.bar:GetMinMaxValues()
	local value = self.bar:GetValue()
	
	-- check for percentage or aboslute values
	if (value == 0) then
		txt = "Dead"
	else
		if (atroxArenaViewerData.defaults.profile.healthdisplay == 1) then
			local a = (value/max)*100*10
			local i = string.find(a,"[\.]",1)
			if (i) then a = tonumber(string.sub(a,1, string.find(a,"[\.]",1)-1)) end
			txt = (a / 10) .. "%"
		elseif (atroxArenaViewerData.defaults.profile.healthdisplay == 2) then
			txt = value .. " / " .. max
		elseif (atroxArenaViewerData.defaults.profile.healthdisplay == 3) then
			txt = (value - max) .. " / " .. max
		end
	
		
	end
	
	self.text:SetText(txt)
end

function AAV_PlayerEntity:transferAuras(obj)
	
	for k,v in pairs(obj.buffs) do
		table.insert(v, self.buffs)
	end
	for k,v in pairs(obj.debuffs) do
		table.insert(v, self.debuffs)
	end
	
end

function AAV_PlayerEntity:arrangeCooldowns()
	--table.sort(target, function(a,b) return a.position < b.position end)
	table.sort(self.cooldowns, function(a,b) 
		return (a.duration - a.alive) < (b.duration - b.alive)
		--return (((a.duration - a.alive) == (b.duration - b.alive)) and (a.entry < b.entry)) or (a.duration - a.alive) < (b.duration - b.alive)
	end)

	local i = 0
	for k,v in pairs(self.cooldowns) do
		v.position = i
		i = i + 1
	end
end

function AAV_PlayerEntity:addCooldown(obj)
	table.insert(self.cooldowns, obj)
end

function AAV_PlayerEntity:removeAllCooldowns()
	for k,v in pairs(self.cooldowns) do
		self.cooldowns[k] = nil
	end
end

function AAV_PlayerEntity:removeCooldown(obj)
	local index = 1
	for k,v in pairs(self.cooldowns) do
		if (v == obj) then
			table.remove(self.cooldowns, index)
			break
		end
		index = index + 1
	end
end

----
-- @param spellid
-- @param type buff = 1, debuff = 2
function AAV_PlayerEntity:addAura(spellid, type, duration)
	local aura, target, range, n
	
	if (type == 1) then target = self.buffs range = self.brange end
	if (type == 2) then target = self.debuffs range = self.drange end
	
	aura = AAV_Aura:new(range, spellid, type, #target, duration)
	self:setAura(aura, spellid, type)
	
	if (atroxArenaViewerData.defaults.profile.shortauras and #target > AAV_MAX_AURASVISIBLE) then
		for k,v in pairs(target) do
			self:removeAura(v.spellid, type)
			break
		end
		
	end
	
	return aura
end

--[[
----
-- if the buffs and debuffs are to be shortened, buffs won't be visible that are lasting the longest.
-- @param type buff = 1, debuff = 2
function AAV_PlayerEntity:sortAuras(type)
	local target
	local i, def
	if (type == 1) then target = self.buffs end
	if (type == 2) then target = self.debuffs end
	def = #target
	
	for k,v in pairs(target) do
		if (v.duration > AAV_AURA_LONGLASTING) then
			v:Hide()
			i = i + 1
		else
			v:Show()
		end
		if
	end
	
end
--]]

----
-- hides all buffs and debuffs and hides existing ones
function AAV_PlayerEntity:hideAllAura()
	for k,v in pairs(self.buffs) do
		v.frame:Hide()
	end
	self.buffs = {}
	
	for k,v in pairs(self.debuffs) do
		v.frame:Hide()
	end
	self.debuffs = {}
end

----
-- removes a buff or debuff from the player.
-- @param spellid
-- @param type buff = 1, debuff = 2
function AAV_PlayerEntity:removeAura(spellid, type)
	local delete = nil
	local target, x, dx
	
	if (type == 1) then target = self.buffs end
	if (type == 2) then target = self.debuffs end
	
	for k,v in pairs(target) do
		if (v.spellid == spellid) then
			delete = v
			v.frame:Hide()
			table.remove(target, k)
			break
		end
	end
	self:adjustPosition(target)
end

----
-- removes all auras depending on omitted value.
function AAV_PlayerEntity:removeAllAuras()
	
	for i=1,#self.buffs do
		self:removeAura(self.buffs[1].spellid, 1)
	end
	for i=1,#self.debuffs do
		self:removeAura(self.debuffs[1].spellid, 2)
	end
	
end

----
-- returns the size of all visible objects (0 = 0%, 1 = 100%).
-- @param val buffs = 1, debuffs = 2
function AAV_PlayerEntity:getVisibleNum(val)
	local num = 0
	if (val == 1) then
		for k,v in pairs(self.buffs) do
			if (v.frame:IsShown()) then
				num = num + 1
			end
		end
	elseif (val == 2) then
		for k,v in pairs(self.debuffs) do
			if (v.frame:IsShown()) then
				num = num + 1
			end
		end
	end
	return num
end

----
-- adjusts the position of all auras.
-- @param target buff, debuff
function AAV_PlayerEntity:adjustPosition(target)
	local n = 0
	
	table.sort(target, function(a,b) return a.position < b.position end)
	
	for k,v in pairs(target) do
		v.position = n
		n = n + 1
		v.frame:SetPoint("TOPLEFT", v.parent, "TOPLEFT", (v.position * AAV_USEDSKILL_ICONBUFFSIZE), 0)
	end
	
end

----
-- sets properties onto an aura object
-- @param aura object
-- @param spellid
-- @param type buff = 1, debuff = 2
function AAV_PlayerEntity:setAura(aura, spellid, type)
	local name, rank, icon, _, _, _, _ = GetSpellInfo(spellid)
	local target, parent
	
	if (type == 1) then target = self.buffs parent = self.brange end
	if (type == 2) then target = self.debuffs parent = self.drange end
	
	self:adjustPosition(target)
	
	aura.type = type
	aura.spellid = spellid
	aura.frame:SetParent(parent)
	aura.frame.texture:SetTexture(icon)
	--aura.position = self:getVisibleNum(type)
	
	
	if (type == 1) then 
		aura.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", (aura.position * AAV_USEDSKILL_ICONBUFFSIZE), 0)
	end
	if (type == 2) then 
		aura.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", (aura.position * AAV_USEDSKILL_ICONBUFFSIZE), 0)
	end
	
	aura.frame:Show()
	
	table.insert(target, aura)
	if (#target > AAV_MAX_AURASVISIBLE and atroxArenaViewerData.defaults.profile.shortauras) then
		for k,v in pairs(target) do
			
		end
	end
	
	-- setting tooltip
	aura.frame:EnableMouse(true)
	aura.frame:SetScript("OnEnter", function(s) 
		if (s:GetAlpha() > 0) then
			GameTooltip:SetOwner(s, "ANCHOR_CURSOR", 0, 0)
			if (rank ~= "") then
				AAV_Gui:SetGameTooltip(name .. " (" .. rank .. ")", nil, s)
			else
				AAV_Gui:SetGameTooltip(name, nil, s)
			end
		end
	end)
	
	aura.frame:SetScript("OnLeave", function(s) 
		GameTooltip:FadeOut()
	end)
	
end