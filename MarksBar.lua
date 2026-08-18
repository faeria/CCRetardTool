local _, ns = ...
local C = ns.Core
local module = { title = "Marqueurs", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" }
local TARGET_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
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
    background:SetColorTexture(0.02, 0.022, 0.034, 0.96)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.icon = icon
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
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    bar:SetBackdropColor(0.01, 0.012, 0.02, 0.9)
    bar:SetBackdropBorderColor(0.12, 0.13, 0.2, 1)
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
    local heading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 8, -8)
    heading:SetText("Barre de marqueurs")
    local section = ns.CreateSection(parent, "Affichage et position", heading, -14)
    section:SetHeight(290)
    local enabled = ns.CreateCheck(section, "Afficher la barre", section.heading, ns.db.marksBar.enabled, function(value) ns.db.marksBar.enabled = value; ApplyVisibility() end)
    local locked = ns.CreateCheck(section, "Verrouiller la position", enabled, ns.db.marksBar.locked, function(value) ns.db.marksBar.locked = value end)
    local mouseover = ns.CreateCheck(section, "Atténuer hors survol", locked, ns.db.marksBar.mouseover, function(value) ns.db.marksBar.mouseover = value; ApplyVisibility() end)
    local horizontal = ns.CreateButton(section, "Horizontal", 115, function() ns.db.marksBar.orientation = "HORIZONTAL"; ApplyLayout() end)
    horizontal:SetPoint("TOPLEFT", mouseover, "BOTTOMLEFT", 4, -18)
    local vertical = ns.CreateButton(section, "Vertical", 115, function() ns.db.marksBar.orientation = "VERTICAL"; ApplyLayout() end)
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
    note:SetTextColor(0.72, 0.74, 0.8)
    refreshPanel = function() enabled:SetChecked(ns.db.marksBar.enabled); locked:SetChecked(ns.db.marksBar.locked); mouseover:SetChecked(ns.db.marksBar.mouseover) end
end

function module:Refresh() if refreshPanel then refreshPanel() end end
function module:Initialize() CreateBar() end
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function() if pendingLayout then ApplyLayout() else ApplyVisibility() end end)
C.RegisterModule("marks", module)
