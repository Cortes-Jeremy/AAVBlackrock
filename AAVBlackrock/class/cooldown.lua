AAV_Cooldown = {}
AAV_Cooldown.__index = AAV_Cooldown

function AAV_Cooldown:new(parent, spellid, duration, entity, entry)
	
	local self = {}
	setmetatable(self, AAV_Cooldown)
	
	self.frame, self.icon, self.text = AAV_Gui:createCooldown(parent)
	self:setValue(parent, spellid, duration, entity, entry)
	
	return self
	
end

function AAV_Cooldown:setValue(parent, spellid, duration, entity, entry)
	local name, rank, icon = GetSpellInfo(spellid)
	
	self.parent = parent
	self.spellid = spellid
	self.duration = duration
	self.position = 0
	self.name = name
	self.rank = rank
	self.alive = 0
	self.timer = 0
	self.dead = false
	self.entity = entity
	self.entry = entry
	
	self.posX, self.posY = 0, 0
		
	self.icon.texture:SetTexture(icon)
	self.text:SetText(self:getDuration())
	self.frame:SetParent(self.parent)
	self.frame:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", self.posX, self.posY)
	self.frame:SetAlpha(0)
	self.frame:Show()
end

function AAV_Cooldown:isDead()
	return self.dead
end

function AAV_Cooldown:getDuration()
	local str = "?"
	if ((self.duration - self.alive) > 60) then
		str = math.floor((self.duration - self.alive)/60) .. "m"
	else
		str = math.floor(self.duration - self.alive)
	end
	return str
end

function AAV_Cooldown:update(elapsed, rate)
	self.timer = self.timer + elapsed
	
	if (self.timer > (1 / AAV_UPDATESPEED)) then
		
		-- MOVING
		if (self.posY < (self.position * AAV_CC_ICONSIZE)) then
			-- UP
			if (self.posY + (self.timer * AAV_CC_ICONSPEED) > (self.position * AAV_CC_ICONSIZE + AAV_CC_ICONMARGIN)) then
				self.posY = (self.position * AAV_CC_ICONSIZE + AAV_CC_ICONMARGIN)
			else
				self.posY = self.posY + (self.timer * AAV_CC_ICONSPEED)
			end
			self.frame:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", self.posX, self.posY)
			
		elseif (self.posY > (self.position * AAV_CC_ICONSIZE)) then
			-- DOWN
			if (self.posY - (self.timer * AAV_CC_ICONSPEED) < (self.position * AAV_CC_ICONSIZE + AAV_CC_ICONMARGIN)) then
				self.posY = (self.position * AAV_CC_ICONSIZE + AAV_CC_ICONMARGIN)
			else
				self.posY = self.posY - (self.timer * AAV_CC_ICONSPEED)
			end
			self.frame:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", self.posX, self.posY)
			
		end
		
		self.text:SetText(self:getDuration())
		
		if (self.alive > self.duration) then
			self.frame:Hide()
			self.dead = true
		end
		
		-- FADE IN
		if (self.alive < AAV_CC_FADEINTIME) then
			if (self.frame:GetAlpha() + (self.timer * AAV_CC_FADEINSPEED) > 1) then
				self.frame:SetAlpha(1)
			else
				self.frame:SetAlpha(self.frame:GetAlpha() + (self.timer * AAV_CC_FADEINSPEED))
			end
		end
			
		-- FADE OUT
		if (self.alive > self.duration - AAV_CC_FADEOUTTIME) then
			if (self.frame:GetAlpha() - (self.timer * AAV_CC_FADEINSPEED) < 0) then
				self.frame:SetAlpha(0)
			else
				self.frame:SetAlpha(self.frame:GetAlpha() - (self.timer * AAV_CC_FADEINSPEED))
			end
		end
		
		-- LIST LIMIT
		if (self.position + 1 >= AAV_CC_MAXLISTING) then
			if (self.position + 1 == AAV_CC_MAXLISTING) then
				if (self.frame:GetAlpha() < 0.5) then
					if (self.frame:GetAlpha() + (self.timer * AAV_CC_FADEINSPEED) > 0.5) then
						self.frame:SetAlpha(0.5)
					else
						self.frame:SetAlpha(self.frame:GetAlpha() + (self.timer * AAV_CC_FADEINSPEED))
					end
				elseif (self.frame:GetAlpha() > 0.5) then
					if (self.frame:GetAlpha() - (self.timer * AAV_CC_FADEOUTSPEED) < 0.5) then
						self.frame:SetAlpha(0.5)
					else
						self.frame:SetAlpha(self.frame:GetAlpha() - (self.timer * AAV_CC_FADEOUTSPEED))
					end
				end
			else
				if (self.frame:GetAlpha() > 0) then
					if (self.frame:GetAlpha() - (self.timer * AAV_CC_FADEOUTSPEED) < 0) then
						self.frame:SetAlpha(0)
					else
						self.frame:SetAlpha(self.frame:GetAlpha() - (self.timer * AAV_CC_FADEOUTSPEED))
					end
				end
			end
		else
			if (self.frame:GetAlpha() < 1 and not (self.alive > self.duration - AAV_CC_FADEOUTTIME) and not (self.alive < AAV_CC_FADEINTIME)) then
				if (self.frame:GetAlpha() + (self.timer * AAV_CC_FADEINSPEED) > 1) then
						self.frame:SetAlpha(1)
					else
						self.frame:SetAlpha(self.frame:GetAlpha() + (self.timer * AAV_CC_FADEINSPEED))
					end
			end
		end
		
		self.alive = self.alive + self.timer
		self.timer = 0
		
	end
	
end