local addonName, ns = ...
local C = ns.Core

local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local mediaRoot = "Interface\\AddOns\\" .. addonName .. "\\TexturesGUI\\"

ns.Media = {
    arrow = mediaRoot .. "arrow.png",
    check = mediaRoot .. "ok-iconBlack.tga",
    close = mediaRoot .. "Close.png",
    cross = mediaRoot .. "cross-small.png",
    logo = mediaRoot .. "logo_ccraidtools.png",
}

ns.Theme = {
    accent = { 0.18, 0.67, 1 },
    accentSoft = { 0.10, 0.28, 0.43 },
    background = { 0.018, 0.024, 0.034 },
    border = { 0.13, 0.18, 0.24 },
    danger = { 1, 0.32, 0.32 },
    gold = { 0.95, 0.72, 0.28 },
    muted = { 0.58, 0.63, 0.70 },
    panel = { 0.029, 0.039, 0.054 },
    panelRaised = { 0.045, 0.058, 0.078 },
    success = { 0.25, 0.88, 0.48 },
    text = { 0.92, 0.95, 1 },
    warning = { 1, 0.68, 0.25 },
}

local T = ns.Theme
local M = ns.Media
local BACKDROP = {
    bgFile = WHITE_TEXTURE,
    edgeFile = WHITE_TEXTURE,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local moduleDescriptions = {
    automation = "Promos • invitations",
    readycheck = "Buffs • conso",
    marks = "Cibles • sol",
    focus = "Focus sous souris",
}

local moduleIcons = {
    automation = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
    readycheck = "Interface\\RaidFrame\\ReadyCheck-Ready",
    marks = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    focus = "Interface\\Icons\\Ability_Hunter_FocusedAim",
}

local function SetBackdrop(frame, background, border, alpha)
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(background[1], background[2], background[3], alpha or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], 1)
end

function ns.CreateCloseButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(28, 28)
    button:SetNormalTexture(M.close)

    local normal = button:GetNormalTexture()
    normal:SetSize(16, 16)
    normal:ClearAllPoints()
    normal:SetPoint("CENTER")

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(M.close)
    highlight:SetSize(16, 16)
    highlight:SetPoint("CENTER")
    highlight:SetVertexColor(T.accent[1], T.accent[2], T.accent[3])
    highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(highlight)
    button:SetScript("OnClick", function() parent:Hide() end)
    return button
end

function ns.CreatePageHeader(parent, title, description, iconPath)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", 4, -2)
    header:SetPoint("TOPRIGHT", -4, -2)
    header:SetHeight(50)

    local iconPlate = CreateFrame("Frame", nil, header, "BackdropTemplate")
    iconPlate:SetSize(40, 40)
    iconPlate:SetPoint("LEFT", 0, 0)
    SetBackdrop(iconPlate, T.panelRaised, T.border)

    local icon = iconPlate:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 7, -7)
    icon:SetPoint("BOTTOMRIGHT", -7, 7)
    icon:SetTexture(iconPath or M.logo)

    local heading = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 12, -2)
    heading:SetText(title)
    heading:SetTextColor(unpack(T.text))

    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -4)
    subtitle:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, -27)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(description or "")
    subtitle:SetTextColor(unpack(T.muted))

    local divider = header:CreateTexture(nil, "BORDER")
    divider:SetPoint("BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(T.border[1], T.border[2], T.border[3], 0.85)
    return header
end

function ns.CreateSection(parent, title, anchor, offset)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local target = anchor or parent
    local topOffset = offset or -10
    section:SetPoint("TOPLEFT", target, anchor and "BOTTOMLEFT" or "TOPLEFT", 0, topOffset)
    section:SetPoint("TOPRIGHT", target, anchor and "BOTTOMRIGHT" or "TOPRIGHT", 0, topOffset)
    SetBackdrop(section, T.panel, T.border, 0.96)

    local headerBackground = section:CreateTexture(nil, "BACKGROUND")
    headerBackground:SetPoint("TOPLEFT", 1, -1)
    headerBackground:SetPoint("TOPRIGHT", -1, -1)
    headerBackground:SetHeight(31)
    headerBackground:SetColorTexture(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 0.92)

    local accent = section:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("BOTTOMLEFT", 1, 1)
    accent:SetWidth(3)
    accent:SetColorTexture(unpack(T.accent))

    local heading = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOPLEFT", 13, -9)
    heading:SetText(title)
    heading:SetTextColor(unpack(T.text))
    section.heading = heading
    return section
end

local function UpdateCheckVisual(check)
    local checked = check:GetChecked()
    check.checkmark:SetShown(checked)
    if checked then
        check.box:SetBackdropColor(T.accent[1], T.accent[2], T.accent[3], 1)
        check.box:SetBackdropBorderColor(0.36, 0.78, 1, 1)
        check.Text:SetTextColor(unpack(T.text))
    else
        check.box:SetBackdropColor(T.background[1], T.background[2], T.background[3], 1)
        check.box:SetBackdropBorderColor(unpack(T.border))
        check.Text:SetTextColor(0.78, 0.82, 0.88)
    end
end

function ns.SetCheck(check, checked)
    check:SetChecked(checked and true or false)
    UpdateCheckVisual(check)
end

function ns.CreateCheck(parent, label, anchor, checked, callback)
    local check = CreateFrame("CheckButton", nil, parent)
    check:SetSize(520, 24)
    check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -7)

    local box = CreateFrame("Frame", nil, check, "BackdropTemplate")
    box:SetSize(18, 18)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop(BACKDROP)
    check.box = box

    local checkmark = box:CreateTexture(nil, "ARTWORK")
    checkmark:SetTexture(M.check)
    checkmark:SetPoint("TOPLEFT", 2, -2)
    checkmark:SetPoint("BOTTOMRIGHT", -2, 2)
    check.checkmark = checkmark

    local labelText = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    labelText:SetPoint("LEFT", box, "RIGHT", 9, 0)
    labelText:SetPoint("RIGHT", check, "RIGHT", 0, 0)
    labelText:SetJustifyH("LEFT")
    labelText:SetText(label)
    check.Text = labelText

    check:SetScript("OnEnter", function(self)
        if not self:GetChecked() then
            self.box:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.9)
        end
        self.Text:SetTextColor(unpack(T.text))
    end)
    check:SetScript("OnLeave", UpdateCheckVisual)
    check:SetScript("OnClick", function(self)
        UpdateCheckVisual(self)
        callback(self:GetChecked() and true or false)
    end)
    ns.SetCheck(check, checked)
    return check
