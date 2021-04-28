AAV_Aura = {}
AAV_Aura.__index = AAV_Aura

function AAV_Aura:new(parent, spellid, type, pos, duration)
	
	local self = {}
	setmetatable(self, AAV_Aura)
	
	self.frame = AAV_Gui:createAura(parent, i)
	self.parent = parent
	self.spellid = spellid
	self.type = type
	self.position = pos
	self.duration = duration
	
	return self
	
end