local _, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

--===================================================--
-- Shared layout / 共用外觀
--===================================================--

local textGap, textLineGap = 2, G.OtherTextLineGap	-- 文字資訊區水平間距，垂直間距
local iconGap = 4					-- 血量圖示與文字資訊區水平間距
local textHeight = G.OtherFS		-- 文字資訊區數值字高
local nameHeight = (G.OtherFS - 4)	-- 文字資訊區名字字高
local statusTextInset = {death = 65, ghost = 54, offline = 85}

-- 設定狀態圖示
local function SetHealthStatus(health, status)
	if health.activeStatus ~= status then
		for _, icon in pairs(health.Status) do
			icon:SetShown(icon == status)
			icon.Glow:SetShown(icon == status)
		end
		health.Base:SetShown(not status)
		health.Fill:SetShown(not status)
		health.Glow:SetShown(not status)

		health.activeStatus = status
	end
end

-- 更新狀態圖，只有隊友框提供離線圖示；離線優先於死亡與釋放靈魂。
local function PostUpdateHealth(health, unit)
	SetHealthStatus(health, (health.Status.offline and not UnitIsConnected(unit) and health.Status.offline)
		or (UnitIsGhost(unit) and health.Status.ghost)
		or (UnitIsDead(unit) and health.Status.death))
end

--===================================================--
-- Specialization artwork / 專精圖示
--===================================================--

-- 每筆資料記錄 256px 圖格的 UV、圖集頁數、水位範圍與可見左緣。
-- 底圖、填色和柔光共用完整圖格，按圖案可見左緣對齊。
local specIcons = {
	-- Druid / 德魯伊
	[102] = {{0, 0.125, 0, 0.25}, 1, 0.1953125, 0.61328125, 0.1953125},		-- 平衡
	[103] = {{0.125, 0.25, 0, 0.25}, 1, 0.1875, 0.609375, 0.171875},		-- 野性戰鬥
	[104] = {{0.25, 0.375, 0, 0.25}, 1, 0.17578125, 0.6171875, 0.20703125},	-- 守護者
	[105] = {{0.375, 0.5, 0, 0.25}, 1, 0.18359375, 0.62109375, 0.19140625},	-- 恢復
	-- Hunter / 獵人
	[253] = {{0.5, 0.625, 0, 0.25}, 1, 0.203125, 0.578125, 0.16015625},	-- 野獸控制
	[254] = {{0.625, 0.75, 0, 0.25}, 1, 0.2109375, 0.5859375, 0.1171875},	-- 射擊
	[255] = {{0.75, 0.875, 0, 0.25}, 1, 0.1875, 0.67578125, 0.1640625},	-- 生存
	-- Mage / 法師
	[62] = {{0.875, 1, 0, 0.25}, 1, 0.16015625, 0.6484375, 0.1484375},		-- 秘法
	[63] = {{0, 0.125, 0.25, 0.5}, 1, 0.171875, 0.65625, 0.15625},			-- 火焰
	[64] = {{0.125, 0.25, 0.25, 0.5}, 1, 0.1796875, 0.65234375, 0.1640625},	-- 冰霜
	-- Paladin / 聖騎士
	[65] = {{0.25, 0.375, 0.25, 0.5}, 1, 0.15625, 0.6875, 0.140625},		-- 神聖
	[66] = {{0.375, 0.5, 0.25, 0.5}, 1, 0.1953125, 0.609375, 0.17578125}, 	-- 防護
	[70] = {{0.5, 0.625, 0.25, 0.5}, 1, 0.16015625, 0.66015625, 0.1484375},	-- 懲戒
	-- Priest / 牧師
	[256] = {{0.625, 0.75, 0.25, 0.5}, 1, 0.19140625, 0.6171875, 0.171875},	-- 戒律
	[257] = {{0.75, 0.875, 0.25, 0.5}, 1, 0.1953125, 0.609375, 0.15625},	-- 神聖
	[258] = {{0.875, 1, 0.25, 0.5}, 1, 0.19921875, 0.609375, 0.16796875},	-- 暗影
	-- Rogue / 盜賊
	[259] = {{0, 0.125, 0.5, 0.75}, 1, 0.1796875, 0.66015625, 0.13671875},		-- 刺殺
	[260] = {{0.125, 0.25, 0.5, 0.75}, 1, 0.18359375, 0.63671875, 0.1953125},	-- 暴徒
	[261] = {{0.25, 0.375, 0.5, 0.75}, 1, 0.18359375, 0.640625, 0.14453125},	-- 敏銳
	-- Shaman / 薩滿
	[262] = {{0.375, 0.5, 0.5, 0.75}, 1, 0.16796875, 0.671875, 0.2109375},	-- 元素
	[263] = {{0.5, 0.625, 0.5, 0.75}, 1, 0.17578125, 0.65625, 0.13671875},	-- 增強
	[264] = {{0.625, 0.75, 0.5, 0.75}, 1, 0.1875, 0.63671875, 0.16015625},	-- 恢復
	-- Warlock / 術士
	[265] = {{0.75, 0.875, 0.5, 0.75}, 1, 0.19921875, 0.60546875, 0.16015625},	-- 痛苦
	[266] = {{0.875, 1, 0.5, 0.75}, 1, 0.1875, 0.62109375, 0.1640625},			-- 惡魔學識
	[267] = {{0, 0.125, 0.75, 1}, 1, 0.171875, 0.68359375, 0.15625},			-- 毀滅
	-- Warrior / 戰士
	[71] = {{0.125, 0.25, 0.75, 1}, 1, 0.1796875, 0.6484375, 0.16796875},	-- 武器
	[72] = {{0.25, 0.375, 0.75, 1}, 1, 0.15625, 0.6875, 0.15234375},		-- 狂怒
	[73] = {{0.375, 0.5, 0.75, 1}, 1, 0.1875, 0.62890625, 0.21875},			-- 防護
	-- Death Knight / 死亡騎士
	[250] = {{0.5, 0.625, 0.75, 1}, 1, 0.15625, 0.66015625, 0.2109375},		-- 血魄
	[251] = {{0.625, 0.75, 0.75, 1}, 1, 0.1875, 0.62890625, 0.19140625},	-- 冰霜
	[252] = {{0.75, 0.875, 0.75, 1}, 1, 0.203125, 0.59765625, 0.16015625},	-- 穢邪
	-- Monk / 武僧
	[268] = {{0.875, 1, 0.75, 1}, 1, 0.1796875, 0.640625, 0.1640625},	-- 釀酒
	[270] = {{0, 0.125, 0, 1}, 2, 0.1875, 0.61328125, 0.15625},			-- 織霧
	[269] = {{0.125, 0.25, 0, 1}, 2, 0.18359375, 0.640625, 0.13671875},	-- 御風
	-- Demon Hunter / 惡魔獵人
	[577] = {{0.25, 0.375, 0, 1}, 2, 0.1796875, 0.6640625, 0.15234375},	-- 災虐
	[581] = {{0.375, 0.5, 0, 1}, 2, 0.18359375, 0.65625, 0.15234375},	-- 復仇
	[1480] = {{0.5, 0.625, 0, 1}, 2, 0.1796875, 0.640625, 0.140625},	-- 噬滅
	-- Evoker / 喚能師
	[1467] = {{0.625, 0.75, 0, 1}, 2, 0.17578125, 0.6484375, 0.1484375},-- 破滅
	[1468] = {{0.75, 0.875, 0, 1}, 2, 0.17578125, 0.6484375, 0.140625},	-- 護存
	[1473] = {{0.875, 1, 0, 1}, 2, 0.1796875, 0.65234375, 0.12890625},	-- 強化
}

