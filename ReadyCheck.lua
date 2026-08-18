local _, ns = ...
local C = ns.Core
local module = { title = "Ready Check", icon = "Interface\\RaidFrame\\ReadyCheck-Ready" }
local window, ticker, hideTimer, scheduledRefresh
local rows, responses = {}, {}
local ROW_HEIGHT = 22

local auraGroups = {
    food = { [308488] = true, [308506] = true, [327708] = true, [382145] = true, [382150] = true, [382152] = true, [382153] = true, [382157] = true, [382230] = true, [382231] = true, [382232] = true },
    flask = { [1236763] = true, [1239355] = true, [1235057] = true, [1239755] = true, [1236767] = true, [1235111] = true, [1235110] = true, [1235108] = true },
    rune = { [224001] = true, [270058] = true, [317065] = true, [347901] = true, [367405] = true, [393438] = true, [453250] = true, [1234969] = true, [1242347] = true, [1264426] = true },
    intellect = { [1459] = true, [264760] = true },
    attackPower = { [6673] = true, [264761] = true },
    stamina = { [21562] = true, [264764] = true },
    druid = { [1126] = true },
    shaman = { [462854] = true },
}

local function StopTimers()
    if ticker then ticker:Cancel(); ticker = nil end
    if scheduledRefresh then scheduledRefresh:Cancel(); scheduledRefresh = nil end
end

local function SafeAuraID(aura)
    if not aura then return nil end
    local ok, id = pcall(function() return aura.spellId end)
    if not ok then return nil end
    if issecretvalue and issecretvalue(id) then return nil end
    if canaccessvalue and not canaccessvalue(id) then return nil end
    return id
end

local function GetAuraState(unit)
    local state = {}
    if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then return state end
    for index = 1, 80 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
        if not aura then break end
        local id = SafeAuraID(aura)
        if id then
            for group, ids in pairs(auraGroups) do
                if ids[id] then state[group] = true end
            end
        end
    end
    return state
end

local function StatusText(status)
    if status == "ready" then return "|cff39e66dPRÊT|r" end
    if status == "notready" then return "|cffff5c5cNON|r" end
    if status == "afk" then return "|cffffa64dABS|r" end
    return "|cffffcc4d…|r"
end

local function AuraText(value)
    return value and "|cff39e66d✓|r" or "|cffff5c5c–|r"
end

local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(555, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    if index % 2 == 0 then
        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(1, 1, 1, 0.025)
    end
    local function Cell(x, width, justify)
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", x, 0)
        text:SetWidth(width)
        text:SetJustifyH(justify or "CENTER")
        return text
    end
    row.name = Cell(4, 130, "LEFT")
    row.ready = Cell(138, 55)
    row.food = Cell(198, 48)
    row.flask = Cell(250, 48)
    row.rune = Cell(302, 48)
    row.intellect = Cell(356, 42)
    row.attackPower = Cell(402, 42)
    row.stamina = Cell(448, 42)
    row.druid = Cell(494, 28)
    row.shaman = Cell(526, 28)
    return row
end

local function BuildWindow()
    if window then return end
    window = CreateFrame("Frame", "CCRaidToolsReadyCheckFrame", UIParent, "BackdropTemplate")
    window:SetSize(590, 520)
    window:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetScript("OnHide", StopTimers)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    window:SetBackdropColor(0.012, 0.014, 0.022, 0.97)
    window:SetBackdropBorderColor(0.12, 0.13, 0.2, 1)
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -13)
    title:SetText("READY CHECK")
    title:SetTextColor(0.451, 0.506, 1)
    window.counter = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    window.counter:SetPoint("LEFT", title, "RIGHT", 12, 0)
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    local headers = { { "Joueur", 4, 130, "LEFT" }, { "Prêt", 138, 55 }, { "Repas", 198, 48 }, { "Flacon", 250, 48 }, { "Rune", 302, 48 }, { "Intel", 356, 42 }, { "PA", 402, 42 }, { "Endu", 448, 42 }, { "D", 494, 28 }, { "C", 526, 28 } }
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT", 14, -42)
    header:SetSize(555, 22)
    for _, data in ipairs(headers) do
        local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", data[2], 0); text:SetWidth(data[3]); text:SetJustifyH(data[4] or "CENTER"); text:SetText(data[1]); text:SetTextColor(0.451, 0.506, 1)
    end
    local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -66)
    scroll:SetPoint("BOTTOMRIGHT", -31, 14)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(555, 420)
    scroll:SetScrollChild(child)
    window.child = child
    window:Hide()
