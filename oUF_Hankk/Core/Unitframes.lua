local _, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

-- 數字與文字的水平間距，名字和數值行之間的垂直間距。
local textGap, textLineGap = 3, -2

--===================================================--
-- Atlas regions / 圖集裁切範圍
--===================================================--

-- 材質重置後，圖片尺寸統一為 256x256px，圖示可見範圍的高度統一，只需要調整排版寬度。
local size, scale = C.DigitSize, C.DigitSize / 256	-- 主框高度 = 尺寸大小；再將 256px 材質距離換算為 UI 尺寸的縮放比
local digitRegions = {	-- 每個數字只取排版寬度內的圖案；完整保留高度，水位位置不變。
	[0] = {width = 148.0442006060351},
	[1] = {width = 95.51238748776457},
	[2] = {width = 148.0442006060351},
	[3] = {width = 143.26858123164686},
	[4] = {width = 157.59543935481156},
	[5] = {width = 143.26858123164686},
	[6] = {width = 148.0442006060351},
	[7] = {width = 143.26858123164686},
	[8] = {width = 148.0442006060351},
	[9] = {width = 148.0442006060351},
}
-- 將各圖格尺寸換算成排版寬度，ColorCurve 可以一次傳遞四個座標，這裡借用 RGBA 保存左、右、上、下 UV，不用來染色。
for digit = 0, 9 do
	local region = digitRegions[digit]
	local column, row = digit % 4, math.floor(digit / 4)
	local inset = (256 - region.width) / 2
	region.texCoords = CreateColor((column * 256 + inset) / 1024,
		((column + 1) * 256 - inset) / 1024, row / 4, (row + 1) / 4)
	region.width = region.width * scale
end
local blankDigit = {width = 0, texCoords = CreateColor(2/4, 3/4, 2/4, 3/4)}
-- 狀態圖示的排版寬度仍以材質像素記錄，建立圖示時換算。
local statusAdvance = {death = 147.02857144932028, ghost = 170.74285716695266, offline = 109.46100923914561}

--===================================================--
-- Digit lookup / 數字對照
--===================================================--

local digitCurves, cropCurves, widthCurves = {}, {}, {}	-- 分別保存柔光圖格、數字裁切範圍與排版寬度
local castbarOffset = (192 - 79) * scale + (G.CastbarFS + 4) * 2	-- 施法條偏移，因百分號非框架而是附加材質，需錨點於主框並偏移
local sidePadding = 16 * scale	-- 原圖集各數字左右兩端各留 16 材質像素的距離，根距比例換算 = 間距 5。

-- 現行圖集的血量水位範圍是從圖格頂部往下的 y=40.6～213.4，根距比例換算底部位置與高度。
local waterBottom = (256 - 213.4) * scale
local waterHeight = (213.4 - 40.6) * scale

-- 預留 "最寬數字 100 +兩側留白" 的寬度，讓 0～100 的可點擊範圍固定。
local width = digitRegions[1].width + 2 * digitRegions[0].width + 2 * sidePadding

