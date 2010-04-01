
local _G = getfenv(0)
local RantTooltip = _G.RantTooltip

if not RantTooltip then return end

local am = function(msg)
	ChatFrame1:AddMessage(msg)
end

local font = "Interface\\AddOns\\RTT_Hexe\\media\\ABF.ttf"
local barTexture = "Interface\\AddOns\\RTT_Hexe\\media\\Flat"
local barTexture2 = "Interface\\AddOns\\RTT_Hexe\\media\\Hatched"
local statusBarsInTooltip = true

RantTooltip.ReactionColors[2] = {1, 0, 0}
RantTooltip.ReactionColors[4] = {1, 1, 0}
RantTooltip.ReactionColors[5] = {0, 1, 0}

RantTooltip.PowerColors["MANA"] = {0, 144/255, 1}

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 8, 
	edgeFile = "Interface\\AddOns\\RTT_Hexe\\media\\krsnik.tga", edgeSize = 12, 
	insets = {left = 3,right = 2,top = 3,bottom = 2},
}

local sbbackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	insets = {top = -1, bottom = -1, left = -1, right = -1},
}

--Status bar
local showStatusBar = function(bar)
	GameTooltip:AddLine(" ")
	bar:ClearAllPoints()
	bar:SetPoint("LEFT", "GameTooltipTextLeft"..GameTooltip:NumLines(true), "LEFT", 0, -2)
	bar:SetPoint("RIGHT", GameTooltip, "RIGHT", -9, 0)
	bar:Show()
	GameTooltip:SetMinimumWidth(120)
end

local hideStatusBar = function(bar)
	if bar:IsShown() then
		bar:Hide()
		local line = select(2,bar:GetPoint())
		if line and line:IsShown() and line:GetText() == " " then
			GameTooltip:DeleteLine(line)
		end
	end
end

local shortValue = function(value)
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return value
	end
end

RantTooltip.Tags["$hshcur"] = function(unit, bar) return shortValue(RantTooltip.Tags["$cur"](unit, bar)) end
RantTooltip.Tags["$hshmax"] = function(unit, bar) return shortValue(RantTooltip.Tags["$max"](unit, bar)) end
RantTooltip.Tags["$hbartext"] = function(unit, bar)
	if bar then
		local hpcur, hpmax
		if bar == "Health" then
			hpcur = GameTooltipStatusBar:GetValue()			
			hpmax = select(2,GameTooltipStatusBar:GetMinMaxValues())
		else
			hpcur = _G["Unit"..bar](unit)
			hpmax = _G["Unit"..bar.."Max"](unit)
		end
		if (hpcur < hpmax) then
			return hpcur.."/"..hpmax
		else
			return hpmax 
		end
	end
end
RantTooltip.Tags["$hdead"] = function(unit) return UnitIsDead(unit) and "|cffB30000DEAD|r" or UnitIsGhost(unit) and "|cff949494GHOST|r" end
RantTooltip.Tags["$hguild"] = function(unit) return UnitIsPlayer(unit) and GetGuildInfo(unit) and "|cff7AFF7A"..GetGuildInfo(unit).."|r" or (RantTooltip.factionInfo and "|cff7AFF7A"..RantTooltip.factionInfo.."|r") end
RantTooltip.Tags["$hrank"] = function(unit) return UnitIsPlayer(unit) and GetGuildInfo(unit) and "|cff7AFF7A"..select(2,GetGuildInfo(unit)).."|r" end


