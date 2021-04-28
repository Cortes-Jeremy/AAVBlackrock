Seeker = {}
Seeker.__index = Seeker;

function Seeker:new(parent)
	local self = {}
	setmetatable(self, Seeker);
	
	self.bar = Gui:createSeekerBar(parent)
	
	--[[
	local left, right
	GameTooltip:ClearLines()
    left = getglobal(GameTooltip:GetName().."TextLeft1")
    right = getglobal(GameTooltip:GetName().."TextRight1")
	--]]
	
	self.tick = Gui:createSeekerText(self.bar)
	self.play = nil
	self.stop = nil
	self.close = nil
	
	return self
end