end

local function Refresh()
    scheduledRefresh = nil
    if not window or not window:IsShown() then return end
    local count = IsInRaid() and GetNumGroupMembers() or 0
    local readyCount = 0
    window.child:SetHeight(math.max(420, count * ROW_HEIGHT))
    for index = 1, count do
        local unit = "raid" .. index
        local name, _, _, _, _, classFileName = GetRaidRosterInfo(index)
        local row = rows[index] or CreateRow(window.child, index)
        rows[index] = row
        local color = classFileName and RAID_CLASS_COLORS[classFileName]
        row.name:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
        row.name:SetText(C.ShortName(name) or "?")
        local status = GetReadyCheckStatus(unit) or responses[unit]
        if status == "ready" then readyCount = readyCount + 1 end
        row.ready:SetText(StatusText(status))
        local state = GetAuraState(unit)
        row.food:SetText(AuraText(state.food)); row.flask:SetText(AuraText(state.flask)); row.rune:SetText(AuraText(state.rune))
        row.intellect:SetText(AuraText(state.intellect)); row.attackPower:SetText(AuraText(state.attackPower)); row.stamina:SetText(AuraText(state.stamina))
        row.druid:SetText(AuraText(state.druid)); row.shaman:SetText(AuraText(state.shaman))
        row:Show()
    end
    for index = count + 1, #rows do rows[index]:Hide() end
    window.counter:SetText(("|cff39e66d%d|r / %d"):format(readyCount, count))
end

local function ScheduleRefresh(delay)
    if not window or not window:IsShown() or scheduledRefresh then return end
    scheduledRefresh = C_Timer.NewTimer(delay or 0.15, Refresh)
end

local function ShowReadyCheck(force)
    if not force and (not ns.db.readyCheck.enabled or not IsInRaid()) then return end
    if force and not IsInRaid() then C.Print("Le test nécessite un groupe de raid."); return end
    BuildWindow()
    wipe(responses)
    if hideTimer then hideTimer:Cancel(); hideTimer = nil end
    window:Show()
    Refresh()
    StopTimers()
    ticker = C_Timer.NewTicker(1.5, Refresh)
end

local function FinishReadyCheck()
    Refresh()
    StopTimers()
    local delay = tonumber(ns.db.readyCheck.autoHideSeconds) or 30
    if delay > 0 then hideTimer = C_Timer.NewTimer(delay, function() if window then window:Hide() end end) end
end

function module:BuildPanel(parent)
    local heading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 8, -8)
    heading:SetText("Ready Check enrichi")
    local section = ns.CreateSection(parent, "Contrôle de préparation", heading, -14)
    section:SetHeight(220)
    local enabled = ns.CreateCheck(section, "Afficher automatiquement le tableau", section.heading, ns.db.readyCheck.enabled, function(value) ns.db.readyCheck.enabled = value; if not value and window then window:Hide() end end)
    local help = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -12)
    help:SetWidth(500)
    help:SetJustifyH("LEFT")
    help:SetText("Affiche l’état de préparation, les consommables et les principaux buffs de raid. Le scan est piloté par les événements et s’arrête dès que la fenêtre est fermée.")
    help:SetTextColor(0.72, 0.74, 0.8)
    local test = ns.CreateButton(section, "Tester en raid", 125, function() ShowReadyCheck(true) end)
    test:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -18)
    module.Refresh = function() enabled:SetChecked(ns.db.readyCheck.enabled) end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_AURA", "GROUP_ROSTER_UPDATE" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, unit, response)
    if not ns.db then return end
    if event == "READY_CHECK" then ShowReadyCheck(false)
    elseif event == "READY_CHECK_CONFIRM" then responses[unit] = response and "ready" or "notready"; ScheduleRefresh()
    elseif event == "READY_CHECK_FINISHED" then FinishReadyCheck()
    elseif event == "UNIT_AURA" then if unit and unit:match("^raid%d+$") then ScheduleRefresh() end
    else ScheduleRefresh() end
end)
C.RegisterModule("readycheck", module)
