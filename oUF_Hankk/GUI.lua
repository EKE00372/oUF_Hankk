local addon, ns = ...
local C, F, G, L = ns[1], ns[2], ns[3], ns[5]

local MainFrame
local THEME_R, THEME_G, THEME_B = unpack(C.HealthColor)
local PANEL_ALPHA, BUTTON_ALPHA = .82, .35
local COLUMN_WIDTH, COLUMN_GAP = 224, 20
local ROW_HEIGHT = 28

local function CreateText(parent, text, size, justify)
	local label = F.CreateText(parent, size or 14, justify or "LEFT")
	label:SetText(text)
	return label
end

local function SetPanelBackdrop(frame, alpha)
	frame:SetBackdrop({
		bgFile = G.media.blank, edgeFile = G.media.blank, edgeSize = 1,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	frame:SetBackdropColor(0, 0, 0, alpha)
	frame:SetBackdropBorderColor(THEME_R, THEME_G, THEME_B, 1)
end

local function CreateBreathGlow(parent)
	local glow = F.CreateSD(parent, parent, 12, THEME_R, THEME_G, THEME_B, .65)
	glow:SetAlpha(.25)
	local animation = glow:CreateAnimationGroup()
	animation:SetLooping("REPEAT")
	for index, values in ipairs({{.25, .75, 5}, {.75, .25, 7}}) do
		local fade = animation:CreateAnimation("Alpha")
		fade:SetFromAlpha(values[1])
		fade:SetToAlpha(values[2])
		fade:SetDuration(values[3])
		fade:SetSmoothing("IN_OUT")
		fade:SetOrder(index)
	end

	-- 視窗關閉時停止裝飾動畫。
	parent:SetScript("OnShow", function() animation:Play() end)
	parent:SetScript("OnHide", function()
		animation:Stop()
		parent.InfoTooltip:Hide()
	end)
end

local function CreateButton(parent, width, text)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width, 26)
	SetPanelBackdrop(button, BUTTON_ALPHA)
	button.Text = CreateText(button, text, 14, "CENTER")
	button.Text:SetPoint("CENTER")
	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(THEME_R * .3, THEME_G * .3, THEME_B * .3, .65)
	end)
	button:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, BUTTON_ALPHA) end)
	return button
end

local function RefreshOptions()
	local changed = false
	for _, row in ipairs(MainFrame.OptionRows) do
		local option = row.Option
		local value = F.GetSavedHankkOption(option.key)
		row.Check:SetChecked(value)
		if value ~= F.GetHankkOption(option.key) then changed = true end
	end
	MainFrame.StatusText:SetText((changed and L.Saved) or L.Unchanged)
end

local function CreateInfoTooltip(parent, text)
	local icon = CreateFrame("Button", nil, parent)
	icon:SetSize(16, 16)
	local texture = icon:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints()
	texture:SetTexture(G.media.info)
	icon:SetHighlightTexture(G.media.info)
	icon:SetScript("OnEnter", function(self)
		local tooltip = MainFrame.InfoTooltip
		tooltip:ClearLines()
		tooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
		tooltip:AddLine(L[text], 1, 1, 1, true)
		local label = tooltip.TextLeft1
		F.SetTextFont(label, 12, "LEFT")
		label:SetWordWrap(true)
		tooltip:Show()
	end)
	icon:SetScript("OnLeave", function() MainFrame.InfoTooltip:Hide() end)
	return icon
end

