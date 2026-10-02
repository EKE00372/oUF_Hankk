local _, ns = ...
local C = ns[1]

C.PartyBuffWhiteList_Retail = {

    -- Racial / 種族

    [58984] = true,      -- [輔助] 影遁 / Shadowmeld

    -- Death Knight / 死亡騎士

    [48707] = true,      -- [個人] 反魔法護罩 / Anti-Magic Shell
    [444741] = true,     -- [個人] 反魔法護罩 / Anti-Magic Shell
    [48792] = true,      -- [個人] 冰錮堅韌 / Icebound Fortitude
    -- [49039] = true,   -- [個人] 巫妖之軀 / Lichborne
    [55233] = true,      -- [個人] 血族之裔 / Vampiric Blood
    -- [101568] = true,  -- [個人] 黑暗救贖 / Dark Succor
    [145629] = true,     -- [團隊] 反魔法力場 / Anti-Magic Zone
    [48265] = true,      -- [輔助] 死神逼近 / Death's Advance
    [212552] = true,     -- [輔助] 闇境靈行 / Wraith Walk
    [444347] = true,     -- [輔助] 死亡戰騎 / Death Charge
    [3714] = true,       -- [輔助] 冰霜之徑 / Path of Frost

    -- Demon Hunter / 惡魔獵人

    -- [442715] = true,  -- [個人] 刃禦 / Blade Ward
    [212800] = true,     -- [個人] 殘影 / Blur
    -- [1266616] = true, -- [個人] 惡魔靜默 / Demon Muzzle
    -- [427912] = true,  -- [個人] 獻祭光環 / Immolation Aura
    -- [258920] = true,  -- [個人] 獻祭光環 / Immolation Aura
    [187827] = true,     -- [個人] 惡魔化身 / Metamorphosis
    [207771] = true,     -- [個人] 熾炎烙印 / Fiery Brand
    [209426] = true,     -- [團隊] 黑暗 / Darkness

    -- Druid / 德魯伊

    [22812] = true,      -- [個人] 樹皮術 / Barkskin
    [22842] = true,      -- [個人] 狂暴恢復 / Frenzied Regeneration
    -- [192081] = true,  -- [個人] 鋼鐵毛皮 / Ironfur
    [61336] = true,      -- [個人] 求生本能 / Survival Instincts
    [393903] = true,     -- [個人] 熊之活力 / Ursine Vigor
    [1261872] = true,    -- [個人] 野性之心 / Heart of the Wild
    [102558] = true,     -- [個人] 化身：厄索克守護者 / Incarnation: Guardian of Ursoc
    [740] = true,        -- [團隊] 寧靜 / Tranquility
    [117679] = true,     -- [團隊] 化身：生命之樹 / Incarnation: Tree of Life
    [102342] = true,     -- [輔助] 鐵樹皮術 / Ironbark
    [1850] = true,       -- [輔助] 突進 / Dash
    [106898] = true,     -- [輔助] 奔竄咆哮 / Stampeding Roar
    [77761] = true,      -- [輔助] 奔竄咆哮 / Stampeding Roar
    [77764] = true,      -- [輔助] 奔竄咆哮 / Stampeding Roar
    [252216] = true,     -- [輔助] 虎豹突進 / Tiger Dash
    [5215] = true,       -- [輔助] 潛行 / Prowl
    -- [340546] = true,  -- [輔助] 堅定追擊 / Tireless Pursuit
    -- [400126] = true,  -- [輔助] 森林漫步 / Forestwalk
    [29166] = true,      -- [輔助] 啟動 / Innervate

    -- Evoker / 喚能師

    [404381] = true,     -- [個人] 抗拒命運 / Defy Fate
    [363916] = true,     -- [個人] 黑曜鱗片 / Obsidian Scales
    [374349] = true,     -- [個人] 再生烈焰 / Renewing Blaze
    -- [359816] = true,  -- [團隊] 夢境飛翔 / Dream Flight
    [363534] = true,     -- [團隊] 時光倒轉 / Rewind
    [374227] = true,     -- [團隊] 輕風 / Zephyr
    [357170] = true,     -- [輔助] 時間擴張 / Time Dilation
    -- [373267] = true,  -- [輔助] 生命守縛 / Lifebind
    [358267] = true,     -- [輔助] 盤旋 / Hover
    [358733] = true,     -- [輔助] 滑翔 / Glide
    [370889] = true,     -- [輔助] 雙生守護者 / Twin Guardian
    [375234] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375226] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375229] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375230] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375238] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375240] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375252] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375253] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375254] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375255] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375256] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375257] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375258] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [406732] = true,     -- [輔助] 空間悖論 / Spatial Paradox
    [406789] = true,     -- [輔助] 空間悖論 / Spatial Paradox

    -- Hunter / 獵人

    [186265] = true,     -- [個人] 巨龜守護 / Aspect of the Turtle
    [202748] = true,     -- [個人][PvP] 求生戰術 / Survival Tactics
    [472708] = true,     -- [個人] 龜殼掩護 / Shell Cover
    [264735] = true,     -- [個人] 適者生存 / Survival of the Fittest
    [53480] = true,      -- [輔助] 犧牲咆哮 / Roar of Sacrifice
    [186257] = true,     -- [輔助] 獵豹守護 / Aspect of the Cheetah
    [186258] = true,     -- [輔助] 獵豹守護 / Aspect of the Cheetah
    [118922] = true,     -- [輔助] 疾影術 / Posthaste
    [5384] = true,       -- [輔助] 假死 / Feign Death
    [199483] = true,     -- [輔助] 偽裝 / Camouflage
    [1267208] = true,    -- [輔助] 把握良機 / Moment of Opportunity
    [1224810] = true,    -- [輔助] 主人的呼喚 / Master's Call
    [54216] = true,      -- [輔助] 主人的呼喚 / Master's Call
    [62305] = true,      -- [輔助] 主人的呼喚 / Master's Call

    -- Mage / 法師

    [342246] = true,     -- [個人] 時光倒轉 / Alter Time
    -- [235313] = true,  -- [個人] 熾炎屏障 / Blazing Barrier
    -- [11426] = true,   -- [個人] 寒冰護體 / Ice Barrier
    [45438] = true,      -- [個人] 寒冰屏障 / Ice Block
    [414658] = true,     -- [個人] 冰脈鎮體 / Ice Cold
    -- [235450] = true,  -- [個人] 稜彩屏障 / Prismatic Barrier
    [449336] = true,     -- [個人] 愈挫愈勇 / Merely a Setback
    [1309793] = true,    -- [個人] 增幅折射 / Amplified Refraction
    [444754] = true,     -- [輔助] 滑溜拋法 / Slippery Slinging
    [130] = true,        -- [輔助] 緩落術 / Slow Fall
    [55342] = true,      -- [輔助] 鏡像 / Mirror Image
    [108843] = true,     -- [輔助] 熾烈迅捷 / Blazing Speed
    [66] = true,         -- [輔助] 隱形術（漸隱）/ Invisibility
    [32612] = true,      -- [輔助] 隱形術（完全隱形）/ Invisibility
    [110960] = true,     -- [輔助] 強效隱形 / Greater Invisibility
    [382294] = true,     -- [輔助] 迅捷咒術 / Incantation of Swiftness

    -- Monk / 武僧

    [122783] = true,     -- [個人] 祛魔訣 / Diffuse Magic
    [120954] = true,     -- [個人] 石形絕釀 / Fortifying Brew
    [125174] = true,     -- [個人] 乾坤挪移 / Touch of Karma
    [132578] = true,     -- [個人] 召喚玄牛怒兆 / Invoke Niuzao, the Black Ox
    [322507] = true,     -- [個人] 天尊絕釀 / Celestial Brew
    [1241059] = true,    -- [個人] 星界灌注 / Celestial Infusion
    -- [432180] = true,  -- [個人] 風之舞 / Dance of the Wind
    [116849] = true,     -- [輔助] 氣繭護體 / Life Cocoon
    -- [119085] = true,  -- [輔助] 真氣飛龍穿 / Chi Torpedo
    -- [443569] = true,  -- [輔助] 赤吉迅捷 / Chi-Ji's Swiftness
    [116841] = true,     -- [輔助] 猛虎出閘 / Tiger's Lust
    -- [394112] = true,  -- [輔助] 逃離現實 / Escape from Reality
    -- [449609] = true,  -- [輔助] 身輕如燕 / Lighter Than Air

    -- Paladin / 聖騎士

    [498] = true,        -- [個人] 聖佑術 / Divine Protection
    [403876] = true,     -- [個人] 聖佑術 / Divine Protection
    [642] = true,        -- [個人] 聖盾術 / Divine Shield
    -- [184662] = true,  -- [個人] 復仇聖盾 / Shield of Vengeance
    [31850] = true,      -- [個人] 忠誠防衛者 / Ardent Defender
    [86659] = true,      -- [個人] 遠古諸王守護者 / Guardian of Ancient Kings
    [212641] = true,     -- [個人] 遠古諸王守護者 / Guardian of Ancient Kings
    [31821] = true,      -- [團隊] 精通光環 / Aura Mastery
    [317929] = true,     -- [團隊] 精通光環 / Aura Mastery
    [1022] = true,       -- [輔助] 保護祝福 / Blessing of Protection
    [6940] = true,       -- [輔助] 犧牲祝福 / Blessing of Sacrifice
    [204018] = true,     -- [輔助] 抗咒祝福 / Blessing of Spellwarding
    [387804] = true,     -- [輔助] 保護迴響 / Echoing Protection
    -- [276111] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221886] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221883] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [276112] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254474] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254472] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254471] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221885] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254473] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [363608] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [294133] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221887] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [453804] = true,  -- [輔助] 神性戰馬 / Divine Steed
    [1044] = true,       -- [輔助] 自由祝福 / Blessing of Freedom

    -- Priest / 牧師

    -- [114214] = true,  -- [個人] 天使之壁 / Angelic Bulwark
    [19236] = true,      -- [個人] 絕望禱言 / Desperate Prayer
    [47585] = true,      -- [個人] 影散 / Dispersion
    [586] = true,        -- [個人] 漸隱術 / Fade
    [45242] = true,      -- [個人] 意志專注 / Focused Will
    [426401] = true,     -- [個人] 意志專注 / Focused Will
    [193065] = true,     -- [個人] 保護之光 / Protective Light
    [27827] = true,      -- [個人] 救贖之靈（死亡）/ Spirit of Redemption
    [215769] = true,     -- [個人][PvP] 救贖之靈（主動）/ Spirit of Redemption
    [64843] = true,      -- [團隊] 神聖禮頌 / Divine Hymn
    [64844] = true,      -- [團隊] 神聖禮頌 / Divine Hymn
    [81782] = true,      -- [團隊] 真言術：壁 / Power Word: Barrier
    [47788] = true,      -- [輔助] 守護聖靈 / Guardian Spirit
    [33206] = true,      -- [輔助] 痛苦鎮壓 / Pain Suppression
    [10060] = true,      -- [輔助] 注入能量 / Power Infusion
    [121557] = true,     -- [輔助] 天使之羽 / Angelic Feather
    [65081] = true,      -- [輔助] 身心合一 / Body and Soul
    [111759] = true,     -- [輔助] 漂浮術 / Levitate

    -- Rogue / 盜賊

    [31224] = true,      -- [個人] 暗影披風 / Cloak of Shadows
    [5277] = true,       -- [個人] 閃避 / Evasion
    [1966] = true,       -- [個人] 佯攻 / Feint
    -- [185311] = true,  -- [個人] 赤紅藥瓶 / Crimson Vial
    [45182] = true,      -- [個人] 死亡謊言（觸發減傷）/ Cheating Death
    [2983] = true,       -- [輔助] 疾跑 / Sprint
    [1784] = true,       -- [輔助] 潛行 / Stealth
    [36554] = true,      -- [輔助] 暗影閃現 / Shadowstep
    [11327] = true,      -- [輔助] 消失 / Vanish
    [114018] = true,     -- [輔助] 隱蔽護罩 / Shroud of Concealment
    [115834] = true,     -- [輔助] 隱蔽護罩 / Shroud of Concealment

    -- Shaman / 薩滿

    [108271] = true,     -- [個人] 星界轉移 / Astral Shift
    [260881] = true,     -- [個人] 幽靈狼 / Spirit Wolf
    [325174] = true,     -- [團隊] 靈魂連結圖騰 / Spirit Link Totem
    [192082] = true,     -- [輔助] 疾風突進 / Wind Rush
    [79206] = true,      -- [輔助] 靈行者之賜 / Spiritwalker's Grace
    [58875] = true,      -- [輔助] 幽魂步伐 / Spirit Walk
    [2645] = true,       -- [輔助] 鬼魂之狼 / Ghost Wolf

    -- Warlock / 術士

    [108416] = true,     -- [個人] 黑暗契約 / Dark Pact
    [104773] = true,     -- [個人] 心志堅定 / Unending Resolve
    [132413] = true,     -- [個人] 暗影壁壘 / Shadow Bulwark
    [387636] = true,     -- [個人] 靈魂炙燃：治療石 / Soulburn: Healthstone
    [389614] = true,     -- [個人] 深淵行者 / Abyss Walker
    [212295] = true,     -- [個人][PvP] 虛空結界 / Nether Ward
    [111400] = true,     -- [輔助] 燃燒狂奔 / Burning Rush
    --[333889] = true,   -- [輔助] 惡魔支配 / Fel Domination
    --[387626] = true,   -- [輔助] 靈魂炙燃 / Soulburn
    [387633] = true,     -- [輔助] 靈魂炙燃：惡魔法陣 / Soulburn: Demonic Circle

    -- Warrior / 戰士

    [118038] = true,     -- [個人] 劍下亡魂 / Die by the Sword
    [184364] = true,     -- [個人] 狂怒恢復 / Enraged Regeneration
    [190456] = true,     -- [個人] 無視苦痛 / Ignore Pain
    [1277297] = true,    -- [個人] 無視苦痛 / Ignore Pain
    [147833] = true,     -- [個人] 阻擾 / Intervene
    [23920] = true,      -- [個人] 法術反射（反射效果）/ Spell Reflection (Reflect)
    --[385391] = true,     -- [個人] 法術反射（魔法減傷）/ Spell Reflection (Magic DR)
    [871] = true,        -- [個人] 盾牆 / Shield Wall
    -- [202147] = true,  -- [個人] 重新振作 / Second Wind
    [12975] = true,      -- [個人] 破釜沉舟 / Last Stand
    [97463] = true,      -- [團隊] 振奮咆哮 / Rallying Cry
    [202164] = true,     -- [輔助] 昂首闊步 / Bounding Stride
    [1244157] = true,    -- [輔助] 刺耳怒吼 / Piercing Howl

}

