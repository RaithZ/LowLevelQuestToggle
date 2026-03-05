-- LowLevelQuestToggle
-- Adds a button anchored to the Quest Tracker to toggle low-level quest tracking

local addonName, addon = ...

LowLevelQuestToggle_ShowLowLevel = LowLevelQuestToggle_ShowLowLevel or false
LowLevelQuestToggle_Visible = LowLevelQuestToggle_Visible ~= false
LowLevelQuestToggle_Position = LowLevelQuestToggle_Position or nil

local button

-- ── helpers ──────────────────────────────────────────────────────────────────

local function FindLowLevelQuestTrackingIndex()
    local count = C_Minimap.GetNumTrackingTypes()
    for i = 1, count do
        local info = C_Minimap.GetTrackingInfo(i)
        if info and info.name then
            local lower = info.name:lower()
            if lower:find("trivial") or lower:find("low.level") or lower:find("hidden quest") then
                return i
            end
        end
    end
    return nil
end

local function GetLiveState()
    local idx = FindLowLevelQuestTrackingIndex()
    if idx then
        local info = C_Minimap.GetTrackingInfo(idx)
        return info and info.active == true
    end
    return false
end

local function UpdateButtonAppearance()
    if not button then return end
    local label = button.Text or _G[button:GetName() .. "Text"]
    if not label then return end
    if LowLevelQuestToggle_ShowLowLevel then
        label:SetText("Low Lvl: ON")
        label:SetTextColor(0, 1, 0, 1)
    else
        label:SetText("Low Lvl: OFF")
        label:SetTextColor(1, 1, 1, 1)
    end
end

-- ── tracking frame refresh ────────────────────────────────────────────────────

local function GetTrackingFrame()
    if MinimapCluster then
        return MinimapCluster.Tracking or MinimapCluster.TrackingFrame
    end
    return _G["MiniMapTrackingFrame"] or _G["MiniMapTracking"]
end

local function RefreshTrackingFrame()
    local tf = GetTrackingFrame()
    if not tf then return end

    -- Fire OnEvent on the frame and its Button child
    local fn = tf:GetScript("OnEvent")
    if fn then pcall(fn, tf, "MINIMAP_UPDATE_TRACKING") end

    if tf.Button and tf.Button.GetScript then
        local fn2 = tf.Button:GetScript("OnEvent")
        if fn2 then pcall(fn2, tf.Button, "MINIMAP_UPDATE_TRACKING") end
    end

    -- Hide/show the tracking frame to force the Button to rebuild its menu on next click
    tf:Hide()
    tf:Show()
end

-- ── apply tracking ────────────────────────────────────────────────────────────

local function ApplyQuestTracking()
    local idx = FindLowLevelQuestTrackingIndex()
    if not idx then return end

    if C_Minimap.SetTrackingFilter then
        C_Minimap.SetTrackingFilter(idx, LowLevelQuestToggle_ShowLowLevel)
    else
        C_Minimap.SetTracking(idx, LowLevelQuestToggle_ShowLowLevel)
    end

    local info = C_Minimap.GetTrackingInfo(idx)
    if info then
        LowLevelQuestToggle_ShowLowLevel = info.active == true
    end

    RefreshTrackingFrame()
end

-- Hook the minimap tracking menu to always reflect live state
local function HookMinimapTrackingMenu()
    local tf = GetTrackingFrame()
    if not tf or not tf.Button then
        C_Timer.After(2, HookMinimapTrackingMenu)
        return
    end

    local btn = tf.Button
    if not btn.menuGenerator then return end

    local origGenerator = btn.menuGenerator
    btn.menuGenerator = function(self, rootDescription, contextData)
        local origCreateCheckbox = rawget(rootDescription, "CreateCheckbox")
        if not origCreateCheckbox then
            return origGenerator(self, rootDescription, contextData)
        end

        rootDescription.CreateCheckbox = function(rdSelf, label, isSelectedFn, setSelectedFn, ...)
            local count = C_Minimap.GetNumTrackingTypes()
            for i = 1, count do
                local info = C_Minimap.GetTrackingInfo(i)
                if info and info.name == label then
                    local idx = i
                    isSelectedFn = function()
                        local liveInfo = C_Minimap.GetTrackingInfo(idx)
                        return liveInfo and liveInfo.active == true
                    end
                    break
                end
            end
            return origCreateCheckbox(rdSelf, label, isSelectedFn, setSelectedFn, ...)
        end

        local result = origGenerator(self, rootDescription, contextData)
        rootDescription.CreateCheckbox = origCreateCheckbox
        return result
    end