end

function ns.SetButtonActive(button, active)
    button.active = active and true or false
    if button.active then
        button:SetBackdropColor(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3], 1)
        button:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.9)
        button.label:SetTextColor(unpack(T.text))
    else
        button:SetBackdropColor(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 1)
        button:SetBackdropBorderColor(unpack(T.border))
        button.label:SetTextColor(0.84, 0.88, 0.94)
    end
end

function ns.CreateButton(parent, label, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 110, 28)
    button:SetBackdrop(BACKDROP)

    local labelText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelText:SetPoint("CENTER", 0, 0)
    labelText:SetText(label)
    button.label = labelText

    local topLine = button:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", 1, -1)
    topLine:SetPoint("TOPRIGHT", -1, -1)
    topLine:SetHeight(1)
    topLine:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.7)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.07, 0.11, 0.15, 1)
        self:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
        self.label:SetTextColor(1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self) ns.SetButtonActive(self, self.active) end)
    button:SetScript("OnMouseDown", function(self) self.label:SetPoint("CENTER", 1, -1) end)
    button:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER", 0, 0) end)
    button:SetScript("OnClick", callback)
    ns.SetButtonActive(button, false)
    return button
end

function ns.CreateEditBox(parent, width)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width or 220, 28)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(500)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetTextInsets(9, 9, 0, 0)
    edit:SetBackdrop(BACKDROP)
    edit:SetBackdropColor(T.background[1], T.background[2], T.background[3], 1)
    edit:SetBackdropBorderColor(unpack(T.border))
    edit:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(T.accent[1], T.accent[2], T.accent[3], 1)
    end)
    edit:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(unpack(T.border))
    end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return edit
end

local function ApplyNavState(button, selected)
    button.selected = selected
    button.selection:SetShown(selected)
    button.arrow:SetShown(selected)
    if selected then
        button.background:SetColorTexture(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3], 0.95)
        button.title:SetTextColor(unpack(T.text))
        button.description:SetTextColor(0.67, 0.82, 0.94)
    else
        button.background:SetColorTexture(T.panel[1], T.panel[2], T.panel[3], 0)
        button.title:SetTextColor(0.76, 0.80, 0.87)
        button.description:SetTextColor(unpack(T.muted))
    end
end

