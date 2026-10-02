-----------------------------
-- Setup / 插件內部設定 --
-----------------------------

local addon, ns = ...

	-- Shared tables for Hankk files / Hankk 各檔案共用的表格
	ns[1] = {} -- C: settings / 設定
	ns[2] = {} -- F: shared functions / 共用函式
	ns[3] = {} -- G: shared data and media / 共用資料與素材
	ns[4] = {} -- T: oUF helpers / oUF 輔助函式
	ns[5] = {} -- L: translated text / 各語言文字

local F, G = ns[2], ns[3]

	-- Decide the client once so Hankk features use the same Forever boundary.
	-- 只在這裡判斷遊戲版本，讓各項 FOREVER 功能使用相同依據。
	G.IsForever = LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC

	G.MediaFolder = "Interface\\AddOns\\"..addon.."\\Media\\"

local MediaFolder = G.MediaFolder

------------------------
-- Textures / 材質 --
------------------------

	-- Texture here; sizes and colors in Config.lua.
	-- 材質在這裡；大小和顏色在 Config.lua。
	G.media = {
		blank = "Interface\\Buttons\\WHITE8X8",
		glow = MediaFolder.."Textures\\glow.tga",				-- Soft frame shadow / 柔邊陰影
		info = "Interface\\FriendsFrame\\InformationIcon",		-- Option help / 選項說明
		
		aurashadow = MediaFolder.."Textures\\aurashadow.tga",	-- Aura icon shadow / 光環圖示陰影
        spark = MediaFolder.."Textures\\spark.tga",				-- Cast progress highlight / 施法進度亮光
		
        digitbase = MediaFolder.."Textures\\Symbols\\Digits_base.tga",   -- Digit bases and health icons / 字底與血量圖示
		digitfill = MediaFolder.."Textures\\Symbols\\Digits_fill.tga",   -- Water fill / 數字內的水位填色
		digitglow = MediaFolder.."Textures\\Symbols\\Digits_glow.tga",   -- Tintable icon halo / 可染色的圖示柔光

		raidicon = MediaFolder.."Textures\\raidicons.blp",      -- Raid markers / 團隊標記
		statusicons = MediaFolder.."Textures\\statusicons.tga", -- Status icons / 狀態圖示

		-- Spec / 專精
		specbase1 = MediaFolder.."Textures\\Icons\\Spec_base-1.tga", -- 灰底
		specbase2 = MediaFolder.."Textures\\Icons\\Spec_base-2.tga",
		specfill1 = MediaFolder.."Textures\\Icons\\Spec_fill-1.tga", -- 填色
		specfill2 = MediaFolder.."Textures\\Icons\\Spec_fill-2.tga",
		specglow1 = MediaFolder.."Textures\\Icons\\Spec_glow-1.tga", -- 光暈
		specglow2 = MediaFolder.."Textures\\Icons\\Spec_glow-2.tga",

		-- Party roles / 隊伍職責
		role_tank = MediaFolder.."Textures\\Icons\\role_Tank.tga",
		role_healer = MediaFolder.."Textures\\Icons\\role_Healer.tga",
		role_dps = MediaFolder.."Textures\\Icons\\role_DPS.tga",

		-- PvP icons / PvP 圖示
		pvp_alliance = MediaFolder.."Textures\\Icons\\Factions_alliance.tga",
		pvp_horde = MediaFolder.."Textures\\Icons\\Factions_horde.tga",

		-- Classic power
        combo = MediaFolder.."Textures\\Resources\\combo.tga",          -- Combo points / 連擊點、龍能與符文
        arcane = MediaFolder.."Textures\\Resources\\arcane.tga",        -- Mage orb / 秘法充能
		holypower = MediaFolder.."Textures\\Resources\\holypower.tga",  -- Holy power / 聖能
		soulshards = MediaFolder.."Textures\\Resources\\soulshards.tga",-- Soul shard / 靈魂碎片
		tipspear = MediaFolder.."Textures\\Resources\\tipspear.tga",  -- Tip of the Spear / 生存獵長矛之尖
		totems = MediaFolder.."Textures\\Resources\\totems.tga",        -- Maelstrom Weapon / 漩渦武器充能柱
	}

	-- Fixed icons share the 4x4 digit atlases; cell 11 stays empty for hidden leading digits.
	-- 固定圖示共用 4×4 數字圖集；第 11 格保留空白，用來省略前導數字。
	G.HealthIconCells = {death = 12, ghost = 13, offline = 14, skull = 15, percent = 16}

