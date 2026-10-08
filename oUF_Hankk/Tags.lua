local _, ns = ...
local oUF = ns.oUF
local F, G = ns[2], ns[3]

local UnitIsTapDenied, UnitIsPlayer, UnitReaction = UnitIsTapDenied, UnitIsPlayer, UnitReaction
local UnitInPartyIsAI = UnitInPartyIsAI
local UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax = UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax
local UnitPowerPercent = UnitPowerPercent
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitClassification, UnitEffectiveLevel = UnitClassification, UnitEffectiveLevel
local GetContentDifficultyCreatureForPlayer = C_PlayerInfo.GetContentDifficultyCreatureForPlayer
local GetDifficultyColor = GetDifficultyColor
local format = string.format
local FormatZero = F.FormatZero

--===================================================--
-- Threat colors / 仇恨顏色
--===================================================--

oUF.colors.threat[1] = oUF:CreateColor(.4, .1, .9) -- 尚未承擔，但仇恨已超過承擔者
oUF.colors.threat[2] = oUF:CreateColor(.9, .1, .9) -- 正承擔仇恨，但不穩定
oUF.colors.threat[3] = oUF:CreateColor(.9, .1, .4) -- 穩定承擔仇恨

--===================================================--
-- Power colors / 能量顏色
--===================================================--

local function ReplacePowerColor(name, index, r, g, b)
	oUF.colors.power[name] = oUF:CreateColor(r, g, b)
	oUF.colors.power[index] = oUF.colors.power[name]
end

ReplacePowerColor("MANA", 0, 0, .8, 1)					-- 法力
ReplacePowerColor("RAGE", 1, .9, .1, .1)				-- 怒氣
ReplacePowerColor("FOCUS", 2, .9, .5, .1)				-- 集中值
ReplacePowerColor("ENERGY", 3, .9, .9, .1)				-- 能量
ReplacePowerColor("RUNIC_POWER", 6, .1, .9, .9)			-- 符能
ReplacePowerColor("SOUL_SHARDS", 7, .87, .47, 1)		-- 術士靈魂碎片
ReplacePowerColor("LUNAR_POWER", 8, 0, .6, 1)			-- 星界能量
ReplacePowerColor("MAELSTROM", 11, 0, .6, 1)			-- 漩渦值
ReplacePowerColor("INSANITY", 13, .74, .35, .95)		-- 瘋狂值
ReplacePowerColor("ARCANE_CHARGES", 16, 0, .8, 1)		-- 秘法充能
ReplacePowerColor("ESSENCE", 19, .02, .9, .9)			-- 精華
oUF.colors.power.FUEL = oUF:CreateColor(0, .75, .7)		-- 燃料
oUF.colors.power.AMMOSLOT = oUF:CreateColor(.8, .6, 0)	-- 彈藥
oUF.colors.power.TIP_OF_THE_SPEAR = oUF:CreateColor(166/255, 242/255, 84/255) -- 長矛之尖
oUF.colors.power.SOUL_FRAGMENTS = {						-- DH 靈魂碎片
	oUF:CreateColor(.87, .47, 1), -- 一般狀態
	oUF:CreateColor(.5, .62, 1), -- 虛空變身
}

--===================================================--
-- Values / 數值
--===================================================--

oUF.Tags.Methods["hankk:altpower"] = function()
	local power = _FRAME.AlternativePower
	if power then return power.valueText end
end

-- 血量：當前值/最大值
oUF.Tags.Methods["hankk:health"] = function(unit)
	local current = F.NumberAbbrValue(UnitHealth(unit))
	if F.GetHankkOption("CurrentValuesOnly") then return current end

	return format("%s/%s", current, F.NumberAbbrValue(UnitHealthMax(unit)))