-- 專精不明時只顯示該職業的圖示。
local classIconSpecs = {
	DEATHKNIGHT = 252,	-- 邪dk
	DRUID = 104,		-- 熊德
	HUNTER = 254,		-- 獸王獵
	MAGE = 62,			-- 秘法
	MONK = 269,			-- 風僧
	PALADIN = 70,		-- 懲戒騎
	PRIEST = 257,		-- 神牧
	ROGUE = 261,		-- 敏銳賊
	SHAMAN = 264,		-- 恢復薩
	WARLOCK = 266,		-- 惡魔術
	WARRIOR = 72,		-- 狂戰
	DEMONHUNTER = 577,	-- 災虐dh
	EVOKER = 1467,		-- 破滅龍
}

-- 隊友觀察取得的是公開專精編號，可以用來查表選擇圖示。
local function SetSpecIcon(health, specID, class)
	local icon = specIcons[specID] or specIcons[classIconSpecs[class]]
	if health.specIcon == icon then return end
	health.specIcon = icon
	
	local base, fill, glow, owner = health.Base, health.Fill, health.Glow, health.LayoutOwner
	local size = health.IconSize
	local inset = (icon and size * icon[5]) or 38 * size / 256
	-- 只移動圖格來對齊可見左緣，定位點與文字都保持不動。
	base:SetPoint("BOTTOMLEFT", owner.IconAnchor, "BOTTOMLEFT", -inset, -46 * size / 256)
	health:ClearAllPoints()
	
	if icon then
		health:SetSize(size, size * icon[4])
		health:SetPoint("BOTTOMLEFT", owner.IconAnchor, "BOTTOMLEFT", -inset, size * icon[3] - 46 * size / 256)
		-- 因為分成兩張圖，所以需要判斷用的圖格在哪張圖集上
		base:SetTexture((icon[2] == 1 and G.media.specbase1) or G.media.specbase2)
		base:SetTexCoord(unpack(icon[1]))

		fill:SetTexture((icon[2] == 1 and G.media.specfill1) or G.media.specfill2)
		fill:SetTexCoord(unpack(icon[1]))
		fill:SetVertexColor(1, 1, 1)

		glow:SetTexture((icon[2] == 1 and G.media.specglow1) or G.media.specglow2)
		glow:SetTexCoord(unpack(icon[1]))
	else
		-- 專精與職業都沒有可用圖案時改用骷髏。
		health:SetSize(size, size * 166 / 256)
		health:SetPoint("BOTTOMLEFT", owner.IconAnchor, "BOTTOMLEFT", -inset, 0)

		base:SetTexture(G.media.digitbase)
		base:SetSpriteSheetCell(G.HealthIconCells.skull, 4, 4)

		fill:SetTexture(G.media.digitfill)
		fill:SetSpriteSheetCell(G.HealthIconCells.skull, 4, 4)
		fill:SetVertexColor(unpack(C.HealthColor))

		glow:SetTexture(G.media.digitglow)
		glow:SetSpriteSheetCell(G.HealthIconCells.skull, 4, 4)
	end
	glow:SetShown(not health.activeStatus)