-- 建立兩套數字排版：目標和焦點靠左，玩家靠右。
for _, align in ipairs({"LEFT", "RIGHT"}) do
	local cells, crops, widths = {}, {}, {}
	digitCurves[align], cropCurves[align], widthCurves[align] = cells, crops, widths

	for slot = 1, 3 do
		cells[slot] = C_CurveUtil.CreateCurve()
		cells[slot]:SetType(Enum.LuaCurveType.Step)
		crops[slot] = C_CurveUtil.CreateColorCurve()
		crops[slot]:SetType(Enum.LuaCurveType.Step)
		widths[slot] = C_CurveUtil.CreateCurve()
		widths[slot]:SetType(Enum.LuaCurveType.Step)
	end

	-- 預建 0～100 的顯示方式供血量取用；階梯曲線讓未滿血的百分比捨去小數，滿血才顯示 100。
	for percent = 0, 100 do
		local text = tostring(percent)	-- 將百分比數值轉為文字字串
		local offset = (align == "RIGHT" and 3 - #text) or 0	-- 前面空出的顯示格

		for slot = 1, 3 do
			-- slot 是畫面上從左到右的第 1～3 格；index 是百分比字串中從左到右的字元位置。
			-- 右對齊的 37：第 1 格空白，第 2 格取 index 1 的 3，第 3 格取 index 2 的 7。
			local index = slot - offset
			local cell = 11		-- 透明圖格在圖集上是第11個
			local region = blankDigit

			-- 有數字的格子才取對應裁切範圍與字寬。
			if index >= 1 and index <= #text then
				local digit = tonumber(text:sub(index, index))
				region = digitRegions[digit]
				cell = digit + 1	-- 數字 0 在第 1 格，3 在第 4 格
			end

			-- 選好圖案與字寬；數字間的位置交給首尾相接的原生寬度條。
			cells[slot]:AddPoint(percent / 100, cell)
			crops[slot]:AddPoint(percent / 100, region.texCoords)
			widths[slot]:AddPoint(percent / 100, region.width)
		end
	end
end

--===================================================--
-- Health updates / 血量更新
--===================================================--

-- 替數字與百分號的填色染色，控制水位條的狀態條維持透明。
local function PostUpdateHealthColor(health, unit, color)
	local r, g, b = unpack(C.HealthColor)
	if color then r, g, b = color:GetRGB() end

	for _, digit in ipairs(health.Digits) do digit.Fill:SetVertexColor(r, g, b) end
	health.Percent.Fill:SetVertexColor(r, g, b)

	health:SetStatusBarColor(1, 1, 1, 0)
end

-- 離線優先於靈魂與死亡；沒有這些狀態時顯示血量數字。
local function PostUpdateHealth(health, unit)
	local connected = UnitIsConnected(unit)
	local status = (not connected and health.Status.offline)
		or (UnitIsGhost(unit) and health.Status.ghost)
		or (UnitIsDead(unit) and health.Status.death)

	-- 單位狀態改變時更新。
	if health.activeStatus ~= status then
		-- 顯示對應的狀態圖示，隱藏其他圖示。
		for _, icon in pairs(health.Status) do
			icon:SetShown(icon == status)
			icon.Glow:SetShown(icon == status)
		end

		-- 顯示狀態圖示時隱藏數字與百分號，恢復正常再顯示。
		for _, digit in ipairs(health.Digits) do
			digit.Base:SetShown(not status)
			digit.Fill:SetShown(not status)
			if digit.Healing then digit.Healing:SetShown(not status) end
			digit.Glow:SetShown(not status)
		end
		health.Percent.Base:SetShown(not status)
		health.Percent.Fill:SetShown(not status)
		if health.Percent.Healing then health.Percent.Healing:SetShown(not status) end
		health.Percent.Glow:SetShown(not status)

		health.activeStatus = status
	end

	-- 將裁切範圍與字寬都交給原生物件；文字跟隨整組數字的外緣。
	local statusSlot = (health.__owner.mystyle == "player" and 3) or 1
	for slot = 1, 3 do
		local digit = health.Digits[slot]
		local cell = health.values:EvaluateCurrentHealthPercent(health.DigitCurves[slot])
		local crop = health.values:EvaluateCurrentHealthPercent(health.CropCurves[slot])
		local digitWidth = health.values:EvaluateCurrentHealthPercent(health.WidthCurves[slot])
		digit.Base:SetTexCoord(crop:GetRGBA())
		digit.Fill:SetTexCoord(crop:GetRGBA())
		if digit.Healing then digit.Healing:SetTexCoord(crop:GetRGBA()) end
		digit.Glow:SetSpriteSheetCell(cell, 4, 4)

		-- 狀態圖示占用一格的寬度，其餘兩格收為零，旁邊文字便會跟著收近。
		digit.Width:SetValue(
			(status and ((slot == statusSlot and status.LayoutWidth) or 0)) or digitWidth,
			Enum.StatusBarInterpolation.Immediate
		)
	end
end

--===================================================--
-- Digit display / 數字顯示
--===================================================--

local function CreateHealthDigits(self)
	local isPlayer = self.mystyle == "player"
	local align = (isPlayer and "RIGHT") or "LEFT"

	-- [[ 數字 ]] --

	-- 依 oUF Health 元素的標準寫法建立一個透明血條，利用該狀態條的填充範圍控制數字的水位裁切。
	local health = CreateFrame("StatusBar", nil, self, "DisableUntrustedLayoutScriptsTemplate")
	health:SetSize(width, waterHeight)
	health:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, waterBottom)
	health:SetOrientation("VERTICAL")
	health:SetReverseFill(false)
	health:SetStatusBarTexture(G.media.blank)
	health:SetStatusBarColor(1, 1, 1, 0)
	health:SetMinMaxValues(0, 1)
	health:SetValue(0)
	health.smoothing = Enum.StatusBarInterpolation.Immediate
	health.maximumHealthClampMode = Enum.UnitMaximumHealthMode.Default

	-- 負責裁切的剪刀：數字與框外百分號共用血量水位，裁切範圍向百分號那側延伸。
	local clip = CreateFrame("Frame", nil, health, "DisableUntrustedLayoutScriptsTemplate")
	clip:SetPoint("TOPLEFT", health:GetStatusBarTexture(), "TOPLEFT", (not isPlayer and -size) or 0, 0)
	clip:SetPoint("BOTTOMRIGHT", health:GetStatusBarTexture(), "BOTTOMRIGHT", (isPlayer and size) or 0, 0)
	clip:SetClipsChildren(true)

	-- 治療預估：從當前血量水位開始，只在當前血量上方顯示，滿血時不顯示。
	local healingClip
	if F.GetHankkOption("HealPrediction") then
		local healing = CreateFrame("StatusBar", nil, health, "DisableUntrustedLayoutScriptsTemplate")
		healing:SetSize(width, waterHeight)
		healing:SetPoint("BOTTOMLEFT", health:GetStatusBarTexture(), "TOPLEFT", 0, 0)
		healing:SetOrientation("VERTICAL")
		healing:SetReverseFill(false)
		healing:SetStatusBarTexture(G.media.blank)
		healing:SetStatusBarColor(1, 1, 1, 0)
		healing:SetMinMaxValues(0, 1)
		healing:SetValue(0)

		healingClip = CreateFrame("Frame", nil, healing, "DisableUntrustedLayoutScriptsTemplate")
		healingClip:SetPoint("TOPLEFT", healing:GetStatusBarTexture(), "TOPLEFT", (not isPlayer and -size) or 0, 0)
		healingClip:SetPoint("BOTTOMRIGHT", healing:GetStatusBarTexture(), "BOTTOMRIGHT", (isPlayer and size) or 0, 0)
		healingClip:SetClipsChildren(true)
		healing.Clip = healingClip
		health.HealingAll = healing
		health.incomingHealClampMode = Enum.UnitIncomingHealClampMode.MissingHealth
		health.incomingHealOverflow = 1
	end

	health.Digits = {}
	health.DigitCurves = digitCurves[align]
	health.CropCurves = cropCurves[align]
	health.WidthCurves = widthCurves[align]

	for slot = 1, 3 do
		-- 原生填充範圍就是裁切後的字寬，不需要再計算數字中心的位置。
		local digitWidth = CreateFrame("StatusBar", nil, health, "DisableUntrustedLayoutScriptsTemplate")
		digitWidth:SetSize(width, size)
		digitWidth:SetOrientation("HORIZONTAL")
		digitWidth:SetReverseFill(isPlayer)
		digitWidth:SetStatusBarTexture(G.media.blank)
		digitWidth:SetStatusBarColor(1, 1, 1, 0)
		digitWidth:SetMinMaxValues(0, width)
		digitWidth:SetValue(0)

		local base = health:CreateTexture(nil, "BACKGROUND")
		base:SetAllPoints(digitWidth:GetStatusBarTexture())
		base:SetTexture(G.media.digitbase)
		base:SetTexCoord(blankDigit.texCoords:GetRGBA())

		-- 柔光獨立放在底圖後面；平常染黑，玩家仇恨更新時只改這一層的顏色。
		local glow = health:CreateTexture(nil, "BACKGROUND", nil, -1)
		glow:SetSize(size, size)
		glow:SetPoint("TOP", digitWidth:GetStatusBarTexture(), "TOP", 0, 0)	-- 置中對齊就不需要裁切直接套用
		glow:SetTexture(G.media.digitglow)
		glow:SetSpriteSheetCell(11, 4, 4)
		glow:SetVertexColor(0, 0, 0)
		glow:SetBlendMode("BLEND")

		-- 填色跟隨裁切後的字寬；柔光則保留完整圖格，避免切掉外伸的光暈。
		local fill = clip:CreateTexture(nil, "ARTWORK")
		fill:SetAllPoints(digitWidth:GetStatusBarTexture())
		fill:SetTexture(G.media.digitfill)
		fill:SetTexCoord(blankDigit.texCoords:GetRGBA())
		fill:SetVertexColor(unpack(C.HealthColor))

		local healingFill
		if healingClip then
			healingFill = healingClip:CreateTexture(nil, "ARTWORK")
			healingFill:SetAllPoints(digitWidth:GetStatusBarTexture())
			healingFill:SetTexture(G.media.digitfill)
			healingFill:SetTexCoord(blankDigit.texCoords:GetRGBA())
			healingFill:SetVertexColor(unpack(C.IncomingHealColor))
		end

		health.Digits[slot] = {Base = base, Fill = fill, Healing = healingFill, Glow = glow, Width = digitWidth}
	end

	-- 玩家從右端往左接，目標和焦點從左端往右接；空格字寬為零，不留占位。
	for slot = 1, 3 do
		local digitWidth = health.Digits[slot].Width
		if isPlayer then
			if slot == 3 then
				digitWidth:SetPoint("TOPRIGHT", self, "TOPRIGHT", -sidePadding, 0)
			else
				digitWidth:SetPoint("TOPRIGHT", health.Digits[slot + 1].Width:GetStatusBarTexture(), "TOPLEFT", 0, 0)
			end
		else
			if slot == 1 then
				digitWidth:SetPoint("TOPLEFT", self, "TOPLEFT", sidePadding, 0)
			else
				digitWidth:SetPoint("TOPLEFT", health.Digits[slot - 1].Width:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
			end
		end
	end

	-- [[ 百分號 ]] --

	-- 百分號共用圖格尺寸，固定掛在主框外，不加入點擊範圍，也不參與數字與文字排版，小字比例由材質決定
	local percentBase = health:CreateTexture(nil, "BACKGROUND")
	percentBase:SetSize(size, size)
	percentBase:SetTexture(G.media.digitbase)
	percentBase:SetSpriteSheetCell(G.HealthIconCells.percent, 4, 4)

	local percentY = (230 - 213.4) * scale
	if isPlayer then
		percentBase:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -79 * scale - 8, percentY)
	else
		percentBase:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", (256 - 187) * scale + 8, percentY)
	end

	local percentFill = clip:CreateTexture(nil, "ARTWORK")
	percentFill:SetAllPoints(percentBase)
	percentFill:SetTexture(G.media.digitfill)
	percentFill:SetSpriteSheetCell(G.HealthIconCells.percent, 4, 4)
	percentFill:SetVertexColor(unpack(C.HealthColor))

	local percentHealing
	if healingClip then
		percentHealing = healingClip:CreateTexture(nil, "ARTWORK")
		percentHealing:SetAllPoints(percentBase)
		percentHealing:SetTexture(G.media.digitfill)
		percentHealing:SetSpriteSheetCell(G.HealthIconCells.percent, 4, 4)
		percentHealing:SetVertexColor(unpack(C.IncomingHealColor))
	end

	local percentGlow = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	percentGlow:SetAllPoints(percentBase)
	percentGlow:SetTexture(G.media.digitglow)
	percentGlow:SetSpriteSheetCell(G.HealthIconCells.percent, 4, 4)
	percentGlow:SetVertexColor(0, 0, 0)
	percentGlow:SetBlendMode("BLEND")

	health.Percent = {Base = percentBase, Fill = percentFill, Healing = percentHealing, Glow = percentGlow}

	-- 狀態圖示不裁切水位，排版寬度只用來定位旁邊文字，貼圖本身維持正方形。
	health.Status = {}
	for name, advance in pairs(statusAdvance) do
		local iconWidth = advance * scale
		local start = (isPlayer and width - sidePadding - iconWidth) or sidePadding
		local icon = health:CreateTexture(nil, "ARTWORK")

		icon:SetSize(size, size)
		icon:SetPoint("TOP", self, "TOPLEFT", start + iconWidth / 2, 0)
		icon:SetTexture(G.media.digitbase)
		icon:SetSpriteSheetCell(G.HealthIconCells[name], 4, 4)
		icon.LayoutWidth = iconWidth
		icon:Hide()

		local glow = health:CreateTexture(nil, "BACKGROUND", nil, -1)
		glow:SetAllPoints(icon)
		glow:SetTexture(G.media.digitglow)
		glow:SetSpriteSheetCell(G.HealthIconCells[name], 4, 4)
		glow:SetVertexColor(0, 0, 0)
		glow:SetBlendMode("BLEND")
		glow:Hide()
		icon.Glow = glow

		health.Status[name] = icon
	end

	health.PostUpdate = PostUpdateHealth
	if F.GetHankkOption("ClassColorDigits") then
		health.colorClass = true
		health.PostUpdateColor = PostUpdateHealthColor
	end
	self.Health = health
