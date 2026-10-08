local _, ns = ...
local C, F, G, T = unpack(ns)
local oUF = ns.oUF

-- 名字上方的光環從定位點起算，留出兩行字高、行距與陰影空間。
local otherNameAuraY = G.OtherFS * 2 + 4

--===================================================--
-- Time format / 時間格式
--===================================================--

local roundDown = Enum.NumericRuleFormatRounding.Down
local durationFormatter = C_StringUtil.CreateNumericRuleFormatter()
durationFormatter:SetBreakpoints({
	{threshold = 0, step = 1, rounding = roundDown, format = "%d"},
	{threshold = 60, format = "%d:%02d", components = {
		{div = 60, step = 1, rounding = roundDown},	-- 分
		{mod = 60, step = 1, rounding = roundDown},	-- 秒，除mod得餘數即為秒
	}},
	{threshold = 300, format = "%dm", components = {{div = 60, step = 1, rounding = roundDown}}},
	{threshold = 3600, format = "%dh", components = {{div = 3600, step = 1, rounding = roundDown}}},
	{threshold = 86400, format = "%dd", components = {{div = 86400, step = 1, rounding = roundDown}}},
})

--===================================================--
-- Button appearance / 圖示外觀
--===================================================--

local function PostCreateAuraButton(element, button, options)
	button.Icon:SetTexCoord(.08, .92, .08, .92)
	if options.desaturateIcon then button.Icon:SetDesaturated(true) end

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints(button.Icon)
	highlight:SetColorTexture(1, 1, 1, .18)
	button:SetHighlightTexture(highlight, "ADD")

	local border = button:CreateTexture(nil, "BACKGROUND", nil, -1)
	border:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
	border:SetColorTexture(1, 1, 1, 1)
	border:SetVertexColor(.1, .1, .1, 1)

	local shadow = button:CreateTexture(nil, "BACKGROUND", nil, -2)
	shadow:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
	shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
	shadow:SetTexture(G.media.aurashadow)
	shadow:SetVertexColor(0, 0, 0, 1)

	if options.showDebuffTypeBorder then
		border:SetVertexColor(1, 1, 1, 1)
		button:AddDispelTypeTexture(border, {
			showWhenHarmful = true,
			showWithoutDispelType = true,
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
			customDispelColorMap = element.__owner.colors.dispel,
		})
	end

	F.SetTextFont(button.Count, G.AuraFS, "RIGHT", G.AuraFontFlag)
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	button.Count:SetTextColor(.9, .9, .1)
	
	F.SetTextFont(button.Time, G.AuraFS, "CENTER", G.AuraFontFlag)
	button.Time:ClearAllPoints()
	button.Time:SetPoint("TOP", button, "TOP", 0, 4)
	button.Time:SetTextColor(unpack(C.TextColor))
end

--===================================================--
-- Enemy/friendly identification / 敵我識別
--===================================================--

local function UpdateFocusAuras(self, event, unit)
	local relation = self.FocusAuraPolarity
	if not relation or not self.__unit or (unit and unit ~= self.__unit) then return end

	local hostile = (UnitCanAttack("player", self.__unit) and true) or false
	if relation.isHostile == hostile then return end
	relation.isHostile = hostile
	
	-- 直接設定各組的最終上限；篩選與上限變更由原生容器刷新。
	local auras = relation.container
	auras:SetAuraGroupMaxFrameCount(relation.important, (hostile and 0) or 2)
	auras:SetAuraGroupMaxFrameCount(relation.control, (hostile and 2) or 0)
	auras:SetAuraGroupFilterString(relation.helpful, (hostile and "HELPFUL") or "HELPFUL|PLAYER|!IMPORTANT")
	auras:SetAuraGroupFilterString(relation.harmful, (hostile and "HARMFUL|PLAYER|!CROWD_CONTROL") or "HARMFUL")
end

