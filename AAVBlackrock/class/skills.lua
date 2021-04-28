AAV_UsedSkill = {}
AAV_UsedSkill.__index = AAV_UsedSkill

function AAV_UsedSkill:new(parent, spellid, cast, num, v)
	
	local self = {}
	setmetatable(self, AAV_UsedSkill)
	
	self.frame, self.bar, self.target, self.tcolor = AAV_Gui:createUsedSkill(parent, num)
	self.num = num
	--self.interrupt = false
	self:setValue(parent, spellid, cast, num, v)
	--self.interrupt = nil
	--self.frame:Show()
	
	
	return self
	
end

function AAV_UsedSkill:isDead()
	return (self.alive > (AAV_USEDSKILL_PERSISTENCE))
end

function AAV_UsedSkill:setValue(parent, spellid, cast, num, v)
	local name, rank, icon, cost, isfunnel, ptype, casttime = GetSpellInfo(spellid)
	
	self.spellid = spellid
	self.cast = cast
	self.casttime = casttime/1000
	self.currentorder = 0
	self.order = 0
	self.timer = 0
	self.alive = 0
	self.parent = parent
	_, _, _, self.posX, self.posY = self.parent:GetPoint(1)
	
	if (self.interrupt and self.interrupt:GetParent() == self.frame) then 
		self.interrupt:Hide()
	end
	
	self.frame:SetPoint("LEFT", self.parent, "BOTTOMLEFT", self.posX, self.posY)
	self.frame.texture:SetTexture(icon)
	
	self.bar:SetHeight(AAV_USEDSKILL_ICONSIZE)
	self.bar.texture:SetTexture(0, 0, 0, 0.65)
	self.bar:SetAlpha(1)
	self:setPointForBar()
	
	self.frame:EnableMouse(true)
	self.frame:SetScript("OnEnter", function(s) 
		if (s:GetAlpha() > 0) then
			GameTooltip:SetOwner(s, "ANCHOR_CURSOR", 0, 0)
			if (rank ~= "") then
				AAV_Gui:SetGameTooltip(name .. " (" .. rank .. ")", nil, s)
			else
				AAV_Gui:SetGameTooltip(name, nil, s)
			end
		end
	end)
	self.frame:SetScript("OnLeave", function(s) 
		GameTooltip:FadeOut()
	end)

	self.frame:Show()
	
	if (v) then
		self.tcolor:Show()
		self.target:Show()
		self.tcolor.texture:SetTexture(AAV_Util:getTargetColor(v, false))
	else
		self.tcolor:Hide()
		self.target:Hide()
	end
	
	if (cast) then self.bar:Show() else self.bar:Hide() end
end

function AAV_UsedSkill:slideRight()
	self.order = self.order + 1
	self.cast = false
	self.bar:SetAlpha(0)
end

----
-- checks if the skill is currently casting.
-- @param cast
function AAV_UsedSkill:isCasting()
	return self.cast
end

----
-- @param elapsed time in miliseconds
-- @param rate current frame rate
function AAV_UsedSkill:moveSkill(elapsed, rate)
	self.timer = self.timer + elapsed
	
	if (self.timer > (1 / AAV_UPDATESPEED)) then
		local _, _, _, parentleft, _ = self.parent:GetPoint(1)
		
		if (self.order ~= self.currentorder) then
			if ((self.posX + (self.timer*AAV_USEDSKILL_ICONSPEED)) > (parentleft + (self.order * (AAV_USEDSKILL_ICONSIZE + AAV_USEDSKILL_ICONMARGIN)))) then
				self.posX = parentleft + (self.order * (AAV_USEDSKILL_ICONSIZE + AAV_USEDSKILL_ICONMARGIN))
				self.currentorder = self.order
			else
				self.posX = self.posX + (self.timer*AAV_USEDSKILL_ICONSPEED)
			end
			
			self.frame:SetPoint("LEFT", self.parent, "BOTTOMLEFT", self.posX+1, self.posY)
			
		end
		
		-- CAST
		if (self.cast == true) then
			if (self.bar:GetHeight() > 0 and self.bar:GetHeight() - ((self.timer*AAV_USEDSKILL_ICONSIZE)/self.casttime) < 0) then
				self.bar:SetHeight(0)
			else
				self.bar:SetHeight(self.bar:GetHeight() - ((self.timer*AAV_USEDSKILL_ICONSIZE)/self.casttime))
			end
			self:setPointForBar()
		end
		
		-- FADE OUT
		if (self.alive > (AAV_USEDSKILL_PERSISTENCE - AAV_USEDSKILL_FADEOUTTIME)) then
			if (self.frame:GetAlpha() - (self.timer*AAV_USEDSKILL_FADEOUTSPEED) < 0) then
				self.frame:SetAlpha(0)
				self.frame:EnableMouse(false)
			else
				self.frame:SetAlpha(self.frame:GetAlpha() - (self.timer*AAV_USEDSKILL_FADEOUTSPEED))
			end
		end
		
		-- FADE IN
		if (self.frame:GetAlpha() < 1 and self.alive < AAV_USEDSKILL_FADEINTIME) then
			if (self.frame:GetAlpha() + (self.timer*AAV_USEDSKILL_FADEINSPEED) > 1) then
				self.frame:SetAlpha(1)
			else
				self.frame:SetAlpha(self.frame:GetAlpha() + self.timer*AAV_USEDSKILL_FADEINSPEED)
			end
		end
		
		self.alive = self.alive + self.timer
		self.timer = 0
	end

end

----
-- sets the bar to the frame.
function AAV_UsedSkill:setPointForBar()
	self.bar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.posX+1, self.posY-16)
end

----
-- hides all attached frames.
function AAV_UsedSkill:hide()
	self.frame:EnableMouse(false)
	self.frame:Hide()
	self.bar:Hide()
	self.tcolor:Hide()
	self.target:Hide()
end