end

--===================================================--
-- Shared builders / 共用建立函式
--===================================================--

-- 焦點倍率：小型焦點使用 0.7 倍，目標鏈文字使用 0.875 倍。
local smallFocusScale = .7
local smallFocusChainScale = (smallFocusScale * 1.25)
local focusScale, focusChainScale

local function CreateMainShared(self)
	local isPlayer = self.mystyle == "player"
	local align = (isPlayer and "RIGHT") or "LEFT"

	self:SetSize(width, size)
	self:RegisterForClicks("AnyDown", "AnyUp")
	-- 主框體
	CreateHealthDigits(self)

	local health = self.Health
	-- 定位點：數字或狀態圖示變寬時，原生錨點會一起移動。
	local info = CreateFrame("Frame", nil, health, "DisableUntrustedLayoutScriptsTemplate")
	info:SetSize(1, 1)
	local textEdge = health.Digits[(isPlayer and 1) or 3].Width:GetStatusBarTexture()
	info:SetPoint("BOTTOM"..align, textEdge, (isPlayer and "BOTTOMLEFT") or "BOTTOMRIGHT",
		(isPlayer and -textGap) or textGap, waterBottom)
	self.Info = info

	-- Tags

	-- 玩家數值行向左延伸；目標和焦點文字向右延伸。
	local value = F.CreateText(info, G.ValueFS, align)
	value:SetSize(0, G.ValueFS + 4)
	value:SetPoint("BOTTOM"..align, info, "BOTTOM"..align, 0, 0)
	value:SetTextColor(unpack(C.TextColor))
	self.Value = value

	-- 目標和焦點在數值行上方顯示名字。
	if not isPlayer then
		local name = F.CreateText(info, G.NameFS, align)
		name:SetSize(0, G.NameFS + 4)
		name:SetPoint("BOTTOM"..align, info, "BOTTOM"..align, 0, G.ValueFS + 4 + textLineGap)
		name:SetTextColor(unpack(C.TextColor))
		self.Name = name
		self:Tag(name, "[hankk:namecolor]"..G.NameTag.."|r")
	end

	-- 目標和焦點標記放在名字前面；玩家標記由狀態圖示列安排位置。
	local marker = health:CreateTexture(nil, "OVERLAY")
	marker:SetSize(C.RaidIconSize, C.RaidIconSize)
	marker:SetTexture(G.media.raidicon)
	marker:Hide()
	self.RaidTargetIndicator = marker
	if not isPlayer then
		marker:SetPoint("LEFT", info, "BOTTOMLEFT", 0, G.ValueFS + 4 + textLineGap + (G.NameFS + 4) / 2)

		local hasMarker = false
		local function UpdateNameSpacing(shown)
			if hasMarker == shown then return end
			hasMarker = shown
			self.Name:SetPoint("BOTTOMLEFT", info, "BOTTOMLEFT",
				(shown and C.RaidIconSize + textGap) or 0, G.ValueFS + 4 + textLineGap)
		end

		-- 跟隨 oUF 的顯隱呼叫，標記隱藏或停用時收回名字前的空間。
		hooksecurefunc(marker, "Show", function() UpdateNameSpacing(true) end)
		hooksecurefunc(marker, "Hide", function() UpdateNameSpacing(false) end)
	end
