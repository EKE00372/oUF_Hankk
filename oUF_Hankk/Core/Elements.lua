-------------------------------
-- Other elements / 其他元素 --
-------------------------------

local _, ns = ...
local oUF = ns.oUF
local C, F, G, T = ns[1], ns[2], ns[3], ns[4]

-- 資源文字與圖示的固定間距。
local textGap = 3

--===================================================--
-- Player resources / 玩家職業資源
--===================================================--

-- 職業資源圖集分為四個 128×128 圖格：底圖、填色、柔光，以及部分圖示使用的高光。
local resourceSize = {combo = 28, holypower = 24.5, soulshards = 28, tipspear = 32, totems = {36, 30},}	-- 尺寸
local resourceGap = {combo = -5, holypower = 0, soulshards = -6, tipspear = -6}	-- 間距，去除留白
local resourceFillBounds = {combo = {32, 97}, soulshards = {23, 103},}	-- 扣除圖格留白後，填充進度條的圖案實際範圍上下邊界

-- 填色、柔光、閃光與數量文字共用 Tags 設定的色表。
local function PostUpdateResourceColor(element, color)
	if not color then return end
	local r, g, b = color:GetRGB()

	for _, bar in ipairs(element.Pillars or element.Icons or element) do
		bar.Fill:SetVertexColor(r, g, b)
		bar.Glow:SetVertexColor(r, g, b)
		if bar.PulseFill then bar.PulseFill:SetVertexColor(r, g, b) end
	end

	if element.Value then element.Value:SetTextColor(r, g, b) end
end

-- 和血量水位百分比一樣，建立一個透明進度條，利用填充範圍控制充能型資源的水位裁切。
local function CreateResourceDriver(self, width, height)
	local bar = CreateFrame("StatusBar", nil, self, "DisableUntrustedLayoutScriptsTemplate")
	bar:SetSize(width, height)
	bar:SetOrientation("VERTICAL")
	bar:SetReverseFill(false)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar:SetStatusBarTexture(G.media.blank)
	bar:GetStatusBarTexture():SetAlpha(0)	-- 控制水位條的充能進度條維持透明。
	bar:Hide()
	return bar
end