end
oUF.Tags.Events["hankk:health"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

-- 吸收盾：縮寫數值
oUF.Tags.Methods["hankk:absorbs"] = function(unit)
	local amount = UnitGetTotalAbsorbs(unit)
	return FormatZero(amount, F.NumberAbbrValue(amount))
end
oUF.Tags.Events["hankk:absorbs"] = "UNIT_ABSORB_AMOUNT_CHANGED"

-- 能量：當前值/最大值
oUF.Tags.Methods["hankk:power"] = function(unit)
	local current = F.NumberAbbrValue(UnitPower(unit))
	
	if F.GetHankkOption("CurrentValuesOnly") then return current end
	return format("%s/%s", current, F.NumberAbbrValue(UnitPowerMax(unit)))
end
oUF.Tags.Events["hankk:power"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_CONNECTION"

-- 首領與競技場能量：當前值
oUF.Tags.Methods["hankk:otherpower"] = function(unit)
	local amount = UnitPower(unit)
	local text = C_StringUtil.WrapString(F.NumberAbbrValue(amount), nil, "|r ||")
	return FormatZero(amount, text)
end
oUF.Tags.Events["hankk:otherpower"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_CONNECTION"

-- 治療隊友法力：百分比
local partyManaColor = oUF.colors.power.MANA:GenerateHexColorMarkup()
oUF.Tags.Methods["hankk:partypower"] = function(unit)
	local role = UnitGroupRolesAssigned(_FRAME.PartyUnit)
	if role ~= "HEALER" then return "" end

	local mana = UnitPower(unit, Enum.PowerType.Mana)
	local percent = UnitPowerPercent(unit, Enum.PowerType.Mana, false, CurveConstants.ScaleTo100)
	local text = format((F.GetHankkOption("CurrentValuesOnly") and "%s%d|r ||") or "%s%d%%|r ||", partyManaColor, percent)
	return FormatZero(mana, text)
end
oUF.Tags.Events["hankk:partypower"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_CONNECTION GROUP_ROSTER_UPDATE PLAYER_ROLES_ASSIGNED ROLE_CHANGED_INFORM"
oUF.Tags.SharedEvents.PLAYER_ROLES_ASSIGNED = true
oUF.Tags.SharedEvents.ROLE_CHANGED_INFORM = true

--===================================================--
-- Target level / 目標等級
--===================================================--

oUF.Tags.Methods["hankk:level"] = function(unit)
	local level = oUF.Tags.Methods.level(unit)
	if level == UnitEffectiveLevel("player") then return end	-- 與玩家同級時隱藏

	local classification = UnitClassification(unit)
	local suffix = ""
	if classification == "worldboss" or classification == "rareelite"
		or classification == "elite" or classification == "rare" then
		suffix = "+"
	end
	local color = GetDifficultyColor(GetContentDifficultyCreatureForPlayer(unit))

	-- 血量前還原顏色
	return format("|cff%02x%02x%02x%s%s|r ", color.r * 255, color.g * 255, color.b * 255, level, suffix)
end
oUF.Tags.Events["hankk:level"] = "UNIT_LEVEL PLAYER_LEVEL_UP PLAYER_LEVEL_CHANGED UNIT_CLASSIFICATION_CHANGED UNIT_FACTION"
-- 玩家這個事件傳來的是等級數字，不是單位名稱；讓 oUF 也更新目標文字。
oUF.Tags.SharedEvents.PLAYER_LEVEL_CHANGED = true

--===================================================--
-- Name color / 名字顏色
--===================================================--

-- 順序：被別人標記、玩家或 AI 隊友職業，最後是一般 NPC 敵我關係。
oUF.Tags.Methods["hankk:namecolor"] = function(unit)
	if UnitIsTapDenied(unit) then
		return oUF.colors.tapped:GenerateHexColorMarkup()
	elseif UnitIsPlayer(unit) or UnitInPartyIsAI(unit) then
		return oUF.Tags.Methods.raidcolor(unit)
	end

	local reaction = UnitReaction(unit, "player")
	if reaction then
		return oUF.colors.reaction[reaction]:GenerateHexColorMarkup()
	end

	return "|cffffffff"
end
oUF.Tags.Events["hankk:namecolor"] = "UNIT_NAME_UPDATE UNIT_FACTION"

-- FOREVER 會分別提供名字與姓氏。未啟用選項時維持全名；
-- 其他版本繼續使用 oUF 原有的名字標籤。
G.NameTag = "[name]"
if G.IsForever then
	G.NameTag = "[hankk:forevername]"
	oUF.Tags.Methods["hankk:forevername"] = function(unit, realUnit)
		local displayedUnit = realUnit or unit
		if F.GetHankkOption("FirstNameOnly") then
			return UnitNameUnmodified(displayedUnit)
		end
		return NameUtil.GetUnmodifiedUnitFullName(displayedUnit)
	end
	oUF.Tags.Events["hankk:forevername"] = "UNIT_NAME_UPDATE"
end

-- FOREVER 獵人寵物心情值
local petHappinessFaces = {":<", ":||", ":D"}
oUF.Tags.Methods["hankk:pethappiness"] = function(unit)
	if unit ~= "pet" then return end

	local happiness = C_PetInfo.GetPetHappiness()
	local face = petHappinessFaces[happiness]
	if face then
		return oUF.colors.happiness[happiness]:GenerateHexColorMarkup() .. face .. "|r "
	end
end
oUF.Tags.Events["hankk:pethappiness"] = "UNIT_HAPPINESS UNIT_PET"