local layout = function(self)
	self:SetBackdrop(backdrop)
	self:SetScale(0.75)
	self:SetBackdropColor(0, 0, 0)
	self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	
	self.bg = self.bg or self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetPoint("TOPLEFT",self,"TOPLEFT",2,-2)
	self.bg:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",-2,2)
	self.bg:SetTexture(barTexture)
	self.bg:SetVertexColor(0.3,0.3,0.3)
	
	if self == GameTooltip then
		RantTooltip:SetInitialAnchor("BOTTOMRIGHT", -120, 200)
		
		--Characters inside { brackets will only show if all variables encompassed by the brackets have a return value
		RantTooltip:SetUnitTags{
			"$dnd$name{ ($aserver)}{: $target}",
			"{$hdead}",
			"{$hguild}{: $hrank}",
			"$level$classification {$race $class}{$type}",
			"$misc",
			"{Talents: $spec} {($talents)}",
		}
		
		GameTooltipHeaderText:SetFont(font, 14, "OUTLINE")
		GameTooltipText:SetFont(font, 13, "OUTLINE")
		
		self.raidIcon = self.raidIcon or self:CreateTexture(nil, "ARTWORK")
		self.raidIcon:SetWidth(16); self.raidIcon:SetHeight(16)
		self.raidIcon:SetPoint("TOP", self, 0, 8)
		
		self.combatIcon = self.combatIcon or self:CreateTexture(nil, "OVERLAY")
		self.combatIcon:SetWidth(20); self.combatIcon:SetHeight(20)
		self.combatIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
		self.combatIcon:SetTexCoord(0.5, 1.0, 0, 0.5)
		self.combatIcon:SetPoint("TOPRIGHT", self, "TOPLEFT", 2, 2)
		self.combatIcon:Hide()
			
		self.PostSetUnit = function(self, unit)
			local reaction = UnitReaction(unit, "player")
			local isplayer = UnitPlayerControlled(unit)
			if reaction then
				self:SetBackdropBorderColor(unpack(RantTooltip.ReactionColors[reaction])) 
			end
			if isplayer then
				self:SetBackdropBorderColor(GameTooltip_UnitColor(unit))
			end
			local r, g, b = UnitSelectionColor(unit)
			if statusBarsInTooltip then
				if (not UnitIsDead(unit)) and (UnitPowerType(unit) == 0) then
					showStatusBar(self.HealthBar)
					if UnitPowerMax(unit) > 0 then
						showStatusBar(self.PowerBar)
						RantTooltip:UpdatePowerBar()
					end
				elseif (not UnitIsDead(unit)) and (not (UnitPowerType(unit) == 0)) then
					showStatusBar(self.HealthBar)
					self.PowerBar:Hide()
				elseif UnitIsDeadOrGhost(unit) then
					self.HealthBar:Hide()
					self.PowerBar:Hide()
				else
					self.PowerBar:Hide()
				end
			end
		end
		if statusBarsInTooltip == true then
		for _, name in ipairs{"Health", "Power"} do
			local statusBar = CreateFrame("StatusBar", nil, self)
			statusBar:SetBackdrop(sbbackdrop)
			statusBar:SetBackdropColor(0, 0, 0)
			statusBar:SetStatusBarTexture(barTexture2)
			statusBar:SetStatusBarColor(0.25, 0.25, 0.35)
					
			statusBar.bg = statusBar.bg or statusBar:CreateTexture(nil, "BORDER")
			statusBar.bg:SetAllPoints(statusBar)
					
			if name == "Health" then
				statusBar.Anchor = { 0, 10 }
				statusBar.unitColors = true
					
				statusBar.text = statusBar.text or statusBar:CreateFontString(nil, "OVERLAY")
				statusBar.text:SetFont(font, 10, "OUTLINE")
				statusBar.text:SetJustifyH("CENTER")
				statusBar.text:SetAllPoints(statusBar)
				statusBar.Tags = "$hbartext   $perc%"
					
				statusBar:SetHeight(8)
				statusBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 10, 0)
				statusBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -10, 0)
			else
				statusBar.Anchor = { 0, 18 }
				statusBar.unitColors = false
				statusBar.powerColors = true
						
				statusBar.text = statusBar.text or statusBar:CreateFontString(nil, "OVERLAY")
				statusBar.text:SetFont(font, 10, "OUTLINE")
				statusBar.text:SetJustifyH("CENTER")
				statusBar.text:SetAllPoints(statusBar)
				statusBar.Tags = "$hbartext"
						
				statusBar.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
				statusBar.bg.color = 0.3
			
				statusBar:SetHeight(8)
				statusBar:SetPoint("TOPLEFT", self.HealthBar, "BOTTOMLEFT", 0, -2)
				statusBar:SetPoint("TOPRIGHT", self.HealthBar, "BOTTOMRIGHT", 0, -2)
			end
					
			statusBar:Hide()
			self[name.."Bar"] = statusBar
		end
	end
end
		
	if not statusBarsInTooltip then
		local statusBar = CreateFrame("StatusBar", nil, self)
		statusBar:SetStatusBarTexture(barTexture)
		statusBar:SetStatusBarColor(0, 1, 0)
			
		statusBar.bg = statusBar.bg or statusBar:CreateTexture(nil, "BORDER")
		statusBar.bg:SetAllPoints(statusBar)
			
		statusBar.Anchor = { 0, 10 }
		statusBar.bg:SetTexture(0, 0, 0, 0.5)
			
		statusBar.text = statusBar.text or statusBar:CreateFontString(nil, "OVERLAY")
		statusBar.text:SetFont(font, 9, "OUTLINE")
		statusBar.text:SetJustifyH("CENTER")
		statusBar.text:SetAllPoints(statusBar)
		statusBar.Tags = "$hbartext"
			
		statusBar:SetHeight(8)
		statusBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, -1)
		statusBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -2, -1)
			
		GameTooltip.HealthBar = statusBar
	end
		
	if self == ItemRefTooltip then
		self.itemIcon = self:CreateTexture(nil, "OVERLAY")
		self.itemIcon:SetWidth(37); self.itemIcon:SetHeight(37)
		self.itemIcon:SetPoint("TOPRIGHT", self, "TOPLEFT", -1, 0)
	end
			
			
	if self:IsObjectType("GameTooltip") then
		RantTooltip:RegisterScript(self, "OnTooltipSetItem", function()
			if self:GetItem() then
				local link = select(2,self:GetItem())
				local rarity = select(3,GetItemInfo(link)) or 1
				self:SetBackdropBorderColor(GetItemQualityColor(rarity))
				self:SetBackdropColor(0.11, 0.11, 0.11)
			end
		end)
				
		RantTooltip:RegisterScript(self, "OnHide", function()
			if self:GetItem() then
				self:SetBackdropBorderColor(1, 1, 1, 1)
			end
		end)
	end
end 

RantTooltip:RegisterLayout("Hexe", layout)
RantTooltip:UseLayout("Hexe")