end

local function ToggleLowLevelQuests()
    LowLevelQuestToggle_ShowLowLevel = not LowLevelQuestToggle_ShowLowLevel
    ApplyQuestTracking()
    UpdateButtonAppearance()
    if LowLevelQuestToggle_ShowLowLevel then
        print("|cFFFFD700[LowLevelQuestToggle]|r Low-level quests are now |cFF00FF00shown|r.")
    else
        print("|cFFFFD700[LowLevelQuestToggle]|r Low-level quests are now |cFFFF4444hidden|r.")
    end
end

-- ── button ────────────────────────────────────────────────────────────────────

local function CreateToggleButton()
    button = CreateFrame("Button", "LowLevelQuestToggleButton", UIParent, "UIPanelButtonTemplate")
    button:SetSize(100, 18)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(10)
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")

    button:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then self:StartMoving() end
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        LowLevelQuestToggle_Position = { point=point, relPoint=relPoint, x=x, y=y }
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Low-Level Quest Toggle", 1, 0.82, 0, 1)
        GameTooltip:AddLine("Click to toggle low-level quests.", 1, 1, 1, 1)
        GameTooltip:AddLine("Shift+Drag to move.", 0.7, 0.7, 0.7, 1)
        GameTooltip:AddLine(" ")
        if LowLevelQuestToggle_ShowLowLevel then
            GameTooltip:AddLine("Status: Showing low-level quests", 0, 1, 0, 1)
        else
            GameTooltip:AddLine("Status: Hiding low-level quests", 1, 0.27, 0.27, 1)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" and not IsShiftKeyDown() then
            ToggleLowLevelQuests()
        end
    end)

    if LowLevelQuestToggle_Position then
        local p = LowLevelQuestToggle_Position
        button:ClearAllPoints()
        button:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
        button:Show()
    else
        local function AnchorButton()
            local tracker = QuestTrackerFrame or ObjectiveTrackerFrame
            if tracker then
                button:ClearAllPoints()
                button:SetPoint("TOPRIGHT", tracker, "BOTTOMRIGHT", 0, -4)
                button:Show()
            else
                C_Timer.After(1, AnchorButton)
            end
        end
        AnchorButton()
    end

    UpdateButtonAppearance()
    if LowLevelQuestToggle_Visible == false then button:Hide() end
end

-- ── event handling ────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- Sync our button when the user changes tracking via the minimap menu
eventFrame:RegisterEvent("MINIMAP_UPDATE_TRACKING")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if LowLevelQuestToggle_ShowLowLevel == nil then
            LowLevelQuestToggle_ShowLowLevel = false
        end

    elseif event == "PLAYER_LOGIN" then
        CreateToggleButton()
        HookMinimapTrackingMenu()
        print("|cFFFFD700[LowLevelQuestToggle]|r Loaded. Low-level quests: " ..
            (LowLevelQuestToggle_ShowLowLevel and "|cFF00FF00ON|r" or "|cFFFF4444OFF|r"))

    elseif event == "PLAYER_ENTERING_WORLD" then
        LowLevelQuestToggle_ShowLowLevel = GetLiveState()
        UpdateButtonAppearance()
        ApplyQuestTracking()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    elseif event == "MINIMAP_UPDATE_TRACKING" then
        -- Tracking changed (via minimap menu or any other source) — sync our button
        LowLevelQuestToggle_ShowLowLevel = GetLiveState()
        UpdateButtonAppearance()
    end
end)

-- ── slash commands ────────────────────────────────────────────────────────────