-- 建立各種職業資源共用的單顆圖示；bodyProgress 用於顯示充能進度。
local function CreateResourceIcon(self, shape, width, height, bodyProgress)
	height = height or width	-- 未指定高度時(漩渦武器除外)，使用與寬度相同的尺寸。

	local texture = G.media[shape]
	local bar = CreateResourceDriver(self, width, height)
	local base = bar:CreateTexture(nil, "BACKGROUND")
	base:SetAllPoints(bar)
	base:SetTexture(texture)
	base:SetTexCoord(0, 1/4, 0, 1)

	-- 替充能類的資源建立專用的充能進度條
	local driver = bar
	if bodyProgress then
		driver = CreateResourceDriver(bar, width, height)
		driver:SetAllPoints(bar)
		driver:Show()
	end
	
	-- 負責裁切的剪刀：水位隨進度增長
	local clip = CreateFrame("Frame", nil, driver, "DisableUntrustedLayoutScriptsTemplate")
	clip:SetAllPoints(driver:GetStatusBarTexture())	-- 材質錨點在完整圖示上，只裁切不拉伸。
	clip:SetClipsChildren(true)
	-- 滿格柔光與閃光動畫放在填色裁切框外，放大時不會被切掉。
	local glowParent = clip
	if bodyProgress then
		glowParent = CreateFrame("Frame", nil, bar)
		glowParent:SetAllPoints(bar)
	end

	-- 充能未完成的那顆資源不顯示glow
	local glow = glowParent:CreateTexture(nil, "BORDER")
	glow:SetAllPoints(bar)
	glow:SetTexture(texture)
	glow:SetTexCoord(2/4, 3/4, 0, 1)
	glow:SetAlpha(0.8)
	if bodyProgress then glow:Hide() end
	bar.Glow = glow

	local fill = clip:CreateTexture(nil, "ARTWORK")
	fill:SetAllPoints(bar)
	fill:SetTexture(texture)
	fill:SetTexCoord(1/4, 2/4, 0, 1)
	bar.Fill = fill

	-- 奧法的星芒利用裁切功能，讓它跟著豆子的有無一起顯隱。
	if shape == "arcane" then
		local highlight = clip:CreateTexture(nil, "OVERLAY")
		highlight:SetAllPoints(bar)
		highlight:SetTexture(texture)
		highlight:SetTexCoord(3/4, 1, 0, 1)
	end

	if bodyProgress then
		-- 閃光也帶上本體，放大時中間有顏色，不只剩一個空心環。
		local pulseFill = glowParent:CreateTexture(nil, "BACKGROUND")
		pulseFill:SetAllPoints(bar)
		pulseFill:SetTexture(texture)
		pulseFill:SetTexCoord(1/4, 2/4, 0, 1)
		pulseFill:SetAlpha(0.8)
		pulseFill:Hide()
		bar.PulseFill = pulseFill

		local pulse = glowParent:CreateAnimationGroup()
		pulse:SetLooping("NONE")
		-- 上一版先膨脹再收縮的寫法
		--[[
		for order = 1, 2 do
			local scale = pulse:CreateAnimation("Scale")
			scale:SetOrder(order)
			scale:SetOrigin("CENTER", 0, 0)
			local from, to = order == 1 and 1 or 1.5, order == 1 and 1.5 or 1
			scale:SetScaleFrom(from, from)
			scale:SetScaleTo(to, to)
			scale:SetDuration(.15)
			scale:SetSmoothing("IN_OUT")
		end
		]]
		-- 填色與光暈一起從放大狀態收回；本體固定不動。
		local scale = pulse:CreateAnimation("Scale")
		scale:SetOrder(1)
		scale:SetOrigin("CENTER", 0, 0)
		scale:SetScaleFrom(1.5, 1.5)
		scale:SetScaleTo(1, 1)
		scale:SetDuration(.5)
		scale:SetSmoothing("IN_OUT")
		-- 收縮同時淡入；共用框讓填色與光暈一起柔和出現，不改平常亮度。
		local fade = pulse:CreateAnimation("Alpha")
		fade:SetOrder(1)
		fade:SetFromAlpha(0)
		fade:SetToAlpha(1)
		fade:SetDuration(.08)
		fade:SetSmoothing("IN_OUT")
		
		local function HidePulseFill() pulseFill:Hide() end
		pulse:SetScript("OnPlay", function() pulseFill:Show() end)
		pulse:SetScript("OnFinished", HidePulseFill)
		pulse:SetScript("OnStop", HidePulseFill)
		local visible, full = false, nil
		
		-- 在水位裁切框之外，監看資源何時顯示或隱藏。
		glowParent:SetScript("OnShow", function() visible, full = true, nil end)
		glowParent:SetScript("OnHide", function()
			visible, full = false, nil
			pulse:Stop()
		end)

		local top, bottom = unpack(resourceFillBounds[shape])
		-- 術士、符文和精華的進度都從 0 開始；符文的上限是冷卻秒數。
		local maximum, current = 1, 0
		local function UpdateFill(fromValue)
			-- 將充能進度按各個豆子的圖示可見高度填充。
			local value
			if maximum <= 0 or current <= 0 then
				value = 0
			elseif current >= maximum then
				value = 1
			else
				value = (128 - bottom + (bottom - top) * current / maximum) / 128
			end
			driver:SetValue(value)

			local complete = (value == 1)
			glow:SetShown(complete)

			if not complete then
				pulse:Stop()
			elseif fromValue and visible and full == false then
				pulse:Play()
			end

			-- 更新範圍不代表剛充滿。圖示重新顯示時，先記住第一個數值，不播放閃光。
			if fromValue then full = complete end
		end

		hooksecurefunc(bar, "SetMinMaxValues", function(_, _, high)
			maximum = high
			UpdateFill(false)
		end)

		hooksecurefunc(bar, "SetValue", function(_, value)
			current = value
			UpdateFill(true)
		end)
	end

	return bar
