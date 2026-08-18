local _, ns = ...
local C = ns.Core
local module = { title = "Marqueurs", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" }
local T = ns.Theme
local TARGET_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local WORLD_MARKER_FOR_ICON = { 5, 6, 3, 2, 7, 1, 4, 8 }
local bar, pendingLayout, refreshPanel
local targetButtons, worldButtons = {}, {}

local function SetIcon(texture, index)
    texture:SetTexture(TARGET_TEXTURE .. index)
    texture:SetTexCoord(0, 1, 0, 1)
end

local function CreateSecureButton(size)
    local button = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate")
    button:SetSize(size, size)
    button:RegisterForClicks("AnyUp")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 0.98)
    button.background = background

    local borders = {}
    for index = 1, 4 do
        local border = button:CreateTexture(nil, "BORDER")
        border:SetColorTexture(unpack(T.border))
        borders[index] = border
    end
    borders[1]:SetPoint("TOPLEFT"); borders[1]:SetPoint("TOPRIGHT"); borders[1]:SetHeight(1)
    borders[2]:SetPoint("BOTTOMLEFT"); borders[2]:SetPoint("BOTTOMRIGHT"); borders[2]:SetHeight(1)
    borders[3]:SetPoint("TOPLEFT"); borders[3]:SetPoint("BOTTOMLEFT"); borders[3]:SetWidth(1)
    borders[4]:SetPoint("TOPRIGHT"); borders[4]:SetPoint("BOTTOMRIGHT"); borders[4]:SetWidth(1)
    button.borders = borders

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", -4, 4)
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetPoint("TOPLEFT", 1, -1)
    highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    highlight:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.20)
    button:SetHighlightTexture(highlight)
    button:SetScript("OnEnter", function(self)
        for _, border in ipairs(self.borders) do border:SetColorTexture(unpack(T.accent)) end
    end)
    button:SetScript("OnLeave", function(self)
        for _, border in ipairs(self.borders) do border:SetColorTexture(unpack(T.border)) end
    end)
    return button
end

local function ApplyVisibility()
    if not bar or InCombatLockdown() then return end
    bar:SetShown(ns.db.marksBar.enabled)
    bar:SetAlpha(ns.db.marksBar.mouseover and 0.12 or ns.db.marksBar.alpha)
end

local function ApplyLayout()
    if not bar then return end
    if InCombatLockdown() then pendingLayout = true; return end
    pendingLayout = false
    local horizontal = ns.db.marksBar.orientation == "HORIZONTAL"
    local targetSize, worldSize, gap = 30, 23, 3
    if horizontal then
        bar:SetSize(8 * targetSize + 7 * gap + 8, targetSize + worldSize + gap + 8)
        for index, button in ipairs(targetButtons) do
            button:ClearAllPoints(); button:SetSize(targetSize, targetSize)
            button:SetPoint("TOPLEFT", 4 + (index - 1) * (targetSize + gap), -4)
        end
        for index, button in ipairs(worldButtons) do
            button:ClearAllPoints(); button:SetSize(worldSize, worldSize)
            button:SetPoint("TOPLEFT", 31 + (index - 1) * (worldSize + gap), -targetSize - gap - 4)
        end
    else
        bar:SetSize(targetSize + worldSize + gap + 8, 8 * targetSize + 7 * gap + 8)
        for index, button in ipairs(targetButtons) do
            button:ClearAllPoints(); button:SetSize(targetSize, targetSize)
            button:SetPoint("TOPLEFT", 4, -4 - (index - 1) * (targetSize + gap))
        end
        for index, button in ipairs(worldButtons) do
            button:ClearAllPoints(); button:SetSize(worldSize, worldSize)
            button:SetPoint("TOPLEFT", targetSize + gap + 4, -31 - (index - 1) * (worldSize + gap))
        end
    end
    bar:SetScale(ns.db.marksBar.scale)
    ApplyVisibility()
end

