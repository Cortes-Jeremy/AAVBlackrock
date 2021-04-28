AAV_Crowd = {}
AAV_Crowd.__index = AAV_Crowd

function AAV_Crowd:new(parent, id, visible)
	
	local self = {}
	setmetatable(self, AAV_Crowd)
	
	self.frame, self.text = AAV_Gui:createCC(parent, id)
	self.id = id
	self.icon = ""
	self.parent = ""
	self.starttime = 0
	self.ttl = 0 -- time to live
	self.timer = 0
	self.alive = 0
	self.spellid = 0
	
	
	return self
end

function AAV_Crowd:setValue(spellid, id, icon, parent, time, lvl)
	self.spellid = spellid
	self.id = id
	self.icon = icon
	self.parent = parent
	self.starttime = time
	self.ttl = time
	self.alive = 0
	self.timer = 0
	
	self.frame:SetParent(self.parent)
	self.frame:SetPoint("TOPLEFT", self.parent, 0, 0)
	self.frame:SetAlpha(0)
	
	self.frame.texture:SetTexture(self.icon)
	
	--self.frame:SetFrameLevel(lvl)
	self.frame.texture:Show()
	
	self.frame:Show()
	self.text:SetText(time)
	
end

function AAV_Crowd:isDead()
	return (self.ttl == 0)
end

function AAV_Crowd:setDead()
	self.ttl = 0
	self.frame:SetAlpha(0)
	self.frame:Hide()
end

function AAV_Crowd:update(elapsed, rate, visible)
	self.timer = self.timer + elapsed
	
	if (self.timer > (1 / AAV_UPDATESPEED)) then
		local txt = math.floor((self.ttl-self.alive)*10)/10
		
		if (not string.find(txt, "[\.]")) then txt = txt .. ".0" end
		self.text:SetText(txt)
		
		-- fade in
		if (self.frame:GetAlpha() < 1 and self.alive < AAV_CROWD_FADEINTIME) then
			if (self.frame:GetAlpha() + (self.timer*AAV_CROWD_FADEINSPEED) > 1) then
				self.frame:SetAlpha(1)
				self.text:SetAlpha(1)
			else
				self.frame:SetAlpha(self.frame:GetAlpha() + self.timer*AAV_CROWD_FADEINSPEED)
			end
		end
		
		-- fade out
		if (self.alive > (self.starttime - AAV_CROWD_FADEOUTTIME)) then
			if (self.frame:GetAlpha() - (self.timer*AAV_CROWD_FADEOUTSPEED) < 0) then
				self.frame:SetAlpha(0)
				self.text:SetAlpha(0)
			else
				self.frame:SetAlpha(self.frame:GetAlpha() - (self.timer*AAV_CROWD_FADEOUTSPEED))
			end
		end
		
		self.alive = self.alive + self.timer
		self.timer = 0
		
		-- setting dead
		if (self.alive > self.ttl or not visible) then
			self:setDead()
		end
	end
end