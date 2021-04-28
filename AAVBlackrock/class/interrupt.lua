AAV_Interrupt = {}
AAV_Interrupt.__index = AAV_Interrupt

function AAV_Interrupt:new()
	local self = {}
	setmetatable(self, AAV_Interrupt)
	
	return self
end

print("RUFL")