-- Include every listed rank because the aura spell ID changes as a classic spell ranks up.
-- 舊版法術升級後的光環 ID 會變，因此每個列出的等級都要納入。
C.PartyBuffWhiteList_Forever = {
    -- Druid / 德魯伊

    [22812] = true,     -- [個人] 樹皮術 / Barkskin
    [22842] = true,     -- [個人] 狂暴恢復1 / Frenzied Regeneration 1
    [22845] = true,     -- [個人] 狂暴恢復2 / Frenzied Regeneration 2
    [740] = true,       -- [團隊] 寧靜1 / Tranquility 1
    [8918] = true,      -- [團隊] 寧靜2 / Tranquility 2
    [9862] = true,      -- [團隊] 寧靜3 / Tranquility 3
    [9863] = true,      -- [團隊] 寧靜4 / Tranquility 4
    [29166] = true,     -- [輔助] 啟動 / Innervate
    [1850] = true,      -- [輔助] 突進1 / Dash 1
    [9821] = true,      -- [輔助] 突進2 / Dash 2
    [783] = true,       -- [輔助] 旅行形態 / Travel Form
    [5215] = true,      -- [輔助] 潛行1 / Prowl 1
    [6783] = true,      -- [輔助] 潛行2 / Prowl 2
    [9913] = true,      -- [輔助] 潛行3 / Prowl 3

    -- Hunter / 獵人

    [19263] = true,     -- [個人] 威懾 / Deterrence
    [5118] = true,      -- [輔助] 獵豹守護 / Aspect of the Cheetah
    [13159] = true,     -- [輔助] 豹群守護 / Aspect of the Pack
    [5384] = true,      -- [輔助] 假死 / Feign Death

    -- Mage / 法師

    [11958] = true,     -- [個人] 寒冰屏障 / Ice Block
    [11426] = true,     -- [個人] 寒冰護體1 / Ice Barrier 1
    [13031] = true,     -- [個人] 寒冰護體2 / Ice Barrier 2
    [13032] = true,     -- [個人] 寒冰護體3 / Ice Barrier 3
    [13033] = true,     -- [個人] 寒冰護體4 / Ice Barrier 4
    [1463] = true,      -- [個人] 法力護盾1 / Mana Shield 1
    [8494] = true,      -- [個人] 法力護盾2 / Mana Shield 2
    [8495] = true,      -- [個人] 法力護盾3 / Mana Shield 3
    [10191] = true,     -- [個人] 法力護盾4 / Mana Shield 4
    [10192] = true,     -- [個人] 法力護盾5 / Mana Shield 5
    [10193] = true,     -- [個人] 法力護盾6 / Mana Shield 6
    [130] = true,       -- [輔助] 緩落術 / Slow Fall
    [1008] = true,      -- [輔助] 魔法增效1 / Amplify Magic 1
    [8455] = true,      -- [輔助] 魔法增效2 / Amplify Magic 2
    [10169] = true,     -- [輔助] 魔法增效3 / Amplify Magic 3
    [10170] = true,     -- [輔助] 魔法增效4 / Amplify Magic 4
    [604] = true,       -- [輔助] 魔法抑制1 / Dampen Magic 1
    [8450] = true,      -- [輔助] 魔法抑制2 / Dampen Magic 2
    [8451] = true,      -- [輔助] 魔法抑制3 / Dampen Magic 3
    [10173] = true,     -- [輔助] 魔法抑制4 / Dampen Magic 4
    [10174] = true,     -- [輔助] 魔法抑制5 / Dampen Magic 5

    -- Paladin / 聖騎士

    [642] = true,       -- [個人] 聖盾術1 / Divine Shield 1
    [1020] = true,      -- [個人] 聖盾術2 / Divine Shield 2
    [498] = true,       -- [個人] 聖佑術1 / Divine Protection 1
    [5573] = true,      -- [個人] 聖佑術2 / Divine Protection 2
    [1022] = true,      -- [輔助] 保護祝福1 / Blessing of Protection 1
    [5599] = true,      -- [輔助] 保護祝福2 / Blessing of Protection 2
    [10278] = true,     -- [輔助] 保護祝福3 / Blessing of Protection 3
    [6940] = true,      -- [輔助] 犧牲祝福1 / Blessing of Sacrifice 1
    [20729] = true,     -- [輔助] 犧牲祝福2 / Blessing of Sacrifice 2
    [1044] = true,      -- [輔助] 自由祝福 / Blessing of Freedom

    -- Priest / 牧師

    [586] = true,       -- [個人] 漸隱術1 / Fade 1
    [9578] = true,      -- [個人] 漸隱術2 / Fade 2
    [9579] = true,      -- [個人] 漸隱術3 / Fade 3
    [9592] = true,      -- [個人] 漸隱術4 / Fade 4
    [10941] = true,     -- [個人] 漸隱術5 / Fade 5
    [10942] = true,     -- [個人] 漸隱術6 / Fade 6
    [27827] = true,     -- [個人] 救贖之靈 / Spirit of Redemption
    [10060] = true,     -- [輔助] 注入能量 / Power Infusion
    [6346] = true,      -- [輔助] 防護恐懼結界 / Fear Ward
    [1706] = true,      -- [輔助] 漂浮術 / Levitate

    -- Rogue / 盜賊

    [5277] = true,      -- [個人] 閃避 / Evasion
    [1856] = true,      -- [個人] 消失1 / Vanish 1
    [11327] = true,     -- [個人] 消失1（光環）/ Vanish 1 (aura)
    [1857] = true,      -- [個人] 消失2 / Vanish 2
    [11329] = true,     -- [個人] 消失2（光環）/ Vanish 2 (aura)
    [2983] = true,      -- [輔助] 疾跑1 / Sprint 1
    [8696] = true,      -- [輔助] 疾跑2 / Sprint 2
    [11305] = true,     -- [輔助] 疾跑3 / Sprint 3
    [1784] = true,      -- [輔助] 潛行1 / Stealth 1
    [1785] = true,      -- [輔助] 潛行2 / Stealth 2
    [1786] = true,      -- [輔助] 潛行3 / Stealth 3
    [1787] = true,      -- [輔助] 潛行4 / Stealth 4

    -- Shaman / 薩滿

    [2645] = true,      -- [輔助] 鬼魂之狼 / Ghost Wolf
    [546] = true,       -- [輔助] 水上行走 / Water Walking
    [131] = true,       -- [輔助] 水下呼吸 / Water Breathing

    -- Warlock / 術士

    [6229] = true,      -- [個人] 暗影防護結界1 / Shadow Ward 1
    [11739] = true,     -- [個人] 暗影防護結界2 / Shadow Ward 2
    [11740] = true,     -- [個人] 暗影防護結界3 / Shadow Ward 3
    [28610] = true,     -- [個人] 暗影防護結界4 / Shadow Ward 4
    [5697] = true,      -- [輔助] 無盡呼吸 / Unending Breath

    -- Warrior / 戰士

    [871] = true,       -- [個人] 盾牆 / Shield Wall
    [12975] = true,     -- [個人] 破釜沉舟 / Last Stand
    [12976] = true,     -- [個人] 破釜沉舟（相關 ID）/ Last Stand (related ID)
    [20230] = true,     -- [個人] 反擊風暴 / Retaliation
}
