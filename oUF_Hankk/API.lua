local _, ns = ...
local F, G = ns[2], ns[3]

local CreateAbbreviateConfig, AbbreviateNumbers = CreateAbbreviateConfig, AbbreviateNumbers
local format = string.format
local WrapString = C_StringUtil.WrapString
local TruncateWhenZero = C_StringUtil.TruncateWhenZero
local StripHyperlinks = C_StringUtil.StripHyperlinks

--===================================================--
-- Number format / 數值格式
--===================================================--

local NumberAbbrConfig = {
	config = CreateAbbreviateConfig({
		{breakpoint = 1e9, abbreviation = "b", significandDivisor = 1e5, fractionDivisor = 1e4, abbreviationIsGlobal = false},
		{breakpoint = 1e6, abbreviation = "m", significandDivisor = 1e4, fractionDivisor = 1e2, abbreviationIsGlobal = false},
		{breakpoint = 1e5, abbreviation = "k", significandDivisor = 1e3, fractionDivisor = 1, abbreviationIsGlobal = false},
		{breakpoint = 1e3, abbreviation = "k", significandDivisor = 1e2, fractionDivisor = 1e1, abbreviationIsGlobal = false},
	})
}

F.NumberAbbrValue = function(value)
	return AbbreviateNumbers(value, NumberAbbrConfig)
end

-- 零值留空判斷：原始值1但百分比0%，不留空
F.FormatZero = function(amount, text)	-- 原始數值，縮寫或百分比格式
	local label = format("|h%s|h", text)	-- 取得文字，例如 |h0%|h
	local link = WrapString(TruncateWhenZero(amount), "|Hitem:", label)	-- 判斷留空，|Hitem:1|h0%|h

	-- text: 要處理的字串, maintainColor: 色碼|c與|r, maintainBrackets: 方括號[], stripNewlines: 換行標記|n, maintainAtlases: atlas材質|A|a, maintainTextures: 材質|T|t)
	return StripHyperlinks(link, true, false, false, false, true)
end

--===================================================--
-- Text / 文字
--===================================================--

-- 所有文字共用同一字型；光環文字可使用獨立描邊。
F.SetTextFont = function(text, fontsize, justify, flag)
	text:SetFont(G.Font, fontsize, flag or G.FontFlag)
	text:SetShadowOffset(0, 0)
	text:SetWordWrap(false)
	text:SetJustifyH(justify)
end

F.CreateText = function(parent, fontsize, justify, flag)
	local text = parent:CreateFontString(nil, "OVERLAY")
	F.SetTextFont(text, fontsize, justify, flag)
	return text
end

--===================================================--
-- Shadow / 陰影
--===================================================--

F.CreateSD = function(parent, anchor, size, r, g, b, a)
	local shadow = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	shadow:SetPoint("TOPLEFT", anchor, "TOPLEFT", -size, size)
	shadow:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", size, -size)
	shadow:SetFrameLevel(math.max(0, parent:GetFrameLevel() - 1))
	shadow:SetBackdrop({edgeFile = G.media.glow, edgeSize = size})
	shadow:SetBackdropBorderColor(r or .05, g or .05, b or .05, a or 1)
	return shadow
end