end

T.CreateClassPower = function(self)
	local class = UnitClassBase("player")
	local supported = {
		DEATHKNIGHT = true, DEMONHUNTER = true, DRUID = true, EVOKER = true,
		HUNTER = true, MAGE = true, MONK = true, PALADIN = true,
		ROGUE = true, SHAMAN = true, WARLOCK = true,
	}
	if not supported[class] then return end

	-- 噬滅與增強不是傳統豆子連擊點，專門處理
	if class == "SHAMAN" or class == "DEMONHUNTER" then
		local element = {}
		-- 保留 ClassPower 的格子，包含載具連擊點；只把矩形貼圖設為透明。
		for index = 1, 10 do
			element[index] = CreateResourceDriver(self, 1, 1)
			element[index]:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		end

		-- 噬滅 靈魂碎片
		if class == "DEMONHUNTER" then
			-- 碎片圖示與實際數量都跟隨這個 icon 的顯隱。
			-- oUF 標準dh資源是一個進度條，我們將進度條換成單個材質固定為滿進度，當普通icon顯示。
			local icon = CreateResourceIcon(element[1], "soulshards", resourceSize.soulshards + 2)
			icon:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -12, 4)
			icon:SetValue(1)
			icon:Show()

			element.Icons = {icon}
			element.Value = F.CreateText(icon, resourceSize.soulshards - 6, "RIGHT")
			element.Value:SetPoint("RIGHT", icon, "LEFT", -textGap, 0)
			element.PostUpdateColor = PostUpdateResourceColor

			element.PostUpdate = function(element, current, maximum, currentChanged, maximumChanged, powerType)
				-- 噬滅的 oUF callback 不提供具體層數，所以要從光環取得碎片數量。
				if powerType == "SOUL_FRAGMENTS" and maximum then
					local spells = Constants.UnitPowerSpellIDs
					local metamorphosis = C_UnitAuras.GetPlayerAuraBySpellID(spells.VOID_METAMORPHOSIS_SPELL_ID)
					local aura = C_UnitAuras.GetPlayerAuraBySpellID((metamorphosis
						and spells.SILENCE_THE_WHISPERS_SPELL_ID) or spells.DARK_HEART_SPELL_ID)
					local count = (aura and aura.applications) or 0
					element.Value:SetText(count)
				elseif powerType == "COMBO_POINTS" and maximum then
					element.Value:SetText(current)
				else
					element.Value:SetText(nil)
				end
			end

			self.ClassPower = element
			return
		end

		-- 增強 漩渦武器
		element.Pillars = {}
		local width, height = unpack(resourceSize.totems)
		for index = 1, 5 do
			local bar = CreateResourceIcon(element[1], "totems", width, height)
			-- 十層模式由右往左累積；每根圖騰柱也先填右半，再填左半。
			bar:SetOrientation("HORIZONTAL")
			bar:SetReverseFill(true)
			if index == 1 then
				bar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -12, 4)
			else
				bar:SetPoint("RIGHT", element.Pillars[index - 1], "LEFT", 2, 0)
			end

			bar:Show()
			element.Pillars[index] = bar
		end
		element.PostUpdateColor = PostUpdateResourceColor

		-- 上限五層時每層填一根，上限十層時每層填半根；停用時不更新柱子。
		element.PostUpdate = function(element, current, maximum, currentChanged, maximumChanged)
			if (currentChanged or maximumChanged) and maximum > 0 then
				local filled = current * 5 / maximum
				for index, bar in ipairs(element.Pillars) do
					bar:SetValue(filled - index + 1)
				end
			end
		end

		self.ClassPower = element
		return
	end

	-- 材質
	local shape = "combo"
	if class == "PALADIN" then
		shape = "holypower"
	elseif class == "WARLOCK" then
		shape = "soulshards"
	elseif class == "MAGE" then
		shape = "arcane"
	elseif class == "HUNTER" then
		shape = "tipspear"
	end
	local sizeKey = (shape == "arcane" and "combo") or shape	-- 法師共用連擊點的圓圈大小與間距，只換成自己的星芒材質。
	local size = resourceSize[sizeKey]
	local gap = resourceGap[sizeKey]
	local element = {}

	-- DK符文、龍能與術士靈魂裂片需要充能，且在充能時不顯示 glow。
	local bodyProgress = (class == "DEATHKNIGHT") or (class == "EVOKER") or (class == "WARLOCK")
	local count = ((class == "DEATHKNIGHT" or class == "EVOKER") and 6) or 10
	
	-- 靠右對齊，向左增長
	for index = 1, count do
		local bar = CreateResourceIcon(self, shape, size, nil, bodyProgress)
		if index == 1 then
			bar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -12, 4)
		else
			bar:SetPoint("RIGHT", element[index - 1], "LEFT", -gap, 0)
		end

		element[index] = bar
	end
	element.PostUpdateColor = PostUpdateResourceColor

	if class == "DEATHKNIGHT" then
		element.colorSpec = true
		self.Runes = element
	elseif class == "EVOKER" then
		element.color = self.colors.power.ESSENCE
		element.updateInterval = .1
		self.Essence = element
	else
		self.ClassPower = element
	end
