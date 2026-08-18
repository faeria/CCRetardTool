local addonName, ns = ...
local C = ns.Core
local module = { title = "Automatisation", icon = "Interface\\GroupFrame\\UI-Group-LeaderIcon" }
local guildRanks, guildRankByPlayer = {}, {}
local refreshPanel

local function RefreshGuildRoster()
    wipe(guildRanks)
    wipe(guildRankByPlayer)
    if not IsInGuild() then return end
    for index = 1, GetNumGuildMembers() do
        local name, rankName = GetGuildRosterInfo(index)
        if name and rankName then
            guildRanks[rankName] = true
            guildRankByPlayer[C.ShortName(name)] = rankName
        end
    end
end

local function ShouldPromote(name)
    local config = ns.db.autoPromote
    return config.names[name] or config.names[C.ShortName(name)] or config.rankNames[guildRankByPlayer[C.ShortName(name)]]
end

local function CheckPromotions()
    if not ns.db.autoPromote.enabled or not IsInRaid() or not UnitIsGroupLeader("player") or InCombatLockdown() then return end
    for index = 1, GetNumGroupMembers() do
        local name, rank = GetRaidRosterInfo(index)
        if name and rank == 0 and ShouldPromote(name) then
            PromoteToAssistant(name)
            C.Print(C.ShortName(name) .. " promu assistant de raid.")
        end
    end
end

local function ShouldLogHere()
    local _, instanceType, difficultyID = GetInstanceInfo()
    local config = ns.db.logging
    if instanceType == "raid" then
        return (difficultyID == 17 and config.lfr) or (difficultyID == 14 and config.normal)
            or (difficultyID == 15 and config.heroic) or (difficultyID == 16 and config.mythic)
    end
    if instanceType == "party" then
        return (difficultyID == 23 and config.dungeonMythic) or (difficultyID == 8 and config.dungeonMythicPlus)
    end
    return false
end

local logTimer
local function CheckCombatLog()
    if logTimer then logTimer:Cancel() end
    logTimer = C_Timer.NewTimer(1, function()
        logTimer = nil
        local wanted, active = ShouldLogHere(), LoggingCombat()
        if wanted and not active then
            LoggingCombat(true)
            ns.db.logging.startedByAddon = true
            C.Print("Journal de combat démarré.")
        elseif not wanted and active and ns.db.logging.startedByAddon then
            LoggingCombat(false)
            ns.db.logging.startedByAddon = false
            C.Print("Journal de combat arrêté.")
        elseif not active then
            ns.db.logging.startedByAddon = false
        end
    end)
end

local function IsKeyword(message)
    local normalized = C.Trim(message)
    if not normalized then return false end
    normalized = normalized:lower()
    for keyword in ns.db.invite.keywords:gmatch("[^,;]+") do
        if C.Trim(keyword):lower() == normalized then return true end
    end
    return false
end

local function HandleWhisper(message, sender)
    local config = ns.db.invite
    if not config.enabled or not IsKeyword(message) then return end
    if config.guildOnly and not guildRankByPlayer[C.ShortName(sender)] then return end
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return end
    if InCombatLockdown() then
        SendChatMessage("Invitation impossible pendant le combat.", "WHISPER", nil, sender)
        return
    end
    if IsInGroup() and not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") then return end
    if C_PartyInfo and C_PartyInfo.InviteUnit then
        C_PartyInfo.InviteUnit(sender)
    elseif InviteUnit then
        InviteUnit(sender)
    end
end