end

--===================================================--
-- Shared frame creation / 共用框體建立
--===================================================--

local function CreateOtherStyle(self, size)
	local textureRatio = size / 256

	-- 三種框體共用固定點擊區：寬度為資訊區寬加圖示寬，高度與圖示相同。
	self:SetSize(C.InfoWidth + size, size)
	self:RegisterForClicks("AnyDown", "AnyUp")

	-- 定位點固定在骷髏可見左緣、水位底部；文字往左延伸，圖示往右延伸。
	-- 血量或狀態改變時，都不移動這個定位點。
	local iconAnchor = CreateFrame("Frame", nil, self)
	iconAnchor:SetSize(1, 1)
	iconAnchor:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -size + 38 * textureRatio, 46 * textureRatio)
	self.IconAnchor = iconAnchor

	-- 等高後的骷髏填色在 y=44..210，水位不計入黑邊與透明留白。
	local health = CreateFrame("StatusBar", nil, self, "DisableUntrustedLayoutScriptsTemplate")
	health:SetSize(size, 166 * textureRatio)
	health:SetPoint("BOTTOMLEFT", iconAnchor, "BOTTOMLEFT", -38 * textureRatio, 0)
	health:SetOrientation("VERTICAL")
	health:SetReverseFill(false)
	health:SetStatusBarTexture(G.media.blank)
	health:SetStatusBarColor(1, 1, 1, 0)
	health:SetMinMaxValues(0, 1)
	health:SetValue(0)
	health.smoothing = Enum.StatusBarInterpolation.Immediate
	health.maximumHealthClampMode = Enum.UnitMaximumHealthMode.Default

	-- 跟隨原生血量填色範圍，裁掉圖案超出目前水位的部分。
	local clip = CreateFrame("Frame", nil, health, "DisableUntrustedLayoutScriptsTemplate")
	clip:SetAllPoints(health:GetStatusBarTexture())
	clip:SetClipsChildren(true)

	local base = health:CreateTexture(nil, "BACKGROUND")
	base:SetSize(size, size)
	base:SetPoint("BOTTOMLEFT", iconAnchor, "BOTTOMLEFT", -38 * textureRatio, -46 * textureRatio)
	base:SetTexture(G.media.digitbase)
	base:SetSpriteSheetCell(G.HealthIconCells.skull, 4, 4)
	-- 填色固定跟隨完整底圖，血量下降時只裁切，不壓縮圖案。
	local fill = clip:CreateTexture(nil, "ARTWORK")
	fill:SetAllPoints(base)
	fill:SetTexture(G.media.digitfill)
	fill:SetSpriteSheetCell(G.HealthIconCells.skull, 4, 4)
	fill:SetVertexColor(unpack(C.HealthColor))
	health.Base, health.Fill = base, fill

	-- 骷髏與專精共用同一層柔光，底圖只保留灰底和純黑輪廓。
	local glow = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	glow:SetAllPoints(base)
	glow:SetTexture(G.media.digitglow)
	glow:SetSpriteSheetCell(G.HealthIconCells.skull, 4, 4)
	glow:SetVertexColor(0, 0, 0)
	glow:SetBlendMode("BLEND")
	health.Glow = glow

	-- 圖格維持完整尺寸，各張圖案的可見左緣都對齊定位點。
	-- 較窄的狀態圖示預先往左靠攏，切換時不用移動文字。
	health.Status = {}
	for _, name in ipairs({"death", "ghost"}) do
		local icon = health:CreateTexture(nil, "ARTWORK")
		icon:SetSize(size, size)
		icon:SetPoint("BOTTOMLEFT", iconAnchor, "BOTTOMLEFT", -statusTextInset[name] * textureRatio, -46 * textureRatio)
		icon:SetTexture(G.media.digitbase)
		icon:SetSpriteSheetCell(G.HealthIconCells[name], 4, 4)
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
	health.IconSize, health.LayoutOwner = size, self
	self.Health = health

	-- 名字與施法條定位在主框體上。
	local info = CreateFrame("Frame", nil, self)
	info:SetSize(C.InfoWidth, nameHeight)
	self.Info = info
	info:SetPoint("BOTTOMRIGHT", iconAnchor, "BOTTOMLEFT", -iconGap, textHeight + textLineGap)

	-- 數值文字不放在水位層，讓能量文字能接在血量文字左側。
	local value = F.CreateText(info, G.OtherFS, "RIGHT")
	value:SetSize(0, textHeight)
	value:SetPoint("BOTTOMRIGHT", info, "BOTTOMRIGHT", 0, -textHeight - textLineGap)
	value:SetTextColor(unpack(C.SubHealthColor))
	self.Value = value
	self:Tag(value, (F.GetHankkOption("CurrentValuesOnly") and "[perhp]") or "[perhp]%")

	local power = F.CreateText(self, G.OtherFS, "RIGHT")
	power:SetSize(0, textHeight)
	power:SetPoint("RIGHT", value, "LEFT", -textGap, 0)
	self.PowerValue = power
	
	local name = F.CreateText(info, nameHeight, "RIGHT")
	name:SetSize(C.InfoWidth, nameHeight)
	name:SetPoint("BOTTOMRIGHT", info, "BOTTOMRIGHT", 0, 0)
	name:SetTextColor(unpack(C.TextColor))
	self.Name = name
	self:Tag(name, "[hankk:namecolor]"..G.NameTag.."|r")
	if self.mystyle ~= "party" then
		-- 固定施法區覆蓋名字，不再隨狀態圖示或團隊標記移動。
		T.CreateOtherCastbar(self, C.InfoWidth, nameHeight + 2, info)
		self.Castbar:SetPoint("LEFT", info, "LEFT", 1, 0)
	end

	-- 隊友標記放在名字旁，首領與競技場標記維持骷髏上的位置。
	local raidIcon = info:CreateTexture(nil, "OVERLAY", nil, 4)
	raidIcon:SetSize(C.RaidIconSize, C.RaidIconSize)
	raidIcon:SetTexture(G.media.raidicon)
	if self.mystyle == "party" then
		raidIcon:SetPoint("RIGHT", info, "RIGHT", 0, 0)
	else
		raidIcon:SetPoint("TOPRIGHT", iconAnchor, size - C.RaidIconSize*0.75, size - C.RaidIconSize*0.75)
	end
	raidIcon:Hide()
	self.RaidTargetIndicator = raidIcon