end

--===================================================--
-- Threat highlight / 仇恨高亮
--===================================================--

local function PostUpdatePlayerThreat(element, unit, status, color)
	local r, g, b = 0, 0, 0
	if unit == "player" and IsInGroup() and status and status > 0 then r, g, b = color:GetRGB() end
	local health = element.Health
	for _, digit in ipairs(health.Digits) do digit.Glow:SetVertexColor(r, g, b) end
	health.Percent.Glow:SetVertexColor(r, g, b)
end

T.CreatePlayerThreatIndicator = function(self)
	local indicator = CreateFrame("Frame", nil, self)
	indicator:EnableMouse(false)
	indicator.Health = self.Health
	indicator.PostUpdate = PostUpdatePlayerThreat
	hooksecurefunc(indicator, "Hide", function() PostUpdatePlayerThreat(indicator) end)
	indicator:Hide()
	self.ThreatIndicator = indicator
end

--===================================================--
-- Indicators / 狀態圖示
--===================================================--

-- 狀態圖集有八個 128px 圖格。預設每格顯示為 32 UI 單位：圖示本體占 24，四周各留 4 給柔光。
local function SetStatusTexture(element, column)
	element:SetTexture(G.media.statusicons)
	element:SetTexCoord(column / 8, (column + 1) / 8, 0, 1)
end

-- 這裡選擇陣營圖案；PvP 狀態同時控制透明度，以及後面圖示需要預留的間距。
local function UpdatePvPIndicator(self, event, unit)
	if unit and unit ~= self.__unit then return end
	unit = unit or self.__unit
	local element = self.PvPIndicator
	local faction = UnitFactionGroup(unit)
	local freeForAll = UnitIsPVPFreeForAll(unit)

	if freeForAll then
		faction = UnitFactionGroup("player")
	elseif unit == "player" and UnitIsMercenary(unit) then
		if faction == "Alliance" then faction = "Horde"
		elseif faction == "Horde" then faction = "Alliance" end
	elseif not UnitIsHumanPlayer(unit) then
		-- 載具使用玩家陣營；敵方載具則使用相反陣營。
		faction = UnitFactionGroup("player")
		if UnitIsEnemy("player", unit) then
			if faction == "Alliance" then faction = "Horde"
			elseif faction == "Horde" then faction = "Alliance" end
		end
	end
	local texture = (faction == "Alliance" and G.media.pvp_alliance) or (faction == "Horde" and G.media.pvp_horde)
	if texture then
		element:SetTexture(texture)
		element:SetTexCoord(0, 1, 0, 1)
	elseif freeForAll then
		element:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		element:SetTexCoord(0, 0.65625, 0, 0.65625)
	else
		element:Hide()
		return
	end

	-- 材質保持顯示，由 PvP 狀態同時收起透明度與占位寬度。
	local active = UnitIsPVP(unit)
	element:SetAlphaFromBoolean(active, 1, 0)
	element.Spacing:SetValue(C_CurveUtil.EvaluateColorValueFromBoolean(active, 1, .5), Enum.StatusBarInterpolation.Immediate)
	element:Show()