function module:BuildPanel(parent)
    local heading = ns.CreatePageHeader(
        parent,
        "Automatisation de raid",
        "Prépare le groupe et le journal sans intervention répétitive.",
        module.icon
    )

    local promote = ns.CreateSection(parent, "Promotions automatiques", heading, -10)
    promote:SetHeight(200)
    local enabled = ns.CreateCheck(promote, "Promouvoir automatiquement les joueurs configurés", promote.heading, ns.db.autoPromote.enabled, function(value) ns.db.autoPromote.enabled = value; CheckPromotions() end)
    local nameLabel = promote:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameLabel:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -10)
    nameLabel:SetText("Joueurs (Nom-Royaume, séparés par des virgules)")
    nameLabel:SetTextColor(unpack(ns.Theme.muted))
    local names = ns.CreateEditBox(promote, 420)
    names:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -5)
    local saveNames = ns.CreateButton(promote, "Enregistrer", 105, function()
        wipe(ns.db.autoPromote.names)
        for name in names:GetText():gmatch("[^,;\n]+") do
            name = C.Trim(name)
            if name then ns.db.autoPromote.names[name] = true end
        end
        CheckPromotions()
        C.Print("Liste de promotions mise à jour.")
    end)
    saveNames:SetPoint("LEFT", names, "RIGHT", 8, 0)
    local rankLabel = promote:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rankLabel:SetPoint("TOPLEFT", names, "BOTTOMLEFT", 0, -10)
    rankLabel:SetText("Rangs de guilde (noms exacts, séparés par des virgules)")
    rankLabel:SetTextColor(unpack(ns.Theme.muted))
    local ranks = ns.CreateEditBox(promote, 420)
    ranks:SetPoint("TOPLEFT", rankLabel, "BOTTOMLEFT", 0, -5)
    local saveRanks = ns.CreateButton(promote, "Enregistrer", 105, function()
        wipe(ns.db.autoPromote.rankNames)
        for rankName in ranks:GetText():gmatch("[^,;\n]+") do
            rankName = C.Trim(rankName)
            if rankName then ns.db.autoPromote.rankNames[rankName] = true end
        end
        CheckPromotions()
        C.Print("Rangs de promotion mis à jour.")
    end)
    saveRanks:SetPoint("LEFT", ranks, "RIGHT", 8, 0)

    local invite = ns.CreateSection(parent, "Invitations par chuchotement", promote, -9)
    invite:SetHeight(120)
    local inviteEnabled = ns.CreateCheck(invite, "Activer les invitations automatiques", invite.heading, ns.db.invite.enabled, function(value) ns.db.invite.enabled = value end)
    local guildOnly = ns.CreateCheck(invite, "Membres de guilde uniquement", inviteEnabled, ns.db.invite.guildOnly, function(value) ns.db.invite.guildOnly = value end)
    inviteEnabled:SetWidth(310)
    guildOnly:SetWidth(310)
    local keywordLabel = invite:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    keywordLabel:SetPoint("TOPLEFT", 342, -43)
    keywordLabel:SetText("Mots-clés")
    keywordLabel:SetTextColor(unpack(ns.Theme.muted))
    local keyword = ns.CreateEditBox(invite, 205)
    keyword:SetPoint("TOPLEFT", keywordLabel, "BOTTOMLEFT", 0, -5)
    keyword:SetText(ns.db.invite.keywords)
    keyword:SetScript("OnEnterPressed", function(self) ns.db.invite.keywords = C.Trim(self:GetText()) or "inv"; self:ClearFocus() end)

    local logging = ns.CreateSection(parent, "Journal de combat automatique", invite, -9)
    logging:SetHeight(126)
    local labels = {
        { "LFR", "lfr" }, { "Normal", "normal" }, { "Héroïque", "heroic" },
        { "Mythique", "mythic" }, { "Donjon M0", "dungeonMythic" }, { "Mythique+", "dungeonMythicPlus" },
    }
    local checks = {}
    for index, data in ipairs(labels) do
        local label, configKey = data[1], data[2]
        local check = ns.CreateCheck(logging, label, logging.heading, ns.db.logging[configKey], function(value)
            ns.db.logging[configKey] = value
            CheckCombatLog()
        end)
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", 13 + ((index - 1) % 3) * 184, -39 - math.floor((index - 1) / 3) * 34)
        check:SetWidth(170)
        checks[configKey] = check
    end
    refreshPanel = function()
        local list = {}
        for name in pairs(ns.db.autoPromote.names) do list[#list + 1] = name end
        table.sort(list)
        names:SetText(table.concat(list, ", "))
        local rankList = {}
        for rankName in pairs(ns.db.autoPromote.rankNames) do rankList[#rankList + 1] = rankName end
        table.sort(rankList)
        ranks:SetText(table.concat(rankList, ", "))
        ns.SetCheck(enabled, ns.db.autoPromote.enabled)
        ns.SetCheck(inviteEnabled, ns.db.invite.enabled)
        ns.SetCheck(guildOnly, ns.db.invite.guildOnly)
        keyword:SetText(ns.db.invite.keywords)
        for key, check in pairs(checks) do ns.SetCheck(check, ns.db.logging[key]) end
    end
end

function module:Refresh() if refreshPanel then refreshPanel() end end
function module:Initialize()
    if ns.db.logging.startedByAddon and not LoggingCombat() then ns.db.logging.startedByAddon = false end
    if IsInGuild() then C_GuildInfo.GuildRoster() end
    RefreshGuildRoster()
    CheckCombatLog()
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "CHAT_MSG_WHISPER", "GUILD_ROSTER_UPDATE", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_ENABLED", "CHALLENGE_MODE_START" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, ...)
    if not ns.db then return end
    if event == "CHAT_MSG_WHISPER" then HandleWhisper(...)
    elseif event == "GUILD_ROSTER_UPDATE" then RefreshGuildRoster(); CheckPromotions()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_REGEN_ENABLED" then CheckPromotions()
    else CheckCombatLog() end
end)

C.RegisterModule("automation", module)
