local _, ns = ...
local C, F, G, T = unpack(ns)

--===================================================--
-- Time and colors / 時間與顏色
--===================================================--

local normalColor = CreateColor(unpack(C.CastNormal))
local shieldColor = CreateColor(unpack(C.CastShield))
local failedColor = CreateColor(unpack(C.CastFailed))
local timeFormatter

local function UpdateColor(element, unit, spellID, notInterruptible)
	if element.isPlayerCastbar then
		element:SetStatusBarColor(normalColor:GetRGBA())
	else
		element:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible, shieldColor, normalColor)
	end
end

local function PostCastStart(element, unit, spellID, notInterruptible)
	UpdateColor(element, unit, spellID, notInterruptible)
	if element.Time then element.Time.binding:SetEnabled(true) end
	if element.SafeZone then
		local showLatency = (unit == "player")
		element.SafeZone:SetShown(showLatency)
		element.Latency:SetShown(showLatency)
		if showLatency then
			element.Latency:SetFormattedText("%dms", select(4, GetNetStats()))
		end
	end
end

local function PostCastFailed(element)
	element:SetStatusBarColor(failedColor:GetRGBA())
	-- 施法已結束，失敗文字旁邊不再繼續倒數。
	if element.Time then
		element.Time.binding:SetEnabled(false)
		element.Time:SetText("")
	end
	if element.SafeZone then
		element.SafeZone:Hide()
		element.Latency:Hide()
	end
end

local function PostCastInterrupted(element, unit, spellID, interruptedBy)
	PostCastFailed(element)

	local name = UnitNameFromGUID(interruptedBy)
	local _, class = UnitClassFromGUID(interruptedBy)

	if class then
		local color = C_ClassColor.GetClassColor(class)
		if color then name = C_ColorUtil.WrapTextInColor(name, color) end
	end

	element.Text:SetFormattedText(SPELL_INTERRUPTED_BY, name)
end

--===================================================--
-- Shared callbacks / 共用回呼
--===================================================--

-- 一般施法文字靠左、引導文字靠右。
local function UpdateTextAlignment(element, duration, interpolation, direction)
	local align = (direction == Enum.StatusBarTimerDirection.RemainingTime and "RIGHT") or "LEFT"
	element.Text:SetJustifyH(align)
	if element.Time then element.Time:SetJustifyH(align) end
end

--===================================================--
-- Player, target and focus / 玩家、目標與專注
--===================================================--

local function CreateBD(bar)
	local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
	border:SetFrameLevel(bar:GetFrameLevel() - 2)
	border:SetBackdrop({bgFile = G.media.blank, edgeFile = G.media.blank, edgeSize = 1})
	border:SetBackdropColor(.15, .15, .15, .6)
	border:SetBackdropBorderColor(.15, .15, .15, 1)
	
	return border
end

T.CreateMainCastbar = function(self)
	local height = (G.CastbarFS + 4) * 1.5
	
	local bar = CreateFrame("StatusBar", nil, self)
	bar:SetFrameLevel(self:GetFrameLevel() + 4)
	bar:SetOrientation("HORIZONTAL")
	bar:SetReverseFill(false)
	bar:SetStatusBarTexture(G.media.blank)
	bar:SetStatusBarColor(normalColor:GetRGBA())
	bar.isPlayerCastbar = (self.mystyle == "player")
	bar:SetHeight(height)
	bar.BarBG = CreateBD(bar)
	bar.BarShadow = F.CreateSD(bar, bar, 4)

	-- 圖示疊在進度條上方，保留完整陰影，也遮住接縫處的條身陰影。
	local iconBG = CreateFrame("Frame", nil, bar)
	bar.IconBG = iconBG
	iconBG:SetFrameLevel(bar:GetFrameLevel() + 2)
	iconBG:SetSize((G.CastbarFS + 4)*2, (G.CastbarFS + 4)*2)
	local iconBorder = iconBG:CreateTexture(nil, "ARTWORK")
	iconBorder:SetPoint("TOPLEFT", iconBG, "TOPLEFT", -1, 1)
	iconBorder:SetPoint("BOTTOMRIGHT", iconBG, "BOTTOMRIGHT", 1, -1)
	iconBorder:SetTexture(G.media.blank)
	iconBorder:SetVertexColor(.15, .15, .15, 1)
	bar.IconBorder = iconBorder
	bar.Icon = iconBG:CreateTexture(nil, "OVERLAY", nil, 1)
	bar.Icon:SetAllPoints(iconBG)
	bar.Icon:SetTexCoord(.08, .92, .08, .92)
	bar.Shadow = F.CreateSD(iconBG, iconBorder, 5, 0, 0, 0)

	bar.Spark = bar:CreateTexture(nil, "OVERLAY", nil, -1)
	bar.Spark:SetTexture(G.media.spark)
	bar.Spark:SetBlendMode("ADD")
	bar.Spark:SetVertexColor(1, 1, .85, .5)
	bar.Spark:SetAlpha(.5)
	bar.Spark:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
	bar.Spark:SetSize(height, height)

	bar.Text = F.CreateText(bar, G.CastbarFS, "LEFT")
	bar.Text:SetTextColor(unpack(C.TextColor))
	bar.Text:SetHeight(G.CastbarFS + 2)
	hooksecurefunc(bar, "SetTimerDuration", UpdateTextAlignment)

	-- 專注只顯示法術名；玩家和目標另顯示時間，並共用相同格式。
	if self.mystyle ~= "focus" then
		if not timeFormatter then
			timeFormatter = C_StringUtil.CreateNumericRuleFormatter()
			timeFormatter:SetBreakpoints({{threshold = 0, format = "%.1f"}})
		end

		bar.Time = F.CreateText(bar, G.CastbarFS, "LEFT")
		bar.Time:SetHeight(G.CastbarFS + 2)
		bar.Time:SetPoint("TOPLEFT", bar.Text, "BOTTOMLEFT", 0, -2)
		bar.Time:SetPoint("TOPRIGHT", bar.Text, "BOTTOMRIGHT", 0, -2)
		bar.Time:SetTextColor(unpack(C.TextColor))

		bar.Time.binding = C_DurationUtil.CreateDurationTextBinding()
		bar.Time.binding:SetTextFormat("{} / {}", {
			{property = Enum.DurationTextBindingProperty.RemainingDuration, formatter = timeFormatter},
			{property = Enum.DurationTextBindingProperty.TotalDuration, formatter = timeFormatter},
		})
	end

	if self.mystyle == "player" then
		bar.SafeZone = bar:CreateTexture(nil, "OVERLAY", nil, -2)
		bar.SafeZone:SetColorTexture(unpack(C.CastFailed))
		bar.SafeZone:SetAlpha(.6)

		bar.Latency = F.CreateText(bar, G.CastbarFS / 2, "CENTER")
		bar.Latency:SetPoint("BOTTOM", bar.SafeZone, "BOTTOM", 0, 0)
		bar.Latency:SetTextColor(.7, .7, .7, .8)
	end

	bar.timeToHold = 0.5
	bar.PostCastStart = PostCastStart
	bar.PostCastInterruptible = UpdateColor
	bar.PostCastFail = PostCastFailed
	bar.PostCastInterrupted = PostCastInterrupted
	self.Castbar = bar