end

local function CreateSubShared(self, arrowText)
	local align = (self.mystyle == "pet" and "RIGHT") or "LEFT"

	self:SetSize(C.SubWidth, G.SubFS + 2)
	self:RegisterForClicks("AnyDown", "AnyUp")

	-- Tags
	local name = F.CreateText(self, G.SubFS, align)
	name:SetSize(0, G.SubFS + 2)
	name:SetPoint(align, self, align, 0, 0)
	name:SetTextColor(unpack(C.SubHealthColor))
	self.Name = name

	-- 共用名字的起點：箭頭向左展開，名字向右展開。
	if arrowText then
		local arrow = F.CreateText(self, G.SubFS, "RIGHT")
		arrow:SetSize(G.SubFS, G.SubFS + 2)
		arrow:SetPoint("RIGHT", self, "LEFT", 0, 0)
		arrow:SetTextColor(unpack(C.SubHealthColor))
		arrow:SetText(arrowText)
		self.Arrow = arrow
	end
end

--===================================================--
-- Per-unit styles / 各單位外觀
--===================================================--

local function CreatePlayerStyle(self)
	self.mystyle = "player"

	CreateMainShared(self)
	-- Tags
	self:Tag(self.Value, "[powercolor][hankk:power]|r" .. ((F.GetHankkOption("HidePlayerHealth") and "") or " || [hankk:health]")
		.. ((F.GetHankkOption("Absorb") and "[|cffffff00+$>hankk:absorbs<$|r]") or ""))

	-- Elements
	self.fade = F.GetHankkOption("Fade")

	if F.GetHankkOption("PlayerThreat") then T.CreatePlayerThreatIndicator(self) end
	if F.GetHankkOption("PlayerResources") then T.CreateClassPower(self) end
	T.CreatePlayerStatusIndicators(self)
	if F.GetHankkOption("PlayerTotems") then T.CreateTotemBar(self) end
	-- Castbar
	T.CreateMainCastbar(self)

	local castbar = self.Castbar
	castbar:SetWidth(C.CastbarWidth)
	castbar:SetPoint("LEFT", self, "RIGHT", castbarOffset, 0)
	castbar.IconBG:SetPoint("RIGHT", castbar, "LEFT", -1, 0)
	local nameY = (G.CastbarFS + 4) * .75 -- 施法條法術名上移，中心對齊上緣，時間列接在下方。
	castbar.Text:SetPoint("LEFT", castbar, "LEFT", 3, nameY)
	castbar.Text:SetPoint("RIGHT", castbar, "RIGHT", -3, nameY)