end

local function PlaceOther(frame, previous, position)
	-- 預覽框建立後會換父框，因此資訊區與施法條在這裡一同設定層級。
	frame.Info:SetFrameLevel(frame:GetFrameLevel() + 4)
	local bar = frame.Castbar
	local barLevel = frame:GetFrameLevel() + 7
	bar:SetFrameLevel(barLevel)
	bar.BarBG:SetFrameLevel(barLevel - 2)
	bar.BarShadow:SetFrameLevel(barLevel - 1)
	if previous then
		frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -10)
	else
		frame:SetPoint(unpack(position))
	end
end

--===================================================--
-- Unit-specific creation / 各單位建立入口
--===================================================--

local function CreateBossStyle(self)
	CreateOtherStyle(self, C.BossSize)
	self:Tag(self.PowerValue, "[powercolor][hankk:otherpower]")
	T.CreateBossAuras(self)
end

local function PostUpdateArenaColor(health, _, color)
	local r, g, b = unpack(C.HealthColor)
	if color then r, g, b = color:GetRGB() end
	health.Fill:SetVertexColor(r, g, b)
	health:SetStatusBarColor(1, 1, 1, 0)
end

-- 對手出場前，由暴雪的顯示工具依受限專精編號提供職業色。
-- 舊版沒有此工具、遊戲 PvP 設定關閉或未回報專精時，骷髏維持橙色。
local function UpdateArenaPreparationColor(health)
	health:SetStatusBarColor(1, 1, 1, 0)
	if UnitFrameUtil and UnitFrameUtil.GetArenaOpponentSpecDisplayInfo
		and GetCVarBool("pvpFramesDisplayClassColor") then
		local info = UnitFrameUtil.GetArenaOpponentSpecDisplayInfo(health.LayoutOwner.ArenaIndex)
		local r, g, b = unpack(C.HealthColor)
		health.Fill:SetVertexColor(
			C_CurveUtil.EvaluateColorValueFromBoolean(info.hasSpec, info.barColorR, r),
			C_CurveUtil.EvaluateColorValueFromBoolean(info.hasSpec, info.barColorG, g),
			C_CurveUtil.EvaluateColorValueFromBoolean(info.hasSpec, info.barColorB, b)
		)
	else
		health.Fill:SetVertexColor(unpack(C.HealthColor))
	end
end

local function PostUpdateArenaPreparation(health)
	-- 準備階段還原正常對手，避免沿用上一輪的死亡圖示。
	SetHealthStatus(health, false)
end

local function CreateArenaStyle(self, unit)
	CreateOtherStyle(self, C.BossSize)
	self:Tag(self.PowerValue, "[powercolor][hankk:otherpower]")
	T.CreateArenaAuras(self)
	self.ArenaIndex = tonumber(unit:match("^arena(%d+)$"))
	local health = self.Health
	health.colorClass = true
	health.PostUpdateColor = PostUpdateArenaColor
	health.UpdateColorArenaPreparation = UpdateArenaPreparationColor
	health.PostUpdateArenaPreparation = PostUpdateArenaPreparation
end

--===================================================--
-- Party frames / 隊友框體
--===================================================--

local partyCount = 4
local partyGap = 6