end

-- addpower 法力 和 altpower 替代能量共用文字格式。
local function UpdateSecondaryPowerText(element, current, maximum)
	if not element.isActive then return end
	-- addpower 靠右對齊，前面的空格讓左側狀態圖示與數值隔開。
	local prefix = (element == element.__owner.AdditionalPower and " ") or ""
	local text
	if F.GetHankkOption("CurrentValuesOnly") then
		text = string.format(prefix.."%s", F.NumberAbbrValue(current))
	else
		text = string.format(prefix.."%s/%s", F.NumberAbbrValue(current), F.NumberAbbrValue(maximum))
	end
	-- 額外法力以最大值控制整段文字留空；目前法力為零仍顯示 0／上限。
	if element == element.__owner.AdditionalPower then text = F.FormatZero(maximum, text) end
	element.Value:SetFormattedText("%s", text)
end

local function ColorSecondaryPowerText(element, color)
	if color then
		element.Value:SetTextColor(color:GetRGB())
	else
		element.Value:SetTextColor(unpack(C.TextColor))
	end
end

-- 保留真正的 oUF StatusBar 承接事件，只顯示它的文字。
local function CreateSecondaryPowerText(self)
	local bar = CreateFrame("StatusBar", nil, self.Health, "DisableUntrustedLayoutScriptsTemplate")
	bar:SetSize(1, 1)
	bar:SetPoint("BOTTOMRIGHT", self.Value, "TOPRIGHT", 0, 0)
	bar:SetStatusBarTexture(G.media.blank)
	bar:GetStatusBarTexture():SetAlpha(0)
	bar:EnableMouse(false)
	bar.colorPower = true
	bar.Value = F.CreateText(bar, G.ValueFS, "RIGHT")
	bar.Value:SetHeight(G.ValueFS + 4)
	bar.Value:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
	bar:Hide()
	bar.isActive = false
	return bar
end

-- 目標特殊能量放進數值行；顯示條件與事件仍由官方元素管理。
T.CreateTargetAlternativePower = function(self)
	local power = CreateFrame("StatusBar", nil, self.Health, "DisableUntrustedLayoutScriptsTemplate")
	power:SetSize(1, 1)
	power:SetPoint("BOTTOMLEFT", self.Value, "BOTTOMLEFT", 0, 0)
	power:SetStatusBarTexture(G.media.blank)
	power:GetStatusBarTexture():SetAlpha(0)
	power:EnableMouse(false)
	power:Hide()
	power.isActive = false
	power.valueText = ""
	power.PostUpdate = function(element, unit, current, minimum, maximum)
		if not element.isActive then return end
		local value = F.NumberAbbrValue(current)
		if not F.GetHankkOption("CurrentValuesOnly") then
			value = string.format("%s/%s", value, F.NumberAbbrValue(maximum))
		end
		local color = self.colors.power[Enum.PowerType.Alternate]
		local markup = (color and color:GenerateHexColorMarkup()) or "|cffffffff"
		-- 結果直接交給標籤顯示；在分隔線與血量文字前還原顏色。
		element.valueText = string.format("%s%s|r || ", markup, value)
		self.Value:UpdateTag()
	end
	hooksecurefunc(power, "Show", function() power.isActive = true end)
	hooksecurefunc(power, "Hide", function()
		if not power.isActive then return end
		power.isActive = false
		power.valueText = ""
		self.Value:UpdateTag()
	end)
	self.AlternativePower = power
end