-------------------------------------
-- GUI options / 圖形介面選項 --
-------------------------------------

	F.GUIOptionSections = {
		{name = "Style", options = {
			{key = "SmallFocus", default = true, tooltip = "SmallFocusDesc"},
			{key = "ClassColorDigits", default = false, tooltip = "ClassColorDigitsTip"},
			{key = "CurrentValuesOnly", default = false, tooltip = "CurrentValuesOnlyTip"},
			{key = "DesaturateOtherDebuffs", default = not G.IsForever, tooltip = "DesaturateOtherDebuffsTip", foreverOnly = false},
			{key = "ShowFirstNameOnly", default = false, foreverOnly = true},
		}},
		{name = "Frames", options = {
			{key = "Arena", default = false, foreverOnly = false},
			{key = "Boss", default = false},
			{key = "Party", default = false},
			{key = "HideCompactRaidManager", default = true, tooltip = "HideCompactRaidManagerTip"},
		}},
		{name = "Elements", options = {
			{key = "PlayerResources", default = true},
			{key = "PlayerTotems", default = true},
			{key = "Fade", default = true, tooltip = "FadeTip"},
			{key = "ShowTargetLevel", default = false, tooltip = "TargetLevelTip"},
			{key = "ThreatHighlight", default = true},
		}},
	}

	local optionMap, activeOptions = {}, {}
	for _, section in ipairs(F.GUIOptionSections) do
		for _, option in ipairs(section.options) do
			optionMap[option.key] = option
		end
	end

	F.IsHankkOptionAvailable = function(option)
		return option.foreverOnly == nil or option.foreverOnly == G.IsForever
	end

	local function GetOptionsDB()
		if type(HankkDB) ~= "table" then HankkDB = {} end
		if type(HankkDB.Options) ~= "table" then HankkDB.Options = {} end
		return HankkDB.Options
	end

	F.GetSavedHankkOption = function(key)
		local option = optionMap[key]
		if not option then return end
		if not F.IsHankkOptionAvailable(option) then return option.default end
		local value = GetOptionsDB()[key]
		if type(value) ~= "boolean" then return option.default end
		return value
	end

	-- Runtime reads a snapshot. GUI edits wait until the next reload.
	-- 執行中的框架只讀啟動時的設定；GUI 修改等下次重載才套用。
	F.GetHankkOption = function(key)
		return activeOptions[key]
	end

	F.SetHankkOption = function(key, value)
		local option = optionMap[key]
		if not option or not F.IsHankkOptionAvailable(option) then return end
		GetOptionsDB()[key] = value == true
	end

	F.ResetHankkOptions = function()
		local db = GetOptionsDB()
		for key, option in pairs(optionMap) do db[key] = option.default end
	end

	local dbLoader = CreateFrame("Frame")
	dbLoader:RegisterEvent("ADDON_LOADED")
	dbLoader:SetScript("OnEvent", function(self, event, name)
		if name ~= addon then return end
		local db = GetOptionsDB()
		for key in pairs(db) do
			if not optionMap[key] then db[key] = nil end
		end
		for key in pairs(optionMap) do
			local value = F.GetSavedHankkOption(key)
			db[key], activeOptions[key] = value, value
		end
		self:UnregisterEvent(event)
		self:SetScript("OnEvent", nil)
	end)