local function EnableFocusAuras(self)
	if not self.FocusAuraPolarity then return end
	-- oUF 已處理換焦點、單位與顯示刷新；這裡只補上缺少的陣營事件。
	self:RegisterEvent("UNIT_FACTION", UpdateFocusAuras)
	UpdateFocusAuras(self)
	return true
end

local function DisableFocusAuras(self)
	if not self.FocusAuraPolarity then return end
	self:UnregisterEvent("UNIT_FACTION", UpdateFocusAuras)
	self.FocusAuraPolarity.isHostile = nil
end

oUF:AddElement("HankkFocusAuraPolarity", UpdateFocusAuras, EnableFocusAuras, DisableFocusAuras)

--===================================================--
-- Target containers / 目標光環容器
--===================================================--

T.CreateTargetAuras = function(self)
	local maxBuffs = math.min(C.TargetMaxBuffs, C.TargetMaxAuras)
	local maxDebuffs = C.TargetMaxAuras - maxBuffs
	local maxPlayerDebuffs = math.min(10, maxDebuffs)
	local size, spacing = C.AuraSize, C.AuraSpacing

	local auras = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = size * C.TargetAurasPerRow + spacing * (C.TargetAurasPerRow - 1),
		initialAnchor = "TOPLEFT", growthX = "RIGHT", growthY = "DOWN",
	})
	-- 光環列與此單位的目標鏈文字保持對齊。
	auras:SetPoint("TOPLEFT", self, "BOTTOMLEFT", C.Position.TOT[4], 0)
	auras:SetFrameLevel(self:GetFrameLevel() + 4)
	auras.PostCreateButton = PostCreateAuraButton

	auras.size = size
	auras.showCount = true
	auras.showDuration = true
	auras.disableCooldown = true
	auras.durationFormatter = durationFormatter
	auras.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"
	auras.elementSpacing = spacing
	auras.lineSpacing = spacing
	auras.groupSpacing = size + spacing	-- 一般圖示間距已算在內；組與組之間再留一格空位。
	auras.groupLineSpacing = spacing
	auras.forceNewLine = false

	-- 每顆圖示使用固定格子大小，避免滿行提早換行。自己的減益最多留十格，其餘容量分給他人；兩組之間不插空格。
	auras:AddGroup("HELPFUL", {
		maxFrameCount = maxBuffs, layout = {elementWidth = size, elementHeight = size},
	})
	auras:AddGroup("HARMFUL|PLAYER", {
		maxFrameCount = maxPlayerDebuffs, showDebuffTypeBorder = true,
		layout = {elementWidth = size, elementHeight = size},
	})
	auras:AddGroup("HARMFUL|!PLAYER", {
		maxFrameCount = maxDebuffs - maxPlayerDebuffs, showDebuffTypeBorder = true,
		desaturateIcon = F.GetHankkOption("DebuffDesaturate"),
		layout = {elementWidth = size, elementHeight = size, groupSpacing = 0},
	})
	self.Auras = auras
end

--===================================================--
-- Focus containers / 焦點光環容器
--===================================================--