-- 隊友框建立前，先註冊 party1～4 的專精查詢。
do
	local members = {}
	local partyUnits = {"party1", "party2", "party3", "party4"}
	local allowedUnits = {party1 = true, party2 = true, party3 = true, party4 = true}
	local rosterEvents = {"GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD"}
	local queryEvents = {"PLAYER_SPECIALIZATION_CHANGED",
		"INSPECT_READY", "UNIT_CONNECTION", "UNIT_NAME_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}
	local dispatcher, timer, cursor, queryActive
	local Schedule

	local function UpdatePartySpecIcon(frame)
		local element = frame.HankkPartySpec
		SetSpecIcon(frame.Health, element.specID, element.class)
	end

	-- 只查 party1～4；在受限場景仍可取得他們的 GUID。
	-- 不把這條查詢路徑套用到敵人。
	local function RefreshIdentity(frame)
		local element = frame.HankkPartySpec
		local exists = UnitExists(element.unit)
		local guid = (exists and UnitGUID(element.unit)) or nil
		local class = (exists and select(2, UnitClass(element.unit))) or nil
		-- 追隨者 NPC 使用顯示職業，但不進入玩家查裝佇列。
		local isPlayer = (exists and UnitIsPlayer(element.unit) and not UnitInPartyIsAI(element.unit)) or false
		local changed = element.guid ~= guid or element.isPlayer ~= isPlayer
		if changed then
			element.guid, element.specID, element.attempts = guid, nil, 0
			element.isPlayer = isPlayer
		end
		element.class = class
	end

	local function CancelTimer()
		if timer then timer:Cancel(); timer = nil end
	end

	local function ClearIdentity(frame)
		local element = frame.HankkPartySpec
		element.guid, element.specID, element.attempts = nil, nil, 0
		element.class, element.isPlayer = nil, false
		UpdatePartySpecIcon(frame)
	end

	-- 團隊中不顯示隊友框：只保留名單／進世界事件，以便回到小隊時恢復查詢。
	local function SyncRaidState()
		local active = not IsInRaid()
		if queryActive ~= active then
			queryActive = active
			for _, event in ipairs(queryEvents) do
				if active then dispatcher:RegisterEvent(event) else dispatcher:UnregisterEvent(event) end
			end
			if not active then
				CancelTimer()
				for _, frame in pairs(members) do ClearIdentity(frame) end
			end
		end
		return active
	end

	local function Pump()
		timer = nil
		if InCombatLockdown() or IsInRaid() then return end
		-- 使用者正在查裝或查看天賦時讓路，包含查裝視窗尚未顯示的等待階段。
		if not (InspectFrame and InspectFrame.unit)
			and not (PlayerSpellsFrame and PlayerSpellsFrame:IsInspecting()) then
			for _ = 1, #partyUnits do
				cursor = (cursor or 0) % #partyUnits + 1
				local frame = members[partyUnits[cursor]]
				if frame then
					RefreshIdentity(frame)
					UpdatePartySpecIcon(frame)
					local element = frame.HankkPartySpec
					if element.isPlayer and element.guid and not element.specID and element.attempts < 3
						and UnitIsConnected(element.unit) and CanInspect(element.unit) then
						element.attempts = element.attempts + 1
						NotifyInspect(element.unit)
						break
					end
				end
			end
		end
		Schedule()
	end

	-- 隊友查裝每次至少間隔三秒，每人最多嘗試三次。
	-- 三秒是我們保守選用的間隔，並非 API 的硬性限制。
	Schedule = function()
		if timer or InCombatLockdown() or IsInRaid() then return end
		for _, frame in pairs(members) do
			local element = frame.HankkPartySpec
			if element.isPlayer and element.guid and not element.specID and element.attempts < 3
				and UnitIsConnected(element.unit) then
				timer = C_Timer.NewTimer(3, Pump)
				return
			end
		end
	end

	local function OnEvent(_, event, argument)
		if not SyncRaidState() then return end
		if event == "PLAYER_REGEN_DISABLED" then CancelTimer(); return end
		-- 單位事件只處理指定隊友；查裝結果則對照已記錄的 GUID。
		-- 不相關事件直接略過，不查其他隊友身分，也不更新圖示。
		local eventFrame
		if event == "UNIT_CONNECTION" or event == "UNIT_NAME_UPDATE"
			or event == "PLAYER_SPECIALIZATION_CHANGED" then
			eventFrame = members[argument]
			if not eventFrame then return end
		elseif event == "INSPECT_READY" then
			for _, frame in pairs(members) do
				if frame.HankkPartySpec.guid == argument then
					eventFrame = frame
					break
				end
			end
			if not eventFrame then return end
		end
		for unit, frame in pairs(members) do
			if not eventFrame or frame == eventFrame then
				local element = frame.HankkPartySpec
				if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED"
					or event == "UNIT_CONNECTION" then
					-- 進入世界後重查專精；隊友重連只恢復尚未完成的查詢。
					if event == "PLAYER_ENTERING_WORLD" then
						element.specID = nil
					end
					element.attempts = 0
					-- 名單與連線變化仍刷新整框；進世界由 oUF 更新，離戰只恢復專精查詢。
					-- 單位或載具暫不存在時，也要更新固定隊友的身分與圖示。
					if (event == "GROUP_ROSTER_UPDATE" or event == "UNIT_CONNECTION") and UnitExists(frame.__unit) then
						frame:UpdateAllElements(event)
					else
						RefreshIdentity(frame)
						UpdatePartySpecIcon(frame)
					end
				else
					RefreshIdentity(frame)
					if event == "INSPECT_READY" then
						if element.isPlayer and element.guid and element.guid == argument then
							local specID = C_SpecializationInfo.GetInspectSpecialization(unit)
							if specID and specID > 0 then element.specID = specID end
						end
					elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
						element.specID, element.attempts = nil, 0
					end
					UpdatePartySpecIcon(frame)
				end
			end
		end
		Schedule()
	end

	local function Update(self)
		if not SyncRaidState() then return end
		RefreshIdentity(self)
		UpdatePartySpecIcon(self)
		Schedule()
	end

	local function Enable(self, unit)
		local element = self.HankkPartySpec
		if not element or not allowedUnits[unit] then return end
		element.unit, element.attempts = unit, 0
		members[unit] = self
		if not dispatcher then dispatcher = CreateFrame("Frame") end
		for _, event in ipairs(rosterEvents) do dispatcher:RegisterEvent(event) end
		dispatcher:SetScript("OnEvent", OnEvent)
		Update(self)
		return true
	end

	local function Disable(self)
		local element = self.HankkPartySpec
		members[element.unit] = nil
		ClearIdentity(self)
		if not next(members) then
			CancelTimer()
			for _, event in ipairs(rosterEvents) do dispatcher:UnregisterEvent(event) end
			for _, event in ipairs(queryEvents) do dispatcher:UnregisterEvent(event) end
			queryActive = nil
			dispatcher:SetScript("OnEvent", nil)
		end
	end

	-- 元素啟停交給官方核心；共用查詢器不呼叫 ClearInspectPlayer 清除其他插件的資料。
	oUF:AddElement("HankkPartySpec", Update, Enable, Disable)
end

-- 隊友只在承擔仇恨時高亮，不分職責；顏色由 oUF 回呼提供。
local function PostUpdatePartyThreat(element, unit, status, color)
	local glow = element.Glow
	if status and status > 1 then
		glow:SetVertexColor(color:GetRGB())
	else
		glow:SetVertexColor(0, 0, 0)
	end
end

-- 預覽職責代表選中的圖案，不取提供血量與法力的目標職責。
-- 使用固定範例，也能在沒有正式服專精查詢的 FOREVER 顯示。
local previewRoles = {
	[66] = "TANK", [73] = "TANK", [104] = "TANK", [250] = "TANK", [268] = "TANK", [581] = "TANK",
	[65] = "HEALER", [105] = "HEALER", [256] = "HEALER", [257] = "HEALER",
	[264] = "HEALER", [270] = "HEALER", [1468] = "HEALER",
}

local function UpdatePartyPreview(frame)
	SetSpecIcon(frame.Health, frame.PreviewSpecID)
	local role = previewRoles[frame.PreviewSpecID] or "DAMAGER"
	frame.PreviewRole = role
	frame.PreviewRoleIndicator:SetTexture((role == "TANK" and G.media.role_tank)
		or (role == "HEALER" and G.media.role_healer) or G.media.role_dps)
	frame.PreviewRoleIndicator:Show()
end

local function CreatePartyStyle(self, unit)
	-- 法力標籤固定用這位隊友判斷職責，載具替換顯示單位時不改查載具職責。
	-- 讀取目標的預覽只使用範例職責，不啟用隊友查裝或仇恨元素。
	local preview = unit == "target"
	if preview then self.PreviewRole = "DAMAGER" else self.PartyUnit = unit end
	self.mystyle = "party"
	CreateOtherStyle(self, C.PartySize)
	-- 隊友標記顯示時才讓名字左移；隊友沒有施法條需要一起調整。
	local raidIcon = self.RaidTargetIndicator
	hooksecurefunc(raidIcon, "Show", function()
		self.Name:SetPoint("BOTTOMRIGHT", self.Info, "BOTTOMRIGHT", -C.RaidIconSize - textGap, 0)
	end)
	hooksecurefunc(raidIcon, "Hide", function()
		self.Name:SetPoint("BOTTOMRIGHT", self.Info, "BOTTOMRIGHT", 0, 0)
	end)
	local health = self.Health

	-- 沿用死亡／靈魂切換，僅為隊友補上固定大小、不受水位裁切的離線圖示。
	local offline = health:CreateTexture(nil, "ARTWORK")
	offline:SetSize(health.IconSize, health.IconSize)
	offline:SetPoint("BOTTOMLEFT", self.IconAnchor, "BOTTOMLEFT",
		-statusTextInset.offline * health.IconSize / 256, -46 * health.IconSize / 256)
	offline:SetTexture(G.media.digitbase)
	offline:SetSpriteSheetCell(G.HealthIconCells.offline, 4, 4)
	offline:Hide()
	local offlineGlow = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	offlineGlow:SetAllPoints(offline)
	offlineGlow:SetTexture(G.media.digitglow)
	offlineGlow:SetSpriteSheetCell(G.HealthIconCells.offline, 4, 4)
	offlineGlow:SetVertexColor(0, 0, 0)
	offlineGlow:SetBlendMode("BLEND")
	offlineGlow:Hide()
	offline.Glow = offlineGlow
	health.Status.offline = offline
	T.CreatePartyAuras(self)
	self:Tag(self.PowerValue, "[hankk:partypower]")

	-- 仇恨更新交給 oUF；指示器隱藏時，圖示柔光恢復黑色。
	if not preview and F.GetHankkOption("ThreatHighlight") then
		local indicator = CreateFrame("Frame", nil, self)
		indicator:EnableMouse(false)
		indicator.Glow = self.Health.Glow
		indicator.PostUpdate = PostUpdatePartyThreat
		hooksecurefunc(indicator, "Hide", function() indicator.Glow:SetVertexColor(0, 0, 0) end)
		indicator:Hide()
		self.ThreatIndicator = indicator
	end

	-- 職責圖示放回框體右下角，不進入血量裁切層。
	local role = self.Info:CreateTexture(nil, "OVERLAY")
	role:SetSize(28, 28)
	role:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 8)
	role:SetDesaturated(true)
	role:SetTexCoord(0, 1, 0, 1)
	role:Hide()
	if preview then
		self.PreviewRoleIndicator = role
	else
		-- 有暴雪原生更新器就交它套用自訂材質；沒有時，oUF 先選內建圖集，
		-- 再依它回報的公開職責換成我們的材質。
		role.tankAtlas = G.media.role_tank
		role.healerAtlas = G.media.role_healer
		role.damageAtlas = G.media.role_dps
		if UnitFrameUtil and UnitFrameUtil.UpdateUnitFrameRoleIcon then
			local state = {
				roleIcon = role,
				optionTable = {
					displayRoleIcon = true,
					textureMap = {
						TANK = role.tankAtlas,
						HEALER = role.healerAtlas,
						DAMAGER = role.damageAtlas,
						VEHICLE = "",
					},
				},
			}
			role.Override = function(frame)
				state.unit = frame.__unit
				UnitFrameUtil.UpdateUnitFrameRoleIcon(state)
			end
		else
			role.PostUpdate = function(element, assignedRole)
				local texture
				if assignedRole == Enum.LFGRole.Tank then texture = element.tankAtlas
				elseif assignedRole == Enum.LFGRole.Healer then texture = element.healerAtlas
				elseif assignedRole == Enum.LFGRole.Damage then texture = element.damageAtlas end
				if texture then
					element:SetTexture(texture)
					element:SetTexCoord(0, 1, 0, 1)
				end
			end
		end
		self.GroupRoleIndicator = role
		self.HankkPartySpec = {}
	end
