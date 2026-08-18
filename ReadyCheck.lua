local _, ns = ...
local C = ns.Core
local module = { title = "Ready Check", icon = "Interface\\RaidFrame\\ReadyCheck-Ready" }
local T, M = ns.Theme, ns.Media
local window, ticker, hideTimer, scheduledRefresh
local rows, responses = {}, {}
local ROW_HEIGHT = 25
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

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

local function AuraText(value)
    return value and "|cff4de87a●|r" or "|cff58606d–|r"
end

local function SetReadyStatus(row, status)
    if status == "ready" then
        row.readyBackground:SetColorTexture(T.success[1], T.success[2], T.success[3], 0.9)
        row.readyIcon:SetTexture(M.check)
        row.readyIcon:SetVertexColor(1, 1, 1)
        row.ready:SetText("PRÊT")
        row.ready:SetTextColor(0.015, 0.08, 0.035)
    elseif status == "notready" then
        row.readyBackground:SetColorTexture(T.danger[1], T.danger[2], T.danger[3], 0.82)
        row.readyIcon:SetTexture(M.cross)
        row.readyIcon:SetVertexColor(1, 1, 1)
        row.ready:SetText("NON")
        row.ready:SetTextColor(1, 1, 1)
    elseif status == "afk" then
        row.readyBackground:SetColorTexture(T.warning[1], T.warning[2], T.warning[3], 0.78)
        row.readyIcon:SetTexture(M.cross)
        row.readyIcon:SetVertexColor(0.15, 0.08, 0.01)
        row.ready:SetText("ABS")
        row.ready:SetTextColor(0.12, 0.07, 0.01)
    else
        row.readyBackground:SetColorTexture(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 1)
        row.readyIcon:SetTexture(M.arrow)
        row.readyIcon:SetVertexColor(unpack(T.warning))
        row.ready:SetText("…")
        row.ready:SetTextColor(unpack(T.warning))
    end
end

local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(565, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.035 or 0.012)
    row.background = background

    local classBar = row:CreateTexture(nil, "BORDER")
    classBar:SetPoint("TOPLEFT", 0, -2)
    classBar:SetPoint("BOTTOMLEFT", 0, 2)
    classBar:SetWidth(2)
    row.classBar = classBar

    local function Cell(x, width, justify)
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", x, 0)
        text:SetWidth(width)
        text:SetJustifyH(justify or "CENTER")
        return text
    end
    row.name = Cell(7, 127, "LEFT")

    local readyBadge = CreateFrame("Frame", nil, row)
    readyBadge:SetSize(52, 18)
    readyBadge:SetPoint("LEFT", 137, 0)
    local readyBackground = readyBadge:CreateTexture(nil, "BACKGROUND")
    readyBackground:SetAllPoints()
    row.readyBackground = readyBackground
    local readyIcon = readyBadge:CreateTexture(nil, "ARTWORK")
    readyIcon:SetSize(11, 11)
    readyIcon:SetPoint("LEFT", 4, 0)
    row.readyIcon = readyIcon
    row.ready = readyBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.ready:SetPoint("LEFT", readyIcon, "RIGHT", 3, 0)
    row.ready:SetPoint("RIGHT", readyBadge, "RIGHT", -3, 0)
    row.ready:SetJustifyH("CENTER")

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
    window:SetSize(610, 550)
    window:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetScript("OnHide", StopTimers)
    window:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
    window:SetBackdropColor(T.background[1], T.background[2], T.background[3], 0.985)
    window:SetBackdropBorderColor(unpack(T.border))

    local headerBackground = window:CreateTexture(nil, "BACKGROUND")
    headerBackground:SetPoint("TOPLEFT", 1, -1)
    headerBackground:SetPoint("TOPRIGHT", -1, -1)
    headerBackground:SetHeight(60)
    headerBackground:SetColorTexture(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 0.98)
    local headerLine = window:CreateTexture(nil, "ARTWORK")
    headerLine:SetPoint("TOPLEFT", 1, -59)
    headerLine:SetPoint("TOPRIGHT", -1, -59)
    headerLine:SetHeight(2)
    headerLine:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 0.75)

    local logo = window:CreateTexture(nil, "ARTWORK")
    logo:SetSize(43, 43)
    logo:SetPoint("TOPLEFT", 11, -8)
    logo:SetTexture(M.logo)
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -5)
    title:SetText("READY CHECK")
    title:SetTextColor(unpack(T.text))
    local subtitle = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("PRÉPARATION DU GROUPE")
    subtitle:SetTextColor(unpack(T.muted))

    local counterBadge = CreateFrame("Frame", nil, window, "BackdropTemplate")
    counterBadge:SetSize(76, 28)
    counterBadge:SetPoint("TOPRIGHT", -47, -16)
    counterBadge:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
    counterBadge:SetBackdropColor(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3], 1)
    counterBadge:SetBackdropBorderColor(unpack(T.border))
    window.counterBadge = counterBadge
    window.counter = counterBadge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    window.counter:SetPoint("CENTER")
    local close = ns.CreateCloseButton(window)
    close:SetPoint("TOPRIGHT", -8, -8)

    local headers = { { "Joueur", 4, 130, "LEFT" }, { "Prêt", 138, 55 }, { "Repas", 198, 48 }, { "Flacon", 250, 48 }, { "Rune", 302, 48 }, { "Intel", 356, 42 }, { "PA", 402, 42 }, { "Endu", 448, 42 }, { "D", 494, 28 }, { "C", 526, 28 } }
    local header = CreateFrame("Frame", nil, window, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 14, -70)
    header:SetSize(565, 25)
    header:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
    header:SetBackdropColor(T.panelRaised[1], T.panelRaised[2], T.panelRaised[3], 1)
    header:SetBackdropBorderColor(unpack(T.border))
    for _, data in ipairs(headers) do
        local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", data[2], 0)
        text:SetWidth(data[3])
        text:SetJustifyH(data[4] or "CENTER")
        text:SetText(data[1])
        text:SetTextColor(unpack(T.accent))
    end
    local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -99)
    scroll:SetPoint("BOTTOMRIGHT", -31, 14)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(565, 435)
    scroll:SetScrollChild(child)
    window.child = child
    window:Hide()