end

--===================================================--
-- Boss and arena / 首領與競技場
--===================================================--

T.CreateOtherCastbar = function(self, width, height, anchor)
	local border = 1

	local bar = CreateFrame("StatusBar", nil, self)
	bar:SetFrameLevel(self:GetFrameLevel() + 7)
	bar:SetOrientation("HORIZONTAL")
	bar:SetReverseFill(false)
	bar:SetStatusBarTexture(G.media.blank)
	bar:SetStatusBarColor(normalColor:GetRGBA())
	-- 條與圖示本體等高，共用外框，中間只留一道分隔線。
	bar:SetSize(width - height - border * 3, height)

	local iconBG = CreateFrame("Frame", nil, bar)
	bar.IconBG = iconBG
	iconBG:SetSize(height, height)
	iconBG:SetPoint("LEFT", bar, "RIGHT", border, 0)
	local iconBorder = iconBG:CreateTexture(nil, "ARTWORK")
	iconBorder:SetPoint("TOPLEFT", iconBG, "TOPLEFT", -1, 1)
	iconBorder:SetPoint("BOTTOMRIGHT", iconBG, "BOTTOMRIGHT", 1, -1)
	iconBorder:SetTexture(G.media.blank)
	iconBorder:SetVertexColor(.15, .15, .15, 1)
	bar.IconBorder = iconBorder
	bar.Icon = iconBG:CreateTexture(nil, "OVERLAY", nil, 1)
	bar.Icon:SetAllPoints(iconBG)
	bar.Icon:SetTexCoord(.08, .92, .08, .92)

	bar.Spark = bar:CreateTexture(nil, "OVERLAY", nil, -1)
	bar.Spark:SetTexture(G.media.spark)
	bar.Spark:SetBlendMode("ADD")
	bar.Spark:SetVertexColor(1, 1, .85, .5)
	bar.Spark:SetAlpha(.5)
	bar.Spark:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
	bar.Spark:SetSize(height, height)

	-- 施法名稱字級比條身高度小 4，讓文字上下留出空間。
	bar.Text = F.CreateText(bar, height - 2, "LEFT")
	bar.Text:SetTextColor(unpack(C.TextColor))
	bar.Text:SetHeight(height)
	bar.Text:SetPoint("LEFT", bar, "LEFT", 3, 0)
	bar.Text:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
	hooksecurefunc(bar, "SetTimerDuration", UpdateTextAlignment)

	-- 施法條與圖示共用外框，整組對齊名字區的中心。
	local background = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	background:SetSize(width, height + border * 2)
	background:SetPoint("CENTER", anchor, "CENTER", 0, 0)
	background:SetFrameLevel(bar:GetFrameLevel() - 2)
	background:SetBackdrop({bgFile = G.media.blank, edgeFile = G.media.blank, edgeSize = border})
	background:SetBackdropColor(.15, .15, .15, .6)
	background:SetBackdropBorderColor(.15, .15, .15, 1)
	bar.BarBG = background
	-- 陰影只繞整組外側，不穿過圖示與施法條的接縫。
	bar.BarShadow = F.CreateSD(bar, background, 4)

	-- 失敗提示停留時也遮住名字；oUF 收起施法條後才恢復，不另加計時器。
	bar:HookScript("OnShow", function() self.Name:SetAlpha(0) end)
	bar:HookScript("OnHide", function() self.Name:SetAlpha(1) end)

	bar.timeToHold = 0.5
	bar.PostCastStart = PostCastStart
	bar.PostCastInterruptible = UpdateColor
	bar.PostCastFail = PostCastFailed
	bar.PostCastInterrupted = PostCastInterrupted
	self.Castbar = bar
end
