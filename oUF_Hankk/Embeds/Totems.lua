local _, ns = ...
local C, F, G, T = ns[1], ns[2], ns[3], ns[4]

-- Credits: NDui totmebar
-- Keep native buttons for tooltips and right-click dismissal, not oUF's read-only Totems.
-- 保留原生按鈕處理提示與右鍵取消，不使用只顯示狀態的 oUF Totems。

local function SortTotemButtons(a, b)
	return a.layoutIndex < b.layoutIndex
end

T.CreateTotemBar = function(self)
	local nativeFrame = TotemFrame
	if self.HankkTotems or not nativeFrame or not nativeFrame.totemPool then return end

	-- Share aura sizes and align to the digits, excluding the percent sign.
	-- 共用光環大小，並對齊數字右端，不含百分號。
	local size, spacing = C.TargetAuraSize, C.TargetAuraSpacing
	local bar = CreateFrame("Frame", nil, self)
	bar:SetSize(size * MAX_TOTEMS + spacing * (MAX_TOTEMS - 1), size)
	bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", self.DigitRightOffset, 0)
	bar:Hide()
	self.HankkTotems = bar

	-- Build fixed positions once; only native button ownership changes on pool reuse.
	-- 固定位置只建立一次；原生按鈕重用時，才重新掛到對應圖示。
	for index = 1, MAX_TOTEMS do
		local totem = CreateFrame("Frame", nil, bar)
		totem:SetSize(size, size)
		if index == 1 then
			totem:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
		else
			totem:SetPoint("RIGHT", bar[index - 1], "LEFT", -spacing, 0)
		end
		-- Match aura icons: a thin dark border and the same soft shadow texture.
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

		local cooldown = CreateFrame("Cooldown", nil, totem, "CooldownFrameTemplate")
		cooldown:SetAllPoints(totem)
		-- Auras show time without a dark swipe; retain native cooldown text updates.
		-- 光環只顯示時間，不蓋冷卻黑影；倒數仍由原生元件更新。
		cooldown:SetDrawSwipe(false)
		cooldown:SetDrawEdge(false)
		cooldown:SetDrawBling(false)
		cooldown:SetHideCountdownNumbers(false)
		local text = cooldown:GetCountdownFontString()
		F.SetTextFont(text, G.AuraFS)
		text:ClearAllPoints()
		text:SetPoint("TOP", totem, "TOP", 0, 4)
		text:SetJustifyH("CENTER")
		text:SetTextColor(unpack(C.TextColor))
		totem.Cooldown = cooldown
		totem:Hide()
		bar[index] = totem
	end

	local active = {}
	local function UpdateTotemBar()
		wipe(active)
		-- Only these native buttons use ordinary Show/Hide and public slot/layoutIndex.
		-- 只讀這組以普通 Show/Hide 更新的原生按鈕；slot 與 layoutIndex 來自公開固定迴圈。
		-- Do not test GetTotemInfo, read remaining time, or inspect the icon payload.
		-- 不判斷 GetTotemInfo、不讀剩餘秒數，也不檢查圖示內容。
		for button in nativeFrame.totemPool:EnumerateActive() do
			if button:IsShown() then active[#active + 1] = button end
		end
		table.sort(active, SortTotemButtons)
		for index = 1, MAX_TOTEMS do
			local totem, button = bar[index], active[index]
			if button then
				totem.Icon:SetTexture(button.Icon.Texture:GetTexture())
				totem.Cooldown:SetCooldownFromDurationObject(GetTotemDuration(button.slot))
				totem.Cooldown:Show()
				totem:Show()

				-- Invisible native artwork; the original scripts still own each individual click.
				-- 原生外觀透明；每個圖示仍由各自原生按鈕處理點擊，不改原生腳本。
				button:ClearAllPoints()
				button:SetParent(totem)
				button:SetAllPoints(totem)
				button:SetAlpha(0)
				button:SetFrameLevel(totem:GetFrameLevel() + 3)
				button:EnableMouse(true)
			else
				totem.Icon:SetTexture(nil)
				totem.Cooldown:Clear()
				totem.Cooldown:Hide()
				totem:Hide()
			end
		end
		bar:SetShown(#active > 0)
	end

	-- Blizzard keeps all events, pool updates and click rules; no extra timer or event loop.
	-- 事件、按鈕池及取消規則都交給暴雪，不另建計時器或事件循環。
	hooksecurefunc(nativeFrame, "Update", UpdateTotemBar)
	UpdateTotemBar()
end

-- Follow the existing pet frame's unit watch, including vehicle and show/hide changes.
-- 跟隨既有寵物框的顯示控制，也涵蓋載具與顯示／隱藏切換。
T.LinkTotemsToPet = function(self, pet)
	local bar = self.HankkTotems
	if not bar or bar.Pet then return end
	bar.Pet = pet
	local hasPet
	local function UpdatePosition(shown)
		if hasPet == shown then return end
		hasPet = shown
		bar:ClearAllPoints()
		if shown then
			-- Leave 4 for the aura shadow and 1 clear unit above the pet text row.
			-- 在寵物文字上方留 4 單位給光環陰影，再留 1 單位空隙。
			-- Pet already follows the digit edge; cancel only its optional horizontal offset.
			-- 寵物已對齊數字右端；只扣回寵物額外設定的水平偏移。
			bar:SetPoint("BOTTOMRIGHT", pet, "TOPRIGHT", -C.Position.Pet[4], 5)
		else
			bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", self.DigitRightOffset, 0)
		end
	end
	-- Hooks supply fixed states; do not read the pet's secret text, visibility or geometry.
	-- 從顯示／隱藏回呼傳入固定狀態，不讀寵物的受限文字、可見性或座標。
	pet:HookScript("OnShow", function() UpdatePosition(true) end)
	pet:HookScript("OnHide", function() UpdatePosition(false) end)
	-- The public effective unit also handles a vehicle already active at /reload.
	-- 公開的目前單位也能處理 /reload 時已在載具中的情況。
	UpdatePosition(UnitExists(pet.__unit))
end