local function CreateBar()
    if bar then return end
    bar = CreateFrame("Frame", "CCRaidToolsMarksBar", UIParent, "BackdropTemplate")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
    bar:SetBackdropColor(T.background[1], T.background[2], T.background[3], 0.94)
    bar:SetBackdropBorderColor(unpack(T.border))
    local accent = bar:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetHeight(2)
    accent:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.8)
    C.RestorePosition(bar, ns.db.marksBar)
    bar:SetScript("OnDragStart", function(self) if not ns.db.marksBar.locked and not InCombatLockdown() then self:StartMoving() end end)
    bar:SetScript("OnDragStop", function(self) if not InCombatLockdown() then self:StopMovingOrSizing(); C.SavePosition(self, ns.db.marksBar) end end)
    bar:SetScript("OnEnter", function(self) if ns.db.marksBar.mouseover then self:SetAlpha(ns.db.marksBar.alpha) end end)
    bar:SetScript("OnLeave", function(self) if ns.db.marksBar.mouseover then self:SetAlpha(0.12) end end)
    for index = 1, 8 do
        local button = CreateSecureButton(30)
        SetIcon(button.icon, index)
        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext1", "/tm [@target,exists] " .. index)
        button:SetAttribute("type2", "macro")
        button:SetAttribute("macrotext2", "/tm [@target,exists] 0")
        targetButtons[index] = button
    end
    for index = 1, 8 do
        local button = CreateSecureButton(23)
        SetIcon(button.icon, index)
        button.icon:SetVertexColor(1, 0.82, 0.35)
        local marker = WORLD_MARKER_FOR_ICON[index]
        button:SetAttribute("type1", "worldmarker")
        button:SetAttribute("marker1", marker)
        button:SetAttribute("action1", "set")
        button:SetAttribute("type2", "worldmarker")
        button:SetAttribute("marker2", marker)
        button:SetAttribute("action2", "clear")
        worldButtons[index] = button
    end
    ApplyLayout()
end

function module:BuildPanel(parent)
    local heading = ns.CreatePageHeader(
        parent,
        "Barre de marqueurs",
        "Pose les marques de cible et les marqueurs au sol depuis une barre sécurisée.",
        module.icon
    )
    local section = ns.CreateSection(parent, "Affichage et position", heading, -10)
    section:SetHeight(290)
    local enabled = ns.CreateCheck(section, "Afficher la barre", section.heading, ns.db.marksBar.enabled, function(value) ns.db.marksBar.enabled = value; ApplyVisibility() end)
    local locked = ns.CreateCheck(section, "Verrouiller la position", enabled, ns.db.marksBar.locked, function(value) ns.db.marksBar.locked = value end)
    local mouseover = ns.CreateCheck(section, "Atténuer hors survol", locked, ns.db.marksBar.mouseover, function(value) ns.db.marksBar.mouseover = value; ApplyVisibility() end)
    local horizontal, vertical
    horizontal = ns.CreateButton(section, "Horizontal", 115, function()
        ns.db.marksBar.orientation = "HORIZONTAL"
        ApplyLayout()
        ns.SetButtonActive(horizontal, true)
        ns.SetButtonActive(vertical, false)
    end)
    horizontal:SetPoint("TOPLEFT", mouseover, "BOTTOMLEFT", 4, -18)
    vertical = ns.CreateButton(section, "Vertical", 115, function()
        ns.db.marksBar.orientation = "VERTICAL"
        ApplyLayout()
        ns.SetButtonActive(horizontal, false)
        ns.SetButtonActive(vertical, true)
    end)
    vertical:SetPoint("LEFT", horizontal, "RIGHT", 8, 0)
    local reset = ns.CreateButton(section, "Recentrer", 115, function()
        if InCombatLockdown() then C.Print("Position modifiable après le combat."); return end
        ns.db.marksBar.point, ns.db.marksBar.relativePoint, ns.db.marksBar.x, ns.db.marksBar.y = "CENTER", "CENTER", 0, -180
        C.RestorePosition(bar, ns.db.marksBar)
    end)
    reset:SetPoint("LEFT", vertical, "RIGHT", 8, 0)
    local note = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", horizontal, "BOTTOMLEFT", 0, -18)
    note:SetWidth(490)
    note:SetJustifyH("LEFT")
    note:SetText("Rangée principale : marques de cible. Rangée dorée : marqueurs au sol. Clic gauche pour poser, clic droit pour retirer. Toutes les actions utilisent des boutons sécurisés utilisables en combat.")
    note:SetTextColor(unpack(T.muted))
    refreshPanel = function()
        ns.SetCheck(enabled, ns.db.marksBar.enabled)
        ns.SetCheck(locked, ns.db.marksBar.locked)
        ns.SetCheck(mouseover, ns.db.marksBar.mouseover)
        ns.SetButtonActive(horizontal, ns.db.marksBar.orientation == "HORIZONTAL")
        ns.SetButtonActive(vertical, ns.db.marksBar.orientation == "VERTICAL")
    end
    refreshPanel()
end

function module:Refresh() if refreshPanel then refreshPanel() end end
function module:Initialize() CreateBar() end
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function() if pendingLayout then ApplyLayout() else ApplyVisibility() end end)
C.RegisterModule("marks", module)