end

local function CreateTargetStyle(self)
	self.mystyle = "target"

	CreateMainShared(self)

	-- Tags
	self:Tag(self.Value, "[hankk:altpower]"..((F.GetHankkOption("TargetLevel") and "[hankk:level]") or "")
		.."[hankk:health]" .. ((F.GetHankkOption("Absorb") and "[|cffffff00+$>hankk:absorbs<$|r]") or "")
		.." || [powercolor][hankk:power]|r")

	-- Elements
	T.CreateTargetAlternativePower(self)
	T.CreateTargetStatusIndicators(self)
	-- Castbar
	T.CreateMainCastbar(self)

	local castbar = self.Castbar
	castbar:SetWidth(C.CastbarWidth)
	castbar:SetPoint("RIGHT", self, "LEFT", -castbarOffset, 0)
	castbar.IconBG:SetPoint("LEFT", castbar, "RIGHT", 1, 0)
	local nameY = (G.CastbarFS + 4) * .75
	castbar.Text:SetPoint("LEFT", castbar, "LEFT", 3, nameY)
	castbar.Text:SetPoint("RIGHT", castbar, "RIGHT", -3, nameY)

	T.CreateTargetAuras(self)
end

local function CreateFocusStyle(self)
	self.mystyle = "focus"

	CreateMainShared(self)

	-- Tags
	self:Tag(self.Value, "[hankk:health]" .. ((F.GetHankkOption("Absorb") and "[|cffffff00+$>hankk:absorbs<$|r]") or "")
		.." || [powercolor][hankk:power]|r")

	-- Elements
	T.CreateTargetStatusIndicators(self)
	-- Castbar
	T.CreateMainCastbar(self)

	local castbar = self.Castbar
	castbar:SetWidth(C.CastbarWidth)
	castbar:SetPoint("RIGHT", self, "LEFT", -castbarOffset, 0)
	castbar.IconBG:SetPoint("LEFT", castbar, "RIGHT", 1, 0)
	castbar.Text:SetPoint("LEFT", castbar, "LEFT", 3, 0)	-- 焦點施法條沒有施法時間，法術名垂直置中。
	castbar.Text:SetPoint("RIGHT", castbar, "RIGHT", -3, 0)

	T.CreateFocusAuras(self, C.Position.FOT[4] * focusChainScale / focusScale)