end

--===================================================--
-- Register and spawn / 註冊外觀與建立正式單位
--===================================================--

oUF:Factory(function(self)
	self:RegisterStyle("HankkBoss", CreateBossStyle)
	self:RegisterStyle("HankkArena", CreateArenaStyle)
	local active = self:GetActiveStyle()
	if F.GetHankkOption("Boss") then
		local previous
		self:SetActiveStyle("HankkBoss")
		-- 數量跟隨遊戲上限；建立後由 oUF 接管原生首領框的停用。
		for index = 1, MAX_BOSS_FRAMES do
			local frame = self:Spawn("boss"..index, "oUF_HankkBoss"..index)
			PlaceOther(frame, previous, C.Position.Boss)
			previous = frame
		end
	end
	if not G.IsForever and F.GetHankkOption("Arena") then
		local previous
		self:SetActiveStyle("HankkArena")
		for index = 1, 5 do
			local frame = self:Spawn("arena"..index, "oUF_HankkArena"..index)
			PlaceOther(frame, previous, C.Position.Arena)
			previous = frame
		end
	end
	self:SetActiveStyle(active)
end)

oUF:Factory(function(self)
	self:RegisterStyle("HankkParty", CreatePartyStyle)
	if F.GetHankkOption("Party") then
		local group = CreateFrame("Frame", "oUF_HankkParty", UIParent, "SecureHandlerStateTemplate")
		group:SetSize(C.InfoWidth + C.PartySize,
			partyCount * C.PartySize + (partyCount - 1) * partyGap)
		group:SetPoint(unpack(C.Position.Party))
		group:Hide()
		-- 即使在戰鬥中，也由遊戲的隊伍狀態調整群組高度。
		group:SetAttribute("member-height", C.PartySize)
		group:SetAttribute("member-gap", partyGap)
		group:SetAttribute("_onstate-count", [[
			self:SetHeight(newstate * self:GetAttribute("member-height")
				+ (newstate - 1) * self:GetAttribute("member-gap"))
		]])
		RegisterStateDriver(group, "count", "[@party4,exists] 4; [@party3,exists] 3; [@party2,exists] 2; 1")
		local previous, active = nil, self:GetActiveStyle()
		self:SetActiveStyle("HankkParty")
		for index = 1, partyCount do
			-- 建立 party1-4 時由 oUF 接管暴雪隊伍框，不建立玩家副本或團隊框。
			local frame = self:Spawn("party"..index, "oUF_HankkParty"..index)
			frame:SetParent(group)
			frame.Info:SetFrameLevel(frame:GetFrameLevel() + 4)
			-- 群組底端固定並向上增長，內部單位則由上往下排列。
			if previous then
				frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -partyGap)
			else
				frame:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, 0)
			end
			previous = frame
		end
		self:SetActiveStyle(active)
		RegisterStateDriver(group, "visibility", "[group:raid] hide; [group:party] show; hide")
	end