SLASH_LOWLEVELQUESTTOGGLE1 = "/llqt"
SLASH_LOWLEVELQUESTTOGGLE2 = "/lowlevelquests"
SlashCmdList["LOWLEVELQUESTTOGGLE"] = function(msg)
    local cmd = msg:lower():match("^%s*(.-)%s*$")
    if cmd == "help" or cmd == "?" then
        print("|cFFFFD700[LowLevelQuestToggle]|r Commands:")
        print("  |cFFFFD700/llqt|r — Toggle low-level quest tracking on/off")
        print("  |cFFFFD700/llqt on|r — Enable low-level quest tracking")
        print("  |cFFFFD700/llqt off|r — Disable low-level quest tracking")
        print("  |cFFFFD700/llqt show|r — Show the toggle button")
        print("  |cFFFFD700/llqt hide|r — Hide the toggle button")
        print("  |cFFFFD700/llqt reset|r — Reset button to default position")
        print("  |cFFFFD700/llqt debug|r — Print tracking type info")
        print("  |cFFFFD700/llqt help|r — Show this help")
        print("  |cFFCCCCCC(Shift+Drag the button to reposition it)|r")
    elseif cmd == "on" then
        LowLevelQuestToggle_ShowLowLevel = true
        ApplyQuestTracking()
        UpdateButtonAppearance()
        print("|cFFFFD700[LowLevelQuestToggle]|r Low-level quests: |cFF00FF00ON|r")
    elseif cmd == "off" then
        LowLevelQuestToggle_ShowLowLevel = false
        ApplyQuestTracking()
        UpdateButtonAppearance()
        print("|cFFFFD700[LowLevelQuestToggle]|r Low-level quests: |cFFFF4444OFF|r")
    elseif cmd == "show" then
        LowLevelQuestToggle_Visible = true
        button:Show()
        print("|cFFFFD700[LowLevelQuestToggle]|r Button shown.")
    elseif cmd == "hide" then
        LowLevelQuestToggle_Visible = false
        button:Hide()
        print("|cFFFFD700[LowLevelQuestToggle]|r Button hidden. Use /llqt show to bring it back.")
    elseif cmd == "reset" then
        LowLevelQuestToggle_Position = nil
        local tracker = QuestTrackerFrame or ObjectiveTrackerFrame
        if tracker then
            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", tracker, "BOTTOMRIGHT", 0, -4)
        end
        print("|cFFFFD700[LowLevelQuestToggle]|r Button position reset.")
    elseif cmd == "debug" then
        local count = C_Minimap.GetNumTrackingTypes()
        print("|cFFFFD700[LowLevelQuestToggle]|r Tracking types (" .. count .. " total):")
        for i = 1, count do
            local info = C_Minimap.GetTrackingInfo(i)
            if info then
                print(string.format("  [%d] name=%s active=%s type=%s subType=%s",
                    i, tostring(info.name), tostring(info.active),
                    tostring(info.type), tostring(info.subType)))
            end
        end
        local tf = GetTrackingFrame()
        print("TrackingFrame: " .. (tf and tostring(tf:GetObjectType()) or "nil"))
    elseif cmd == "" then
        ToggleLowLevelQuests()
    else
        print("|cFFFFD700[LowLevelQuestToggle]|r Unknown command. Commands:")
        print("  |cFFFFD700/llqt|r — Toggle low-level quest tracking on/off")
        print("  |cFFFFD700/llqt on|r — Enable low-level quest tracking")
        print("  |cFFFFD700/llqt off|r — Disable low-level quest tracking")
        print("  |cFFFFD700/llqt show|r — Show the toggle button")
        print("  |cFFFFD700/llqt hide|r — Hide the toggle button")
        print("  |cFFFFD700/llqt reset|r — Reset button to default position")
        print("  |cFFFFD700/llqt debug|r — Print tracking type info")
        print("  |cFFFFD700/llqt help|r — Show this help")
        print("  |cFFCCCCCC(Shift+Drag the button to reposition it)|r")
    end
end
