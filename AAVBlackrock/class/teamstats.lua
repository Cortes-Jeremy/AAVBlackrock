AAV_TeamStats = {}
AAV_TeamStats.__index = AAV_TeamStats

function AAV_TeamStats:new(parent, teamdata, matchdata, team, bracket, cdhack)

	local self = {}
	setmetatable(self, AAV_TeamStats)

	self.teamhead = AAV_Gui:createTeamHead(parent)
	self.entries = {}
	for i = 1, 5 do
		self.entries[i] = {}
		self.entries[i]["entry"], self.entries[i]["icon"], self.entries[i]["name"], self.entries[i]["damage"], self.entries[i]["high"], self.entries[i]["heal"], self.entries[i]["rating"], self.entries[i]["mmr"] = AAV_Gui:createDetailEntry(parent)
	end
	self:setValue(parent, teamdata, matchdata, team, bracket)
	
	return self
	
end

function AAV_TeamStats:hideAll()
	for k,v in pairs(self.entries) do
		v["entry"]:Hide()
	end
end

function AAV_TeamStats:setValue(parent, teamdata, matchdata, team, bracket)
	
	self.parent = parent
	self.team = team
	self.bracket = bracket
	self.posY = ((team-1) * bracket * (25))
	
	self:hideAll()
	
	self.teamhead:SetText(teamdata.name)
	self.teamhead:SetPoint("TOPLEFT", parent, 20, -25 - self.posY - (team * 55) + 15)

	local rating, mmr, diff
	local i = 1
	
	if (teamdata.diff and teamdata.diff >= 0) then diff = "+" .. teamdata.diff else diff = teamdata.diff end
	if (not teamdata.rating) then rating = "-" else rating = teamdata.rating .. " (" .. diff .. ")" end
	if (not teamdata.mmr) then mmr = "-" else mmr = teamdata.mmr end

	for c,w in pairs(matchdata) do
		if (w.player == 1 and w.team == team) then
			self.entries[i]["entry"]:Show()
			self.entries[i]["entry"]:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -35 - self.posY - (team * 55) - (25 * (i-1)))
			self.entries[i]["icon"].texture:SetTexture("Interface\\Addons\\AAVBlackrock\\res\\" .. w.class .. ".tga")
			self.entries[i]["name"]:SetText(w.name)
			self.entries[i]["name"]:SetTextColor(AAV_Util:getTargetColor(w, true))
			self.entries[i]["damage"]:SetText(w.ddone)
			self.entries[i]["high"]:SetText(w.hcrit)
			self.entries[i]["heal"]:SetText(w.hdone)
			self.entries[i]["rating"]:SetText(rating)
			self.entries[i]["mmr"]:SetText(mmr)
			i = i + 1
		end
	end
end