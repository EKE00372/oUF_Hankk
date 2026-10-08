local _, ns = ...
local C, F, G, T = ns[1], ns[2], ns[3], ns[4]

-- Credits: NDui totmebar
-- 保留原生按鈕處理提示與右鍵取消，不使用只顯示狀態的 oUF Totems。

local function SortTotemButtons(a, b)
	return a.layoutIndex < b.layoutIndex
end

T.CreateTotemBar = function(self)
	local nativeFrame = TotemFrame
	if not nativeFrame or not nativeFrame.totemPool then return end

	-- 圖騰使用固定的時間後綴，不用冷卻倒數的本地化單位。
	local roundDown = Enum.NumericRuleFormatRounding.Down
	local durationFormatter = C_StringUtil.CreateNumericRuleFormatter()
	durationFormatter:SetBreakpoints({
		{threshold = 0, step = 1, rounding = roundDown, format = "%d"},
		{threshold = 60, format = "%dm", components = {{div = 60, step = 1, rounding = roundDown}}},
	})

	-- 共用光環大小；等寵物框建立後，再統一設定整列位置。
	local size, spacing = C.AuraSize+4, C.AuraSpacing
	local bar = CreateFrame("Frame", nil, self)
	bar:SetSize(size * MAX_TOTEMS + spacing * (MAX_TOTEMS - 1), size)
	bar:Hide()
	self.HankkTotems = bar

	-- 固定位置只建立一次；原生按鈕重用時，才重新掛到對應圖示。
	for index = 1, MAX_TOTEMS do
		local totem = CreateFrame("Frame", nil, bar)
		totem:SetSize(size, size)
		if index == 1 then
			totem:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
		else
			totem:SetPoint("RIGHT", bar[index - 1], "LEFT", -spacing, 0)
		end
		-- 與光環圖示相同：細暗邊框，加上同一張柔陰影材質。
		local border = totem:CreateTexture(nil, "BACKGROUND", nil, -1)
		border:SetPoint("TOPLEFT", totem, "TOPLEFT", -1, 1)
		border:SetPoint("BOTTOMRIGHT", totem, "BOTTOMRIGHT", 1, -1)
		border:SetColorTexture(1, 1, 1, 1)
		border:SetVertexColor(.1, .1, .1, 1)
		totem.Border = border
		local shadow = totem:CreateTexture(nil, "BACKGROUND", nil, -2)
		shadow:SetPoint("TOPLEFT", totem, "TOPLEFT", -4, 4)
		shadow:SetPoint("BOTTOMRIGHT", totem, "BOTTOMRIGHT", 4, -4)
		shadow:SetTexture(G.media.aurashadow)
		shadow:SetVertexColor(0, 0, 0, 1)
		totem.Shadow = shadow
		local icon = totem:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(totem)
		icon:SetTexCoord(.08, .92, .08, .92)
		totem.Icon = icon

		-- 圖騰自己的時間文字，由遊戲直接更新倒數。
		local text = F.CreateText(totem, G.AuraFS, "CENTER", G.AuraFontFlag)
		text:SetPoint("TOP", totem, "TOP", 0, 4)
		text:SetTextColor(unpack(C.TextColor))
		text.binding = C_DurationUtil.CreateDurationTextBinding()
		text.binding:SetFontString(text)
		text.binding:SetFormatter(durationFormatter)
		text.binding:SetExpiredText("")
		text.binding:SetZeroDurationText("")
		text.binding:SetEnabled(false)
		totem.Time = text
		totem:Hide()
		bar[index] = totem
	end

	local active = {}
	local function UpdateTotemBar()
		wipe(active)
		-- 依原生按鈕的顯示狀態與固定順序排列圖騰。
		-- 圖示內容和剩餘時間仍交給暴雪處理。
		for button in nativeFrame.totemPool:EnumerateActive() do
			if button:IsShown() then active[#active + 1] = button end
		end
		table.sort(active, SortTotemButtons)
		for index = 1, MAX_TOTEMS do
			local totem, button = bar[index], active[index]
			if button then
				totem.Icon:SetTexture(button.Icon.Texture:GetTexture())
				totem.Time.binding:SetDuration(GetTotemDuration(button.slot))
				totem.Time.binding:SetEnabled(true)
				totem:Show()

				-- 原生外觀透明；每個圖示仍由各自原生按鈕處理點擊，不改原生腳本。
				button:ClearAllPoints()
				button:SetParent(totem)
				button:SetAllPoints(totem)
				button:SetAlpha(0)
				button:SetFrameLevel(totem:GetFrameLevel() + 3)
				button:EnableMouse(true)
			else
				totem.Icon:SetTexture(nil)
				totem.Time.binding:SetEnabled(false)
				totem.Time:SetText("")
				totem:Hide()
			end
		end
		bar:SetShown(#active > 0)
	end

	-- 事件、按鈕池及取消規則都交給暴雪，不另建計時器或事件循環。
	hooksecurefunc(nativeFrame, "Update", UpdateTotemBar)
	UpdateTotemBar()
end

-- 跟隨既有寵物框的顯示控制，也涵蓋載具與顯示／隱藏切換。
T.LinkTotemsToPet = function(self, pet)
	local bar = self.HankkTotems
	if not bar then return end
	local hasPet
	local function UpdatePosition(shown)
		if hasPet == shown then return end
		hasPet = shown
		bar:ClearAllPoints()
		if shown then
			-- 寵物文字上方留 4 單位給圖示陰影，再留 1 單位空隙。
			-- 直接對齊寵物右端，不再加減水平偏移。
			bar:SetPoint("BOTTOMRIGHT", pet, "TOPRIGHT", 0, 5)
		else
			bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -24, 0)
		end
	end
	-- 從顯隱 callback 傳入固定狀態，不讀寵物的受限文字、可見性或座標。
	pet:HookScript("OnShow", function() UpdatePosition(true) end)
	pet:HookScript("OnHide", function() UpdatePosition(false) end)
	-- 公開的目前單位也能處理 /reload 時已在載具中的情況。
	UpdatePosition(UnitExists(pet.__unit))
end