end

local function CreatePetStyle(self)
	self.mystyle = "pet"

	self.fade = F.GetHankkOption("Fade")
	CreateSubShared(self)

	-- Tags
	local tag = "[perhp]%@[hankk:namecolor]"..G.NameTag.."|r"
	if G.IsForever and UnitClassBase("player") == "HUNTER" then
		tag = "[hankk:pethappiness]" .. tag
	end
	self:Tag(self.Name, tag)
end

local function CreateToTStyle(self)
	self.mystyle = "tot"

	CreateSubShared(self, "›")

	-- Tags
	self:Tag(self.Name, "[hankk:namecolor]"..G.NameTag.."|r @[perhp]"
		..((F.GetHankkOption("CurrentValuesOnly") and "") or "%"))
end

local function CreateToTTStyle(self)
	self.mystyle = "tott"

	CreateSubShared(self, "»")

	-- Tags
	self:Tag(self.Name, "[hankk:namecolor]"..G.NameTag.."|r @[perhp]"
		..((F.GetHankkOption("CurrentValuesOnly") and "") or "%"))
end

local function CreateFoTStyle(self)
	self.mystyle = "fot"

	CreateSubShared(self, "›")

	-- Tags
	self:Tag(self.Name, "[hankk:namecolor]"..G.NameTag.."|r @[perhp]"
		..((F.GetHankkOption("CurrentValuesOnly") and "") or "%"))