T.CreateFocusAuras = function(self, xOffset)
	local size, spacing = C.AuraSize, C.AuraSpacing

	local auras = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = size * 14 + spacing * (14 - 1),
		initialAnchor = "TOPLEFT", growthX = "RIGHT", growthY = "DOWN",
	})
	-- 光環列與此單位的目標鏈文字保持對齊。
	auras:SetPoint("TOPLEFT", self, "BOTTOMLEFT", xOffset, -5)
	auras:SetFrameLevel(self:GetFrameLevel() + 4)
	auras.PostCreateButton = PostCreateAuraButton

	auras.size = size
	auras.showCount = true
	auras.showDuration = true
	auras.disableCooldown = true
	auras.durationFormatter = durationFormatter
	auras.tooltipAnchor = "ANCHOR_BOTTOM"
	auras.elementSpacing = spacing
	auras.lineSpacing = spacing
	auras.groupSpacing = size + spacing	-- 一般圖示間距已算在內；組與組之間再留一格空位。
	auras.groupLineSpacing = spacing
	auras.forceNewLine = false

	-- 增益和減益各建立兩組。焦點敵我改變時，第一組切換原生篩選條件；第二組切換顯示上限，不使用時設為 0。
	-- 敵方增益 HELPFUL 4
	-- 敵方減益 HARMFUL|PLAYER|!CROWD_CONTROL 6 HARMFUL|CROWD_CONTROL 2
	-- 友方增益 HELPFUL|PLAYER|!IMPORTANT 4 HELPFUL|IMPORTANT 2
	-- 友方減益 HARMFUL 6
	
	local relation = {container = auras}
	self.FocusAuraPolarity = relation
	relation.helpful = auras:AddGroup("HELPFUL|PLAYER|!IMPORTANT", {
		maxFrameCount = 4, layout = {elementWidth = size, elementHeight = size},
	})
	relation.important = auras:AddGroup("HELPFUL|IMPORTANT", {
		maxFrameCount = 2, layout = {elementWidth = size, elementHeight = size},
	})
	relation.harmful = auras:AddGroup("HARMFUL", {
		maxFrameCount = 6, showDebuffTypeBorder = true, layout = {elementWidth = size, elementHeight = size},
	})
	relation.control = auras:AddGroup("HARMFUL|CROWD_CONTROL", {
		maxFrameCount = 0, showDebuffTypeBorder = true, layout = {elementWidth = size, elementHeight = size},
	})
	self.Auras = auras
end

--===================================================--
-- Arena containers / 競技場光環容器
--===================================================--

local arenaBuffFilters = {
	"HELPFUL|BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE",
	"HELPFUL|EXTERNAL_DEFENSIVE",
	"HELPFUL|RAID_PLAYER_DISPELLABLE|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE",
}

T.CreateArenaAuras = function(self)
	local size, spacing = C.AuraSize, C.AuraSpacing
	local buffSize = size + 4
	
	local debuffs = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = size * 6 + spacing * (6 - 1),
		initialAnchor = "BOTTOMRIGHT", growthX = "LEFT", growthY = "UP",
	})
	debuffs:SetPoint("BOTTOMRIGHT", self.IconAnchor, "BOTTOMLEFT", -spacing*1.5, otherNameAuraY)
	
	local buffs = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Vertical, layoutLimit = buffSize * 2 + spacing,
		initialAnchor = "BOTTOMLEFT", growthX = "RIGHT", growthY = "UP",
	})
	buffs:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -spacing/2, spacing*2.5)
	
	for _, element in ipairs({debuffs, buffs}) do
		element:SetFrameLevel(self:GetFrameLevel() + 4)
		element.PostCreateButton = PostCreateAuraButton
		element.showCount = true
		element.showDuration = true
		element.disableCooldown = true
		element.durationFormatter = durationFormatter
		element.sortMethod = AuraContainerSortMethod.Default
		element.elementSpacing = spacing
		element.lineSpacing = spacing
	end
	debuffs.size, buffs.size = size, buffSize
	debuffs.tooltipAnchor, buffs.tooltipAnchor = "ANCHOR_TOPLEFT", "ANCHOR_BOTTOMRIGHT"
	
	debuffs:AddGroup("HARMFUL|PLAYER|!CROWD_CONTROL", {
		maxFrameCount = 4, showDebuffTypeBorder = true,
		layout = {elementWidth = size, elementHeight = size},
	})
	debuffs:AddGroup("HARMFUL|CROWD_CONTROL", {
		maxFrameCount = 2, showDebuffTypeBorder = true,
		layout = {elementWidth = size, elementHeight = size},
	})
	for _, filter in ipairs(arenaBuffFilters) do
		buffs:AddGroup(filter, {
			maxFrameCount = 2, layout = {elementWidth = buffSize, elementHeight = buffSize},
		})
	end
	self.Buffs, self.Debuffs = buffs, debuffs
end

--===================================================--
-- Boss containers / 首領光環容器
--===================================================--

