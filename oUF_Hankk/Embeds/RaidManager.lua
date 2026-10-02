local _, ns = ...
local F = ns[2]

local fadeOutDelay = 1
local fadeOutToken = 0
local fadeOutAnimation

local function CancelFadeOut()
	fadeOutToken = fadeOutToken + 1

	if fadeOutAnimation and fadeOutAnimation:IsPlaying() then
		fadeOutAnimation:Stop()
	end
end

local function GetFadeOutAnimation(manager)
	if fadeOutAnimation then return fadeOutAnimation end

	fadeOutAnimation = manager:CreateAnimationGroup()
	fadeOutAnimation:SetToFinalAlpha(true)
	fadeOutAnimation:SetScript("OnFinished", function()
		if manager.collapsed and not manager:IsMouseOver() then
			manager:SetAlpha(0)
		end
	end)

	local alpha = fadeOutAnimation:CreateAnimation("Alpha")
	alpha:SetFromAlpha(1)
	alpha:SetToAlpha(0)
	alpha:SetDuration(0.5)
	alpha:SetSmoothing("IN_OUT")

	return fadeOutAnimation
end

local function HideManager(manager)
	if not manager.collapsed then return end
	CancelFadeOut()
	local token = fadeOutToken

	-- 每次移出取代上次的等待；移回時讓舊回呼失效，不需持續輪詢。
	C_Timer.After(fadeOutDelay, function()
		if token ~= fadeOutToken then return end
		if not manager.collapsed or manager:IsMouseOver() then return end
		manager:SetAlpha(1)
		GetFadeOutAnimation(manager):Play()
	end)
end

local function ShowManager(manager)
	CancelFadeOut()
	manager:SetAlpha(1)
end

local function RefreshManagerAlpha(manager)
	if manager.collapsed and not manager:IsMouseOver() then
		CancelFadeOut()
		manager:SetAlpha(0)
	else
		ShowManager(manager)
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)

	if not F.GetHankkOption("HideCompactRaidManager") then return end

	local manager = CompactRaidFrameManager
	if not manager then return end

	manager:HookScript("OnEnter", ShowManager)
	manager:HookScript("OnLeave", HideManager)
	manager:HookScript("OnShow", RefreshManagerAlpha)
	RefreshManagerAlpha(manager)
end)