end)

--===================================================--
-- Temporary target previews / 讀取目標的臨時預覽
--===================================================--

local L = ns[5]
local previews, previewEvents = {}, nil
local previewNames = {boss = "Boss", arena = "Arena", party = "Party"}
local previewSpecs = {264, 261, 258, 1480}

-- 預覽框保留供下次使用；關閉時停止監看單位，不讓它們自行重新出現。
local function ClosePreview(preview)
	if not preview then return end
	UnregisterStateDriver(preview.group, "visibility")
	preview.group:Hide()
	for _, frame in ipairs(preview.frames) do frame:Disable() end
end

SlashCmdList.OUFHANKKTEST = function(message)
	if InCombatLockdown() then print(L.PreviewCombat); return end
	local command, argument = message:lower():match("^%s*(%S+)%s*(.-)%s*$")
	if command == "off" and argument == "" then
		for _, preview in pairs(previews) do ClosePreview(preview) end
		if previewEvents then
			previewEvents:UnregisterEvent("PLAYER_ENTERING_WORLD")
			previewEvents:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
		print(L.PreviewOff)
		return
	end
	local name = previewNames[command]
	if not name or (command ~= "party" and argument ~= "") then print(L.PreviewHelp); return end
	if command == "arena" and G.IsForever then print(L.PreviewForeverArena); return end
	local specID
	if command == "party" and argument ~= "" then
		specID = tonumber(argument)
		if not specIcons[specID or false] then print(L.PreviewInvalidSpec); return end
	end

	-- 競技場準備時可能還沒有 arena 單位，因此在競技場內不開啟預覽。
	local _, instanceType = IsInInstance()
	if instanceType == "arena" then print(L.PreviewInArena); return end
	if command == "boss" then ClosePreview(previews.arena)
	elseif command == "arena" then ClosePreview(previews.boss) end

	local preview = previews[command]
	if not preview then
		local group = CreateFrame("Frame", "oUF_Hankk"..name.."Preview", UIParent, "SecureHandlerStateTemplate")
		group:Hide()
		if command == "party" then
			group:SetSize(C.InfoWidth + C.PartySize, partyCount * C.PartySize + (partyCount - 1) * partyGap)
			group:SetPoint(unpack(C.Position.Party))
		else
			group:SetAllPoints(UIParent)
		end
		preview = {group = group, frames = {}}
		previews[command] = preview
		local count = (command == "boss" and math.min(5, MAX_BOSS_FRAMES))
			or (command == "arena" and 5) or partyCount
		local active = oUF:GetActiveStyle()
		oUF:SetActiveStyle("Hankk"..name)
		for index = 1, count do
			-- 另外建立讀取目標的副本，不改任何正式首領、競技場或隊友框的單位。
			local frame = oUF:Spawn("target", "oUF_Hankk"..name.."Preview"..index)
			frame:SetParent(group)
			local previous = preview.frames[index - 1]
			if command == "party" then
				frame.Info:SetFrameLevel(frame:GetFrameLevel() + 4)
				if previous then
					frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -partyGap)
				else
					frame:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, 0)
				end
			else
				PlaceOther(frame, previous, C.Position[name])
			end
			preview.frames[index] = frame
		end
		oUF:SetActiveStyle(active)
		local label = F.CreateText(preview.frames[1], 12.8, "RIGHT")
		label:SetPoint("BOTTOMRIGHT", preview.frames[1], "TOPRIGHT", 0, 6)
		label:SetTextColor(unpack(C.HealthColor))
		label:SetFormattedText(L.PreviewLabel, L[name])
	end

	if not previewEvents then
		previewEvents = CreateFrame("Frame")
		previewEvents:SetScript("OnEvent", function(self)
			-- 換場景時關閉預覽；若已進入戰鬥，就等離開戰鬥後再解除安全框設定。
			if InCombatLockdown() then self:RegisterEvent("PLAYER_REGEN_ENABLED"); return end
			for _, activePreview in pairs(previews) do ClosePreview(activePreview) end
			self:UnregisterEvent("PLAYER_ENTERING_WORLD")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end)
	end
	previewEvents:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- 安全父框會在戰鬥、沒有目標或出現正式遭遇單位時隱藏所有副本。
	-- 隊友預覽在組隊時也隱藏；每個副本仍由原生單位監看處理目標是否存在。
	local visibility = "[combat][@target,noexists]"
	if command == "party" then visibility = visibility.."[group]" end
	for index = 1, MAX_BOSS_FRAMES do visibility = visibility.."[@boss"..index..",exists]" end
	if not G.IsForever then
		for index = 1, 5 do visibility = visibility.."[@arena"..index..",exists]" end
	end
	RegisterStateDriver(preview.group, "visibility", visibility.." hide; show")
	for index, frame in ipairs(preview.frames) do
		if command == "party" then
			frame.PreviewSpecID = specID or previewSpecs[index]
			UpdatePartyPreview(frame)
			-- 只有第二格示範仇恨紅光，不為隊友預覽查詢目標的仇恨。
			if index == 2 and F.GetHankkOption("ThreatHighlight") then
				frame.Health.Glow:SetVertexColor(oUF.colors.threat[3]:GetRGB())
			else frame.Health.Glow:SetVertexColor(0, 0, 0) end
		end
		frame:Enable()
		frame:UpdateAllElements("Hankk"..name.."Preview")
	end
	print(string.format(L.PreviewOn, L[name]))
end
SLASH_OUFHANKKTEST1 = "/hanktest"
SLASH_OUFHANKKTEST2 = "/hankktest"