local mainFrame
local function BuildWindow()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "CCRaidToolsMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(840, 660)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetToplevel(true)
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    SetBackdrop(mainFrame, T.background, T.border, 0.985)
    C.RestorePosition(mainFrame, ns.db.window)
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        C.SavePosition(self, ns.db.window)
    end)
    mainFrame:SetScript("OnHide", function() CloseDropDownMenus() end)

    local shadow = mainFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetPoint("TOPLEFT", -5, 5)
    shadow:SetPoint("BOTTOMRIGHT", 5, -5)
    shadow:SetColorTexture(0, 0, 0, 0.55)

    local header = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(72)
    header:SetBackdrop({ bgFile = WHITE_TEXTURE })
    header:SetBackdropColor(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 0.98)

    local logoGlow = header:CreateTexture(nil, "BACKGROUND")
    logoGlow:SetSize(66, 66)
    logoGlow:SetPoint("LEFT", 10, 0)
    logoGlow:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.08)

    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(58, 58)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture(M.logo)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 13, -8)
    title:SetText("CC RAIDTOOLS")
    title:SetTextColor(unpack(T.text))

    local brandAccent = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    brandAccent:SetPoint("LEFT", title, "RIGHT", 5, 0)
    brandAccent:SetText("REFORGED")
    brandAccent:SetTextColor(unpack(T.accent))

    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)
    subtitle:SetText("CENTRE DE COMMANDEMENT DE RAID  •  RETAIL 12.1")
    subtitle:SetTextColor(unpack(T.muted))

    local version = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("RIGHT", header, "RIGHT", -50, 0)
    version:SetText("v2.0.0")
    version:SetTextColor(0.46, 0.53, 0.62)

    local headerLine = header:CreateTexture(nil, "ARTWORK")
    headerLine:SetPoint("BOTTOMLEFT", 0, 0)
    headerLine:SetPoint("BOTTOMRIGHT", 0, 0)
    headerLine:SetHeight(2)
    headerLine:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.72)

    local close = ns.CreateCloseButton(mainFrame)
    close:SetPoint("TOPRIGHT", -9, -9)

    local nav = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    nav:SetPoint("TOPLEFT", 12, -84)
    nav:SetPoint("BOTTOMLEFT", 12, 12)
    nav:SetWidth(190)
    SetBackdrop(nav, T.panel, T.border, 0.96)

    local navTitle = nav:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    navTitle:SetPoint("TOPLEFT", 14, -13)
    navTitle:SetText("OUTILS DE RAID")
    navTitle:SetTextColor(unpack(T.accent))

    local navHint = nav:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    navHint:SetPoint("BOTTOMLEFT", 14, 13)
    navHint:SetText("/ccrt  •  glisser pour déplacer")
    navHint:SetTextColor(0.42, 0.48, 0.56)

    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 14, -2)
    content:SetPoint("BOTTOMRIGHT", -14, 14)

    local panels, buttons = {}, {}
    local function Select(moduleID)
        for id, panel in pairs(panels) do
            panel:SetShown(id == moduleID)
        end
        for id, button in pairs(buttons) do
            ApplyNavState(button, id == moduleID)
        end
        local module = ns.modules[moduleID]
        if module and module.Refresh then module:Refresh() end
        mainFrame.selectedModule = moduleID
    end

    for index, id in ipairs(ns.moduleOrder) do
        local moduleID = id
        local module = ns.modules[moduleID]
        local button = CreateFrame("Button", nil, nav)
        button:SetSize(174, 54)
        button:SetPoint("TOPLEFT", 8, -35 - (index - 1) * 58)

        local background = button:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        button.background = background

        local selection = button:CreateTexture(nil, "ARTWORK")
        selection:SetPoint("TOPLEFT", 0, 0)
        selection:SetPoint("BOTTOMLEFT", 0, 0)
        selection:SetWidth(3)
        selection:SetColorTexture(unpack(T.accent))
        button.selection = selection

        local iconPlate = button:CreateTexture(nil, "BORDER")
        iconPlate:SetSize(34, 34)
        iconPlate:SetPoint("LEFT", 10, 0)
        iconPlate:SetColorTexture(0.015, 0.022, 0.032, 0.75)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24)
        icon:SetPoint("CENTER", iconPlate, "CENTER", 0, 0)
        icon:SetTexture(module.icon or moduleIcons[moduleID] or "Interface\\Icons\\INV_Misc_Gear_01")

        local buttonTitle = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        buttonTitle:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 10, -2)
        buttonTitle:SetSize(103, 14)
        buttonTitle:SetJustifyH("LEFT")
        buttonTitle:SetText(module.title or moduleID)
        button.title = buttonTitle

        local description = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        description:SetPoint("TOPLEFT", buttonTitle, "BOTTOMLEFT", 0, -4)
        description:SetSize(103, 12)
        description:SetJustifyH("LEFT")
        description:SetText(moduleDescriptions[moduleID] or "Configuration du module")
        button.description = description

        local arrow = button:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(12, 12)
        arrow:SetPoint("RIGHT", -7, 0)
        arrow:SetTexture(M.arrow)
        arrow:SetRotation(-math.pi / 2)
        button.arrow = arrow

        button:SetScript("OnEnter", function(self)
            if not self.selected then
                self.background:SetColorTexture(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 0.8)
                self.title:SetTextColor(unpack(T.text))
            end
        end)
        button:SetScript("OnLeave", function(self) ApplyNavState(self, self.selected) end)
        button:SetScript("OnClick", function() Select(moduleID) end)
        buttons[moduleID] = button

        local panel = CreateFrame("Frame", nil, content)
        panel:SetAllPoints()
        panel:Hide()
        panels[moduleID] = panel
        if module.BuildPanel then module:BuildPanel(panel) end
    end

    mainFrame.panels = panels
    Select(ns.moduleOrder[1])
    mainFrame:Hide()
    return mainFrame
end

function ns.ToggleWindow()
    if not ns.db then C.InitializeDatabase() end
    local window = BuildWindow()
    window:SetShown(not window:IsShown())
end
