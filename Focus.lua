local _, ns = ...
local C = ns.Core
local module = { title = "Focus", icon = "Interface\\Icons\\Ability_Hunter_FocusedAim" }
local secureButton
local pendingApply
local statusText

local function BindingKey(config)
    return config.modifier:upper() .. "-BUTTON" .. config.button
end

local function ApplyBinding()
    if not secureButton or InCombatLockdown() then pendingApply = true; return end
    pendingApply = false
    ClearOverrideBindings(secureButton)
    if ns.db.focus.enabled then
        SetOverrideBindingClick(secureButton, true, BindingKey(ns.db.focus), secureButton:GetName(), "LeftButton")
    end
    if statusText then statusText:SetText(ns.db.focus.enabled and ("Actif : " .. BindingKey(ns.db.focus)) or "Désactivé") end
end

local function SetDropdownValue(dropdown, value, labels)
    UIDropDownMenu_SetSelectedValue(dropdown, value)
    UIDropDownMenu_SetText(dropdown, labels[value])
end

function module:BuildPanel(parent)
    local heading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 8, -8)
    heading:SetText("Focus sécurisé")
    local section = ns.CreateSection(parent, "Raccourci mouseover", heading, -14)
    section:SetHeight(210)
    local enabled = ns.CreateCheck(section, "Activer le raccourci de focus", section.heading, ns.db.focus.enabled, function(value) ns.db.focus.enabled = value; ApplyBinding() end)
    local help = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -10)
    help:SetWidth(500)
    help:SetJustifyH("LEFT")
    help:SetText("Place le focus sur l’unité sous la souris via un bouton sécurisé. Les changements effectués en combat sont appliqués automatiquement à la fin du combat.")
    help:SetTextColor(0.72, 0.74, 0.8)
    statusText = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -18)
    statusText:SetTextColor(0.4, 1, 0.55)

    local modifiers = { shift = "Maj", ctrl = "Ctrl", alt = "Alt" }
    local buttons = { ["1"] = "Clic gauche", ["2"] = "Clic droit", ["3"] = "Clic milieu", ["4"] = "Bouton 4", ["5"] = "Bouton 5" }
    local modifier = CreateFrame("Frame", nil, section, "UIDropDownMenuTemplate")
    modifier:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", -16, -10)
    UIDropDownMenu_SetWidth(modifier, 110)
    UIDropDownMenu_Initialize(modifier, function(_, level)
        for value, label in pairs(modifiers) do
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
        for value, label in pairs(buttons) do
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
        enabled:SetChecked(ns.db.focus.enabled)
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