end

local function Refresh()
    scheduledRefresh = nil
    if not window or not window:IsShown() then return end
    local count = IsInRaid() and GetNumGroupMembers() or 0
    local readyCount = 0
    window.child:SetHeight(math.max(435, count * ROW_HEIGHT))
    for index = 1, count do
        local unit = "raid" .. index
        local name, _, _, _, _, classFileName = GetRaidRosterInfo(index)
        local row = rows[index] or CreateRow(window.child, index)
        rows[index] = row
        local color = classFileName and RAID_CLASS_COLORS[classFileName]
        row.name:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
        row.classBar:SetColorTexture(color and color.r or 0.5, color and color.g or 0.5, color and color.b or 0.5, 0.9)
        row.name:SetText(C.ShortName(name) or "?")
        local status = GetReadyCheckStatus(unit) or responses[unit]
        if status == "ready" then readyCount = readyCount + 1 end
        SetReadyStatus(row, status)
        row.background:SetColorTexture(
            status == "notready" and T.danger[1] or 1,
            status == "notready" and T.danger[2] or 1,
            status == "notready" and T.danger[3] or 1,
            status == "notready" and 0.055 or (index % 2 == 0 and 0.035 or 0.012)
        )
        local state = GetAuraState(unit)
        row.food:SetText(AuraText(state.food)); row.flask:SetText(AuraText(state.flask)); row.rune:SetText(AuraText(state.rune))
        row.intellect:SetText(AuraText(state.intellect)); row.attackPower:SetText(AuraText(state.attackPower)); row.stamina:SetText(AuraText(state.stamina))
        row.druid:SetText(AuraText(state.druid)); row.shaman:SetText(AuraText(state.shaman))
        row:Show()
    end
    for index = count + 1, #rows do rows[index]:Hide() end
    local complete = count > 0 and readyCount == count
    window.counterBadge:SetBackdropColor(
        complete and 0.07 or T.accentSoft[1],
        complete and 0.30 or T.accentSoft[2],
        complete and 0.14 or T.accentSoft[3],
        1
    )
    window.counter:SetText((complete and "|cff58ed82%d / %d|r" or "|cff5ec4ff%d|r / %d"):format(readyCount, count))
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
    local heading = ns.CreatePageHeader(
        parent,
        "Ready Check enrichi",
        "Visualise instantanément les réponses, consommables et buffs de raid.",
        module.icon
    )
    local section = ns.CreateSection(parent, "Contrôle de préparation", heading, -10)
    section:SetHeight(220)
    local enabled = ns.CreateCheck(section, "Afficher automatiquement le tableau", section.heading, ns.db.readyCheck.enabled, function(value) ns.db.readyCheck.enabled = value; if not value and window then window:Hide() end end)
    local help = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -12)
    help:SetWidth(500)
    help:SetJustifyH("LEFT")
    help:SetText("Affiche l’état de préparation, les consommables et les principaux buffs de raid. Le scan est piloté par les événements et s’arrête dès que la fenêtre est fermée.")
    help:SetTextColor(unpack(T.muted))
    local test = ns.CreateButton(section, "Tester en raid", 125, function() ShowReadyCheck(true) end)
    test:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -18)
    module.Refresh = function() ns.SetCheck(enabled, ns.db.readyCheck.enabled) end
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