-- 從右往左：額外法力、特殊能量、狀態圖示，最後是團隊標記。
T.CreatePlayerStatusIndicators = function(self)
	local powers, icons = {}, {}
	local class = UnitClassBase("player")
	if class == "DRUID" or class == "PRIEST" or class == "SHAMAN" then
		local power = CreateSecondaryPowerText(self)
		power.PostUpdate = UpdateSecondaryPowerText
		power.PostUpdateColor = ColorSecondaryPowerText
		if class == "DRUID" then
			-- 只擴充德魯伊的副本；貓的能量與熊的怒氣也同時顯示法力。
			power.displayPairs = CopyTable(ALT_POWER_BAR_PAIR_DISPLAY_INFO)
			power.displayPairs.DRUID[Enum.PowerType.Energy] = true
			power.displayPairs.DRUID[Enum.PowerType.Rage] = true
		end
		self.AdditionalPower = power
		powers[#powers + 1] = power
	end
	local alternative = CreateSecondaryPowerText(self)
	-- 這兩個官方 callback 有 unit 參數；AdditionalPower 的 callback 則沒有。
	alternative.PostUpdate = function(element, unit, current, minimum, maximum)
		UpdateSecondaryPowerText(element, current, maximum)
	end
	alternative.PostUpdateColor = function(element, unit, color)
		ColorSecondaryPowerText(element, color)
	end
	self.AlternativePower = alternative
	powers[#powers + 1] = alternative
	-- 柔光留白隨圖示尺寸等比縮放；定位時扣回這段留白，讓圖示本體對齊。
	local inset = C.StatusSize * 4 / 24
	local pvpAdvance = C.StatusSize + 3
	for _, entry in ipairs({
		{"LeaderIndicator", 2, C.PlayerStatusColors.Role}, {"AssistantIndicator", 5, C.PlayerStatusColors.Role},
		{"PvPIndicator"},
		{"RestingIndicator", 1, C.PlayerStatusColors.Resting}, {"CombatIndicator", 0, C.PlayerStatusColors.Combat},
	}) do
		local icon = self.Health:CreateTexture(nil, "OVERLAY")
		icon:SetSize(C.StatusSize + inset * 2, C.StatusSize + inset * 2)
		icon:SetPoint("BOTTOMRIGHT", self.Value, "TOPRIGHT", inset, -inset)
		if entry[2] then
			SetStatusTexture(icon, entry[2])
			icon:SetVertexColor(unpack(entry[3]))
		else
			-- 半滿時不占位；全滿時，後面的圖示向左移 pvpAdvance 的距離。
			-- 填滿區域始終保留寬度，兩種狀態都能作為定位依據。
			local spacing = CreateFrame("StatusBar", nil, self.Health, "DisableUntrustedLayoutScriptsTemplate")
			spacing:SetSize(pvpAdvance * 2, 1)
			spacing:SetOrientation("HORIZONTAL")
			spacing:SetReverseFill(true)
			spacing:SetStatusBarTexture(G.media.blank)
			spacing:SetStatusBarColor(1, 1, 1, 0)
			spacing:SetMinMaxValues(0, 1)
			spacing:SetValue(.5, Enum.StatusBarInterpolation.Immediate)
			spacing:EnableMouse(false)
			icon.Spacing = spacing
			icon.Override = UpdatePvPIndicator
			icon:SetTexCoord(0, 1, 0, 1)
			icon:SetVertexColor(1, 1, 1)
			icon:SetBlendMode("BLEND")
		end
		icon:Hide()
		icon.isActive = false
		icons[#icons + 1] = icon
		self[entry[1]] = icon
	end
	-- 團隊標記接在所有狀態圖示後面，顯示時固定是這一列的最左側。
	local marker = self.RaidTargetIndicator
	marker.isActive = false
	icons[#icons + 1] = marker

	local function UpdateSpacing(icon, shown)
		if icon then
			if icon.isActive == shown then return end
			icon.isActive = shown
		end
		-- 從數值行右端開始，每個顯示中的項目接在前一個項目左側。
		-- 文字使用自然寬度；未顯示的項目不留空位。
		local anchor, point, gap = self.Value, "TOPRIGHT", 0
		for _, power in ipairs(powers) do
			if power.isActive then
				power:SetPoint("BOTTOMRIGHT", anchor, point, -gap, 0)
				anchor, point, gap = power.Value, "BOTTOMLEFT", textGap
			end
		end
		local offset = gap
		for _, indicator in ipairs(icons) do
			if indicator == self.PvPIndicator then
				indicator:SetPoint("BOTTOMRIGHT", anchor, point, inset - offset, -inset)
				indicator.Spacing:SetPoint("TOPRIGHT", anchor, point, pvpAdvance - offset, 0)
				anchor, point, offset = indicator.Spacing:GetStatusBarTexture(), "TOPLEFT", 0
			elseif indicator == self.RaidTargetIndicator then
				if indicator.isActive then
					indicator:SetPoint("BOTTOMRIGHT", anchor, point, -offset, 0)
				end
			elseif indicator.isActive then
				indicator:SetPoint("BOTTOMRIGHT", anchor, point, inset - offset, -inset)
				offset = offset + C.StatusSize
			end
		end
	end

	-- 所有物件建立後，再統一掛上顯隱 callback。
	for _, power in ipairs(powers) do
		hooksecurefunc(power, "Show", function() UpdateSpacing(power, true) end)
		hooksecurefunc(power, "Hide", function() UpdateSpacing(power, false) end)
	end
	for _, icon in ipairs(icons) do
		hooksecurefunc(icon, "Show", function() UpdateSpacing(icon, true) end)
		hooksecurefunc(icon, "Hide", function() UpdateSpacing(icon, false) end)
	end
	-- PvP 圖示被停用時，也要收回預留的間距。
	hooksecurefunc(self.PvPIndicator, "Hide", function()
		self.PvPIndicator.Spacing:SetValue(.5, Enum.StatusBarInterpolation.Immediate)
	end)
	-- oUF 每次更新都會選用隊長／嚮導圖集；接著換回我們的皇冠與職責顏色。
	self.LeaderIndicator.PostUpdate = function(icon)
		SetStatusTexture(icon, 2)
		icon:SetVertexColor(unpack(C.PlayerStatusColors.Role))
	end
	UpdateSpacing()
end

-- 目標狀態圖示：放在子框上，畫在名字前面，不讓文字蓋住圖示。
T.CreateTargetStatusIndicators = function(self)
	local size = C.StatusSize + 2
	local overlay = CreateFrame("Frame", nil, self.Info, "DisableUntrustedLayoutScriptsTemplate")
	overlay:SetSize(size, size)
	overlay:SetPoint("CENTER", self.Name, "CENTER", 0, 0)
	-- 置中排列
	local icons = {}
	local function UpdateSpacing(icon, shown)
		if icon.isActive == shown then return end
		icon.isActive = shown
		local count = 0
		for _, indicator in ipairs(icons) do
			if indicator.isActive then count = count + 1 end
		end
		local step = size - 4
		local offset = -(count - 1) * step / 2
		for _, indicator in ipairs(icons) do
			if indicator.isActive then
				indicator:SetPoint("CENTER", overlay, "CENTER", offset, 0)
				offset = offset + step
			end
		end
	end
	-- 位面、召喚、戰復
	for _, name in ipairs({"PhaseIndicator", "SummonIndicator", "ResurrectIndicator"}) do
		local icon = overlay:CreateTexture(nil, "OVERLAY")
		icon:SetSize(size, size)
		icon:SetAlpha(0.8)
		icon:SetPoint("CENTER", overlay, "CENTER", 0, 0)
		icon:Hide()
		icon.isActive = false
		icons[#icons + 1] = icon
		self[name] = icon
		-- oUF 顯示、隱藏或停用圖示時，重新計算整組的置中位置。
		hooksecurefunc(icon, "Show", function() UpdateSpacing(icon, true) end)
		hooksecurefunc(icon, "Hide", function() UpdateSpacing(icon, false) end)
	end
end