T.CreateBossAuras = function(self)
	local size, spacing = C.AuraSize, C.AuraSpacing
	local buffSize = size + 4
	
	local debuffs = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = size * 6 + spacing * (6 - 1),
		initialAnchor = "BOTTOMRIGHT", growthX = "LEFT", growthY = "UP",
	})
	debuffs:SetPoint("BOTTOMRIGHT", self.IconAnchor, "BOTTOMLEFT", -spacing*1.5, otherNameAuraY)
	
	local buffs = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Vertical, layoutLimit = buffSize * 2 + spacing,
		initialAnchor = "BOTTOMLEFT", growthX = "RIGHT", growthY = "UP",
	})
	buffs:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -spacing/2, spacing*2.5)
	
	for _, element in ipairs({debuffs, buffs}) do
		element:SetFrameLevel(self:GetFrameLevel() + 4)
		element.PostCreateButton = PostCreateAuraButton
		element.showCount = true
		element.showDuration = true
		element.disableCooldown = true
		element.durationFormatter = durationFormatter
		element.sortMethod = AuraContainerSortMethod.Default
		element.elementSpacing = spacing
		element.lineSpacing = spacing
	end
	debuffs.size, buffs.size = size, buffSize
	debuffs.tooltipAnchor, buffs.tooltipAnchor = "ANCHOR_TOPLEFT", "ANCHOR_BOTTOMRIGHT"

	debuffs:AddGroup("HARMFUL|PLAYER", {
		maxFrameCount = 6, showDebuffTypeBorder = true,
		layout = {elementWidth = size, elementHeight = size},
	})
	buffs:AddGroup("HELPFUL", {
		maxFrameCount = 4, layout = {elementWidth = buffSize, elementHeight = buffSize},
	})
	self.Buffs, self.Debuffs = buffs, debuffs
end

--===================================================--
-- Party containers / 隊伍光環容器
--===================================================--

T.CreatePartyAuras = function(self)
	local size, spacing = C.AuraSize, C.AuraSpacing
	local debuffSize = size + 4
	local buffWhiteList = (G.IsForever and C.PartyBuffWhiteList_Forever) or C.PartyBuffWhiteList_Retail
	
	local buffs = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = size * 4 + spacing * (4 - 1),
		initialAnchor = "BOTTOMRIGHT", growthX = "LEFT", growthY = "UP",
	})
	buffs:SetPoint("BOTTOMRIGHT", self.IconAnchor, "BOTTOMLEFT", -spacing*1.5, otherNameAuraY)
	
	local debuffs = self:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Vertical, layoutLimit = debuffSize * 2 + spacing,
		initialAnchor = "BOTTOMLEFT", growthX = "RIGHT", growthY = "UP",
	})
	debuffs:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -spacing/2, spacing*2.5)
	
	for _, element in ipairs({buffs, debuffs}) do
		element:SetFrameLevel(self:GetFrameLevel() + 4)
		element.PostCreateButton = PostCreateAuraButton
		element.showCount = true
		element.showDuration = true
		element.disableCooldown = true
		element.durationFormatter = durationFormatter
		element.sortMethod = AuraContainerSortMethod.Default
		element.elementSpacing = spacing
		element.lineSpacing = spacing
	end
	buffs.size, debuffs.size = size, debuffSize
	buffs.tooltipAnchor, debuffs.tooltipAnchor = "ANCHOR_TOPLEFT", "ANCHOR_BOTTOMRIGHT"
	
	buffs:AddGroup("HELPFUL", {
		candidateFilters = {includeSpellIDs = buffWhiteList}, maxFrameCount = 4,
		layout = {elementWidth = size, elementHeight = size},
	})
	
	debuffs:AddGroup("HARMFUL", {
		maxFrameCount = 4, showDebuffTypeBorder = true,
		layout = {elementWidth = debuffSize, elementHeight = debuffSize},
	})
	self.Buffs, self.Debuffs = buffs, debuffs
end