local function CreateOption(parent, option, x, y)
	local row = CreateFrame("Button", nil, parent)
	row:SetSize(COLUMN_WIDTH, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", x, y)
	row.Option = option

	local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	check:SetSize(26, 26)
	check:SetPoint("TOPLEFT", -3, 0)
	check:GetCheckedTexture():SetVertexColor(THEME_R, THEME_G, THEME_B)
	row.Check = check

	local label = CreateText(row, L[option.key])
	label:SetPoint("TOPLEFT", 28, -6)
	if option.tooltip then
		row.Info = CreateInfoTooltip(row, option.tooltip)
		row.Info:SetPoint("LEFT", label, "RIGHT", 4, 2)
	else
		label:SetWidth(COLUMN_WIDTH - 28)
	end
	local function Save(value)
		F.SetHankkOption(option.key, value)
		RefreshOptions()
	end
	check:SetScript("OnClick", function(self) Save(self:GetChecked() == true) end)
	row:SetScript("OnClick", function() Save(not F.GetSavedHankkOption(option.key)) end)
	table.insert(MainFrame.OptionRows, row)
end

-- 底部兩個按鈕共用重載與戰鬥檢查。
local function RequestReload()
	if InCombatLockdown() then MainFrame.StatusText:SetText(L.Combat); return end
	ReloadUI()
end

local function BuildGUI()
	MainFrame = CreateFrame("Frame", "oUF_HankkGUI", UIParent, "BackdropTemplate")
	table.insert(UISpecialFrames, MainFrame:GetName())
	MainFrame:SetFrameStrata("DIALOG")
	MainFrame:SetSize(520, 420)
	MainFrame:SetPoint("CENTER")
	MainFrame:SetMovable(true)
	MainFrame:EnableMouse(true)
	MainFrame:RegisterForDrag("LeftButton")
	MainFrame:SetClampedToScreen(true)
	MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
	MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
	SetPanelBackdrop(MainFrame, PANEL_ALPHA)
	MainFrame.InfoTooltip = CreateFrame("GameTooltip", "oUF_HankkInfoTooltip", MainFrame, "GameTooltipTemplate")
	MainFrame.InfoTooltip:SetFrameStrata("TOOLTIP")
	MainFrame.InfoTooltip:Hide()
	CreateBreathGlow(MainFrame)

	local version = C_AddOns.GetAddOnMetadata(addon, "Version") or ""
	local title = CreateText(MainFrame, "oUF_Hankk "..version, 20, "CENTER")
	title:SetPoint("TOP", 0, 14)
	title:SetTextColor(THEME_R, THEME_G, THEME_B)
	MainFrame.OptionRows = {}

	-- 單頁兩欄；說明放在資訊圖示的提示框。
	local y = -30
	for _, section in ipairs(F.GUIOptionSections) do
		local heading = CreateText(MainFrame, L[section.name], 16)
		heading:SetPoint("TOPLEFT", 26, y)
		heading:SetTextColor(THEME_R, THEME_G, THEME_B)
		y = y - 26
		local column = 0
		for _, option in ipairs(section.options) do
			if F.IsHankkOptionAvailable(option) then
				CreateOption(MainFrame, option, 26 + column * (COLUMN_WIDTH + COLUMN_GAP), y)
				column = 1 - column
				if column == 0 then y = y - ROW_HEIGHT end
			end
		end
		if column == 1 then y = y - ROW_HEIGHT end
		y = y - 10
	end

	MainFrame.StatusText = CreateText(MainFrame, "", 12, "LEFT")
	MainFrame.StatusText:SetTextColor(THEME_R, THEME_G, THEME_B)

	local close = CreateButton(MainFrame, 24, "X")
	close:SetPoint("TOPRIGHT", -12, -12)
	close:SetScript("OnClick", function() MainFrame:Hide() end)

	local reload = CreateButton(MainFrame, 128, L.Reload)
	reload:SetPoint("BOTTOMRIGHT", -26, 20)
	reload:SetScript("OnClick", RequestReload)

	local reset = CreateButton(MainFrame, 128, L.Reset)
	reset:SetPoint("RIGHT", reload, "LEFT", -12, 0)
	MainFrame.StatusText:SetPoint("LEFT", MainFrame, "BOTTOMLEFT", 26, 33)
	MainFrame.StatusText:SetPoint("RIGHT", reset, "LEFT", -12, 0)
	reset:SetScript("OnClick", function()
		F.ResetHankkOptions()
		RefreshOptions()
		RequestReload()
	end)
	MainFrame:Hide()
end

F.CreateHankkGUI = function()
	if not MainFrame then BuildGUI() end
	RefreshOptions()
	MainFrame:SetShown(not MainFrame:IsShown())
end

SlashCmdList["OUFHANKK"] = F.CreateHankkGUI
SLASH_OUFHANKK1 = "/hankk"
SLASH_OUFHANKK2 = "/hank"
