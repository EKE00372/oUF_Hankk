local _, ns = ...
local C, G = ns[1], ns[3]

local MediaFolder = G.MediaFolder

-------------------------------
-- User settings / 使用者設定 --
-------------------------------

	-- Use /hankk for feature switches; edit these sizes and colors, then /reload.
	-- 功能開關用 /hankk；下方大小與顏色可手動修改，再輸入 /reload 套用。

-----------
-- Fonts --
-----------

	-- Font
	G.Font = MediaFolder.."Fonts\\HankkSansDIN.ttf"

	-- Font Flag, "THICKOUTLINE", "OUTLINE", "NONE"
    G.FontFlag = "THICKOUTLINE"	-- General text outline / 一般文字描邊
	G.AuraFontFlag = "OUTLINE"	-- Aura text outline / 光環文字描邊
	
	-- Font size
    G.NameFS = 26		-- Unit name / 名字
	G.ValueFS = 20		-- Health/power value / 血量與能量數值

	G.OtherFS = 20		-- Party/Boss/Arena / 首領、競技場及隊友
	G.OtherTextLineGap = 2	-- Gap between the two text rows / 名字與數值兩行的間距
	G.SubFS = 16		-- Pet and ToT/ToTT/FoT/FoTT / 寵物/目標的目標鏈/焦點的目標鏈

	G.AuraFS = 14		-- Aura / 光環
	G.CastbarFS = 16	-- Spell / 施法條

------------------------
-- UnitFrame settings --
------------------------

	-- Size / 尺寸

	C.DigitSize = 80	-- Main-frame digit and status icon size / 主框數字與狀態圖示尺寸
	C.SubWidth = 130	-- Pet and target-chain click area width / 寵物與目標鏈可點擊寬度

	C.BossSize = 80		-- Boss and arena health icon / 首領與競技場圖示
	C.PartySize = 80	-- Party spec health icon / 隊友專精圖示
	C.InfoWidth = 130	-- Boss/arena/party name width / 首領、競技場及隊友名字區域總寬
	
	C.RaidIconSize = 24	-- Raid icon / 團隊標記
	C.StatusSize = 24	-- Player status / 玩家狀態圖示

	-- Colors / 顏色

	C.HealthColor = {1, 0.65, 0.16}		-- Main health percent digits / 主體血量百分比顏色
	C.SubHealthColor = {1, 0.65, 0.16}	-- Pet and ToT/ToTT/FoT/FoTT / 寵物/目標的目標鏈/焦點的目標鏈
	C.TextColor = {1, 1, 1}				-- Base text color / 文字底色
	
	C.PlayerStatusColors = {
		Role = {1, 0.82, 0.36},		-- Leader and assistant / 隊長與助理
		Resting = {0.47, 0.75, 1},	-- Resting / 休息
		Combat = {1, 0.39, 0.3},	-- Combat / 戰鬥
	}

	-- Fading / 淡出
	C.FadeOutAlpha = 0		-- Faded opacity: 0 hidden, 1 fully visible / 淡出後透明度：0 隱藏，1 完全顯示

----------------------------
-- Castbar settings / 施法條設定 --
----------------------------

	C.CastbarWidth = 132			-- Player and target castbar width / 玩家與目標施法條寬度
	C.CastNormal = {1, 0.65, 0.16}	-- Normal castbar / 普通施法條
	C.CastShield = {1, 0.31, 0.2}	-- Cannot be interrupted / 不可打斷施法條
	C.CastFailed = {1, 0.31, 0.2}	-- Failed or interrupted / 失敗或被打斷

----------------------------------
-- Auras / 光環 --
----------------------------------

	C.AuraSize = 20		-- Icon size; both buffs and debuffs / 增益與減益的圖示大小
	C.AuraSpacing = 6	-- Spacing between icons and rows / 圖示間距

	C.TargetAurasPerRow = 10	-- Slots in each row / 每行光環數
	C.TargetMaxAuras = 40		-- Max aura count / 最大光環數量
	C.TargetMaxBuffs = 10		-- Max buff count / 最大增益數量

----------------------------------
-- Position settings / 位置設定 --
----------------------------------

	-- Frame point, reference frame, reference point, X, Y. Positive X moves right; positive Y moves up.
	-- 依序是框體對齊點、參考框體、參考點、左右距離、上下距離。正數往右或往上。
	C.Position = {
		-- Player = {"RIGHT", UIParent, "CENTER", -220, -180},
		Pet = {"BOTTOMRIGHT", "oUF_HankkPlayer", "TOPRIGHT", -12, -4},
		
		-- Target = {"LEFT", UIParent, "CENTER", 220, -180},
		TOT = {"BOTTOMLEFT", "oUF_HankkTarget", "TOPLEFT", 24, -4},
		TOTT = {"BOTTOMLEFT", "oUF_HankkToT", "TOPLEFT", 0, 0},

		-- Focus = {"CENTER", UIParent, "CENTER", 0, -270},
		FOT = {"BOTTOMLEFT", "oUF_HankkFocus", "TOPLEFT", 24, -4},
		FOTT = {"BOTTOMLEFT", "oUF_HankkFoT", "TOPLEFT", 0, 0},
		
		-- Boss = {"RIGHT", UIParent, "RIGHT", -140, 185},
		-- Arena = {"RIGHT", UIParent, "RIGHT", -140, 185},
		-- Party = {"BOTTOMRIGHT", "oUF_HankkPlayer", "TOPRIGHT", -64, 60},
	}
