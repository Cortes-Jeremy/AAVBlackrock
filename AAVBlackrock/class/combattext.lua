AAV_CombatText = {}
AAV_CombatText.__index = AAV_CombatText

function AAV_CombatText:new(parent, team, type, amount, crit)
	local self = {}
	setmetatable(self, AAV_CombatText)
	
	self.text = AAV_Gui:createCombatText(parent)
	self.team = team
	
	self:setValue(parent, type, amount, crit)
	
	return self
end

----
-- sets the text of the combat text. sets the object alive, too.
-- @param type damage = 1, heal = 2
-- @param crit whether crit
-- @param value
function AAV_CombatText:setValue(p, type, amount, crit)
	local pre
	
	self.parent = p
	_, _, _, self.posX, self.posY = p:GetPoint(1)

	self.timer = 0
	self.alive = 0
	self.crit = crit
	
	self.text:SetPoint("CENTER", self.parent, "BOTTOM", self.posX, self.posY)
	
	if (type == 1) then self.text:SetTextColor(255/219, 0, 0) pre = "-" end
	if (type == 2) then self.text:SetTextColor(15/219, 255/207, 0) pre = "+" end
	
	if (crit == 0) then self.text:SetTextHeight(AAV_COMBATTEXT_SCROLLINGTEXTFONTSIZE) end
	if (crit == 1) then self.text:SetTextHeight(AAV_COMBATTEXT_SCROLLINGTEXTCRITPLUS) end
	
	
	self.text:SetText(pre .. amount)
end

function AAV_CombatText:moveText(elapsed, rate)
	self.timer = self.timer + elapsed
	
	if (self.timer > (1 / AAV_UPDATESPEED)) then
		
		self.posY = self.posY + (AAV_COMBATTEXT_FRAMESPEED*self.timer)
		self.text:SetPoint("CENTER", self.parent, "BOTTOM", self.posX, self.posY)
		
		if (self.alive > (AAV_COMBATTEXT_PERSISTENCE - AAV_COMBATTEXT_FADETIME)) then
			if (self.text:GetAlpha() - (AAV_COMBATTEXT_ALPHASPEED*self.timer) < 0) then
				self.text:SetAlpha(0)
			else 
				self.text:SetAlpha(self.text:GetAlpha() - (AAV_COMBATTEXT_ALPHASPEED*self.timer))
			end
		end
		
		if (self.text:GetStringHeight() > AAV_COMBATTEXT_SCROLLINGTEXTFONTSIZE) then
			local size = self.text:GetStringHeight() - (AAV_COMBATTEXT_CRITSPEED*self.timer)
			if (size < AAV_COMBATTEXT_SCROLLINGTEXTFONTSIZE) then size = AAV_COMBATTEXT_SCROLLINGTEXTFONTSIZE end
			self.text:SetTextHeight(size)
		end
		
		self.alive = self.alive + self.timer
		self.timer = 0
	end
	
end

function AAV_CombatText:isDead()
	return (self.alive > AAV_COMBATTEXT_PERSISTENCE + AAV_COMBATTEXT_FADETIME)
end

function AAV_CombatText:hide()
	self.text:SetAlpha(0)
end