end

local function CreateFoTTStyle(self)
	self.mystyle = "fott"

	CreateSubShared(self, "»")

	-- Tags
	self:Tag(self.Name, "[hankk:namecolor]"..G.NameTag.."|r @[perhp]"
		..((F.GetHankkOption("CurrentValuesOnly") and "") or "%"))
end

--===================================================--
-- Spawn / 建立單位框體
--===================================================--

oUF:Factory(function(self)
	self:RegisterStyle("HankkPlayer", CreatePlayerStyle)
	self:RegisterStyle("HankkTarget", CreateTargetStyle)
	self:RegisterStyle("HankkFocus", CreateFocusStyle)
	self:RegisterStyle("HankkPet", CreatePetStyle)
	self:RegisterStyle("HankkToT", CreateToTStyle)
	self:RegisterStyle("HankkToTT", CreateToTTStyle)
	self:RegisterStyle("HankkFoT", CreateFoTStyle)
	self:RegisterStyle("HankkFoTT", CreateFoTTStyle)

	self:SetActiveStyle("HankkPlayer")
	local player = self:Spawn("player", "oUF_HankkPlayer")
	local playerAnchor = T.CreatePositionAnchor("Player", width, size,
		{point = "CENTER", x = -220 - width / 2, y = -180})
	player:SetPoint("CENTER", playerAnchor, "CENTER", 0, 0)

	self:SetActiveStyle("HankkTarget")
	local target = self:Spawn("target", "oUF_HankkTarget")
	local targetAnchor = T.CreatePositionAnchor("Target", width, size,
		{point = "CENTER", x = 220 + width / 2, y = -180})
	target:SetPoint("CENTER", targetAnchor, "CENTER", 0, 0)

	self:SetActiveStyle("HankkPet")
	local pet = self:Spawn("pet", "oUF_HankkPet")
	pet:SetPoint(unpack(C.Position.Pet))
	T.LinkTotemsToPet(player, pet)

	self:SetActiveStyle("HankkToT")
	local targettarget = self:Spawn("targettarget", "oUF_HankkToT")
	targettarget:SetPoint(unpack(C.Position.TOT))

	self:SetActiveStyle("HankkToTT")
	local targettargettarget = self:Spawn("targettargettarget", "oUF_HankkToTT")
	targettargettarget:SetPoint(unpack(C.Position.TOTT))

	-- 焦點生成前獲取縮放倍率。
	focusScale = (F.GetHankkOption("SmallFocus") and smallFocusScale) or 1
	focusChainScale = (focusScale < 1 and smallFocusChainScale) or 1
	self:SetActiveStyle("HankkFocus")
	local focus = self:Spawn("focus", "oUF_HankkFocus")
	focus:SetScale(focusScale)
	-- 預設座標以小型布局為基準，錨點為框架中心，完整尺寸會四面等比增大，因此把焦點下移相同距離，讓焦點高度保持原位。
	local focusY = -270
	if focusScale == 1 then
		local focusTopIncrease = size * (1 - smallFocusScale) / 2
		local chainAreaHeight = 2 * (G.SubFS + 2) + C.Position.FOT[5]
		local chainTopIncrease = chainAreaHeight * (1 - smallFocusChainScale)
		focusY = focusY - focusTopIncrease - chainTopIncrease
	end
	-- 定位框不縮放，使用畫面座標；焦點自身保留較小尺寸與原有內部布局。
	local focusAnchor = T.CreatePositionAnchor("Focus", width * focusScale, size * focusScale,
		{point = "CENTER", x = 0, y = focusY})
	focus:SetPoint("CENTER", focusAnchor, "CENTER", 0, 0)

	self:SetActiveStyle("HankkFoT")
	local focustarget = self:Spawn("focustarget", "oUF_HankkFoT")
	focustarget:SetScale(focusChainScale)
	focustarget:SetPoint(unpack(C.Position.FOT))

	self:SetActiveStyle("HankkFoTT")
	local focustargettarget = self:Spawn("focustargettarget", "oUF_HankkFoTT")
	focustargettarget:SetScale(focusChainScale)
	focustargettarget:SetPoint(unpack(C.Position.FOTT))
end)
