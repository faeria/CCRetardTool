local _, ns = ...
local C = ns.Core

local ACCENT = { 0.451, 0.506, 1 }
local moduleIcons = {
    automation = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
    readycheck = "Interface\\RaidFrame\\ReadyCheck-Ready",
    marks = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    focus = "Interface\\Icons\\Ability_Hunter_FocusedAim",
}

function ns.CreateSection(parent, title, anchor, offset)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetPoint("TOPLEFT", anchor or parent, anchor and "BOTTOMLEFT" or "TOPLEFT", 0, offset or -8)
    section:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    section:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    section:SetBackdropColor(0.025, 0.027, 0.04, 0.9)
    section:SetBackdropBorderColor(0.12, 0.13, 0.2, 1)
    local heading = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOPLEFT", 12, -10)
    heading:SetText(title)
    heading:SetTextColor(unpack(ACCENT))
    section.heading = heading
    return section
end

function ns.CreateCheck(parent, label, anchor, checked, callback)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -6)
    check:SetChecked(checked and true or false)
    check.Text:SetText(label)
    check:SetScript("OnClick", function(self) callback(self:GetChecked() and true or false) end)
    return check
end

function ns.CreateButton(parent, label, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 110, 24)
    button:SetText(label)
    button:SetScript("OnClick", callback)
    return button
end

function ns.CreateEditBox(parent, width)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width or 220, 24)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(500)
    return edit
end

local frame
local function BuildWindow()
    if frame then return frame end
    frame = CreateFrame("Frame", "CCRaidToolsMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(760, 570)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.012, 0.014, 0.022, 0.96)
    frame:SetBackdropBorderColor(0.12, 0.13, 0.2, 1)
    C.RestorePosition(frame, ns.db.window)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); C.SavePosition(self, ns.db.window) end)
    frame:SetScript("OnHide", function() CloseDropDownMenus() end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("CC RAIDTOOLS")
    title:SetTextColor(unpack(ACCENT))
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("LEFT", title, "RIGHT", 10, -1)
    subtitle:SetText("REFORGED  •  v2.0.0")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local nav = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    nav:SetPoint("TOPLEFT", 10, -48)
    nav:SetPoint("BOTTOMLEFT", 10, 10)
    nav:SetWidth(170)
    nav:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    nav:SetBackdropColor(0.02, 0.022, 0.034, 1)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 12, 0)
    content:SetPoint("BOTTOMRIGHT", -10, 10)

    local panels, buttons = {}, {}
    local function Select(id)
        for moduleID, panel in pairs(panels) do panel:SetShown(moduleID == id) end
        for moduleID, button in pairs(buttons) do
            button.bg:SetColorTexture(moduleID == id and ACCENT[1] * 0.28 or 0.03, moduleID == id and ACCENT[2] * 0.28 or 0.032, moduleID == id and ACCENT[3] * 0.28 or 0.045, 1)
        end
        local module = ns.modules[id]
        if module and module.Refresh then module:Refresh() end
    end

    for index, id in ipairs(ns.moduleOrder) do
        local module = ns.modules[id]
        local button = CreateFrame("Button", nil, nav)
        button:SetSize(154, 42)
        button:SetPoint("TOPLEFT", 8, -8 - (index - 1) * 46)
        button.bg = button:CreateTexture(nil, "BACKGROUND")
        button.bg:SetAllPoints()
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", 9, 0)
        icon:SetTexture(module.icon or moduleIcons[id] or "Interface\\Icons\\INV_Misc_Gear_01")
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", icon, "RIGHT", 9, 0)
        text:SetText(module.title or id)
        button:SetScript("OnClick", function() Select(id) end)
        buttons[id] = button

        local panel = CreateFrame("Frame", nil, content)
        panel:SetAllPoints()
        panel:Hide()
        panels[id] = panel
        if module.BuildPanel then module:BuildPanel(panel) end
    end
    frame.panels = panels
    Select(ns.moduleOrder[1])
    frame:Hide()
    return frame
end

function ns.ToggleWindow()
    if not ns.db then C.InitializeDatabase() end
    local window = BuildWindow()
    window:SetShown(not window:IsShown())
end
