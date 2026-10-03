local _, ns = ...
local C, F, G, T, L = unpack(ns)
local movers, positions = {}, nil
local labels = {Player = L.EditModePlayer, Target = L.EditModeTarget, Focus = L.EditModeFocus,
	Party = L.Party, Boss = L.Boss, Arena = L.Arena}

-- 拖曳結束就保存，不參與暴雪布局的儲存、還原或切換。
local function FinishDrag(mover)
	if not mover.dragging or InCombatLockdown() then return end
	local anchor = mover.anchor
	anchor:StopMovingOrSizing()
	mover.dragging = nil
	local point, _, relativePoint, x, y = anchor:GetPoint()
	positions[mover.positionKey] = {point = point, relativePoint = relativePoint, x = x, y = y}
end

-- 跟隨編輯模式視窗；切到快捷鍵設定或進入戰鬥時收起。
local function UpdateMovers()
	local editing = EditModeManagerFrame:IsShown() and not InCombatLockdown()
	for _, mover in pairs(movers) do
		-- 拖曳途中進戰鬥時，離戰後才執行收尾與保存。
		FinishDrag(mover)
		mover:SetShown(editing)
	end
end

EditModeManagerFrame:HookScript("OnShow", UpdateMovers)
EditModeManagerFrame:HookScript("OnHide", UpdateMovers)
local combat = CreateFrame("Frame")
combat:RegisterEvent("PLAYER_REGEN_DISABLED")
combat:RegisterEvent("PLAYER_REGEN_ENABLED")
combat:SetScript("OnEvent", UpdateMovers)

-- 各組只有一個公開定位框；沒有對應單位或玩家淡出時，仍可在編輯模式移動。
-- 只改整組位置，不改單位顯隱、點擊範圍或內部布局。
T.CreatePositionAnchor = function(key, width, height, defaultPosition)
	if not positions then
		HankkDB.Positions = HankkDB.Positions or {}
		positions = HankkDB.Positions
	end

	local anchor = CreateFrame("Frame", "oUF_Hankk"..key.."Anchor", UIParent)
	anchor:SetSize(width, height)
	anchor:SetMovable(true)
	anchor:SetClampedToScreen(true)
	anchor:SetDontSavePosition(true)

	local position = positions[key] or defaultPosition
	anchor:SetPoint(position.point, UIParent, position.relativePoint or position.point, position.x, position.y)

	-- 移動框獨立於單位框，平時隱藏，不攔截單位框的滑鼠操作。
	local mover = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	mover:SetAllPoints(anchor)
	mover:SetFrameStrata("DIALOG")
	mover:SetBackdrop({bgFile = G.media.blank, edgeFile = G.media.blank, edgeSize = 1})
	mover:SetBackdropColor(.1, .1, .1, .65)
	mover:SetBackdropBorderColor(unpack(C.HealthColor))
	mover.anchor, mover.positionKey = anchor, key
	mover.defaultPosition = defaultPosition
	movers[key] = mover

	-- 首領與競技場的預設位置重疊，拖曳標籤分放上緣左右，兩組都能直接選到。
	local handle = mover
	if key == "Boss" or key == "Arena" then
		mover:EnableMouse(false)
		handle = CreateFrame("Frame", nil, mover, "BackdropTemplate")
		handle:SetSize(width / 2, G.SubFS + 8)
		
		local side = (key == "Boss" and "LEFT") or "RIGHT"
		handle:SetPoint("BOTTOM"..side, mover, "TOP"..side, 0, 0)
		handle:SetBackdrop({bgFile = G.media.blank, edgeFile = G.media.blank, edgeSize = 1})
		handle:SetBackdropColor(.1, .1, .1, .9)
		handle:SetBackdropBorderColor(unpack(C.HealthColor))
	end
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")

	local label = F.CreateText(handle, G.SubFS, "CENTER")
	label:SetPoint("CENTER")
	label:SetText(labels[key])

	handle:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		anchor:StartMoving()
		mover.dragging = true
	end)
	handle:SetScript("OnDragStop", function() FinishDrag(mover) end)
	mover:SetScript("OnHide", FinishDrag)

	handle:SetScript("OnMouseUp", function(self, button)
		if button ~= "RightButton" or InCombatLockdown() then return end
		FinishDrag(mover)
		local default = mover.defaultPosition
		anchor:ClearAllPoints()
		anchor:SetPoint(default.point, UIParent, default.point, default.x, default.y)
		positions[key] = nil
	end)

	handle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("oUF_Hankk: "..labels[key])
		GameTooltip:AddLine(string.format(L.EditModeMoveHint, G.LeftButton, G.RightButton), 1, 1, 1)
		GameTooltip:Show()
	end)
	handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
	mover:SetShown(EditModeManagerFrame:IsShown() and not InCombatLockdown())

	return anchor
end
