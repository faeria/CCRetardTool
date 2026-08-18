local _, ns = ...
local C = ns.Core
local module = { title = "Focus", icon = "Interface\\Icons\\Ability_Hunter_FocusedAim" }
local T = ns.Theme
local secureButton
local pendingApply
local statusText, statusBadge

local function BindingKey(config)
    return config.modifier:upper() .. "-BUTTON" .. config.button
end

local function UpdateStatus()
    if not statusText then return end
    local enabled = ns.db.focus.enabled
    statusText:SetText(enabled and ("ACTIF  •  " .. BindingKey(ns.db.focus)) or "DÉSACTIVÉ")
    statusText:SetTextColor(enabled and 0.12 or 0.78, enabled and 0.22 or 0.22, enabled and 0.08 or 0.22)
    statusBadge:SetBackdropColor(
        enabled and T.success[1] or T.danger[1],
        enabled and T.success[2] or T.danger[2],
        enabled and T.success[3] or T.danger[3],
        enabled and 0.86 or 0.72
    )
end

local function ApplyBinding()
    UpdateStatus()
    if not secureButton or InCombatLockdown() then pendingApply = true; return end
    pendingApply = false
    ClearOverrideBindings(secureButton)
    if ns.db.focus.enabled then
        SetOverrideBindingClick(secureButton, true, BindingKey(ns.db.focus), secureButton:GetName(), "LeftButton")
    end
end

local function SetDropdownValue(dropdown, value, labels)
    UIDropDownMenu_SetSelectedValue(dropdown, value)
    UIDropDownMenu_SetText(dropdown, labels[value])
end

function module:BuildPanel(parent)
    local heading = ns.CreatePageHeader(
        parent,
        "Focus sécurisé",
        "Assigne le focus sous la souris avec un raccourci fiable, même en combat.",
        module.icon
    )
    local section = ns.CreateSection(parent, "Raccourci mouseover", heading, -10)
    section:SetHeight(245)
    local enabled = ns.CreateCheck(section, "Activer le raccourci de focus", section.heading, ns.db.focus.enabled, function(value) ns.db.focus.enabled = value; ApplyBinding() end)
    local help = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -10)
    help:SetWidth(500)
    help:SetJustifyH("LEFT")
    help:SetText("Place le focus sur l’unité sous la souris via un bouton sécurisé. Les changements effectués en combat sont appliqués automatiquement à la fin du combat.")
    help:SetTextColor(unpack(T.muted))

    statusBadge = CreateFrame("Frame", nil, section, "BackdropTemplate")
    statusBadge:SetSize(190, 28)
    statusBadge:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -16)
    statusBadge:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    statusBadge:SetBackdropBorderColor(unpack(T.border))
    statusText = statusBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("CENTER")

    local modifiers = { shift = "Maj", ctrl = "Ctrl", alt = "Alt" }
    local modifierOrder = { "shift", "ctrl", "alt" }
    local buttons = { ["1"] = "Clic gauche", ["2"] = "Clic droit", ["3"] = "Clic milieu", ["4"] = "Bouton 4", ["5"] = "Bouton 5" }
    local buttonOrder = { "1", "2", "3", "4", "5" }
    local modifierLabel = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modifierLabel:SetPoint("TOPLEFT", statusBadge, "BOTTOMLEFT", 0, -15)
    modifierLabel:SetText("MODIFICATEUR")
    modifierLabel:SetTextColor(unpack(T.muted))
    local mouseLabel = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mouseLabel:SetPoint("LEFT", modifierLabel, "RIGHT", 98, 0)
    mouseLabel:SetText("BOUTON DE SOURIS")
    mouseLabel:SetTextColor(unpack(T.muted))

    local modifier = CreateFrame("Frame", nil, section, "UIDropDownMenuTemplate")
    modifier:SetPoint("TOPLEFT", modifierLabel, "BOTTOMLEFT", -16, -3)
    UIDropDownMenu_SetWidth(modifier, 110)
    UIDropDownMenu_Initialize(modifier, function(_, level)
        for _, value in ipairs(modifierOrder) do
            local label = modifiers[value]
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = label, value
            info.checked = ns.db.focus.modifier == value
            info.func = function() ns.db.focus.modifier = value; SetDropdownValue(modifier, value, modifiers); ApplyBinding() end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local mouse = CreateFrame("Frame", nil, section, "UIDropDownMenuTemplate")
    mouse:SetPoint("LEFT", modifier, "RIGHT", 15, 0)
    UIDropDownMenu_SetWidth(mouse, 125)
    UIDropDownMenu_Initialize(mouse, function(_, level)
        for _, value in ipairs(buttonOrder) do
            local label = buttons[value]
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = label, value
            info.checked = ns.db.focus.button == value
            info.func = function() ns.db.focus.button = value; SetDropdownValue(mouse, value, buttons); ApplyBinding() end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    SetDropdownValue(modifier, ns.db.focus.modifier, modifiers)
    SetDropdownValue(mouse, ns.db.focus.button, buttons)
    module.Refresh = function()
        ns.SetCheck(enabled, ns.db.focus.enabled)
        SetDropdownValue(modifier, ns.db.focus.modifier, modifiers)
        SetDropdownValue(mouse, ns.db.focus.button, buttons)
        ApplyBinding()
    end
end

function module:Initialize()
    secureButton = CreateFrame("Button", "CCRaidToolsFocusButton", UIParent, "SecureActionButtonTemplate")
    secureButton:SetAttribute("type", "macro")
    secureButton:SetAttribute("macrotext", "/focus [@mouseover,exists,nodead]")
    ApplyBinding()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function() if pendingApply then ApplyBinding() end end)
C.RegisterModule("focus", module)
