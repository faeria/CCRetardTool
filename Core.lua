local addonName, ns = ...

local C = {}
ns.Core = C
_G.CCRaidTools = ns

local DB_VERSION = 2
local PREFIX = "|cff2eabffCC RaidTools|r"

local defaults = {
    version = DB_VERSION,
    minimap = { hidden = false },
    window = { point = "CENTER", relativePoint = "CENTER", x = 220, y = 0 },
    autoPromote = { enabled = true, names = {}, rankNames = {} },
    invite = { enabled = true, keywords = "inv,invite", guildOnly = false },
    logging = {
        lfr = false, normal = false, heroic = false, mythic = false,
        dungeonMythic = false, dungeonMythicPlus = false,
        startedByAddon = false,
    },
    readyCheck = { enabled = true, autoHideSeconds = 30 },
    marksBar = {
        enabled = false, locked = false, mouseover = false,
        orientation = "HORIZONTAL", scale = 1, alpha = 1,
        point = "CENTER", relativePoint = "CENTER", x = 0, y = -180,
    },
    focus = { enabled = true, modifier = "shift", button = "1" },
}

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function MigrateLegacy(db, force)
    if type(AutoPromoteDB) ~= "table" then return end
    if type(AutoPromoteDB.names) == "table" and (force or not next(db.autoPromote.names)) then
        for name, enabled in pairs(AutoPromoteDB.names) do db.autoPromote.names[name] = enabled end
    end
    if type(AutoPromoteDB.rankNames) == "table" and (force or not next(db.autoPromote.rankNames)) then
        for rank, enabled in pairs(AutoPromoteDB.rankNames) do db.autoPromote.rankNames[rank] = enabled end
    end
    if type(AutoPromoteDB.logging) == "table" then
        for key in pairs(defaults.logging) do
            if key ~= "startedByAddon" and AutoPromoteDB.logging[key] ~= nil then
                db.logging[key] = AutoPromoteDB.logging[key] and true or false
            end
        end
    end
    if AutoPromoteDB.loggingStartedByAddon ~= nil then
        db.logging.startedByAddon = AutoPromoteDB.loggingStartedByAddon and true or false
    end
    for oldKey, newKey in pairs({ inviteTool = "invite", marksBar = "marksBar", focus = "focus" }) do
        local legacy = AutoPromoteDB[oldKey]
        if type(legacy) == "table" then
            for key, value in pairs(legacy) do
                local mapped = key == "keyword" and "keywords" or key == "mouseButton" and "button" or key
                db[newKey][mapped] = value
            end
        end
    end
    if AutoPromoteDB.raidCheckEnabled ~= nil then db.readyCheck.enabled = AutoPromoteDB.raidCheckEnabled and true or false end
    if type(AutoPromoteDB.windowPos) == "table" and AutoPromoteDB.windowPos.point then
        for key, value in pairs(AutoPromoteDB.windowPos) do db.window[key] = value end
    end
end

function C.InitializeDatabase()
    local fresh = type(CCRaidToolsDB) ~= "table"
    CCRaidToolsDB = CCRaidToolsDB or {}
    CopyDefaults(defaults, CCRaidToolsDB)
    if fresh or (CCRaidToolsDB.version or 0) < DB_VERSION then MigrateLegacy(CCRaidToolsDB, fresh) end
    CCRaidToolsDB.version = DB_VERSION
    ns.db = CCRaidToolsDB
end

function C.Print(message)
    print(PREFIX .. ": " .. tostring(message))
end

function C.Trim(value)
    if type(value) ~= "string" then return nil end
    value = value:match("^%s*(.-)%s*$")
    return value ~= "" and value or nil
end

function C.ShortName(name)
    return name and Ambiguate(name, "short") or nil
end

function C.SavePosition(frame, destination)
    if not frame or not destination then return end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if point then
        destination.point, destination.relativePoint = point, relativePoint or point
        destination.x, destination.y = x or 0, y or 0
    end
end

function C.RestorePosition(frame, source)
    frame:ClearAllPoints()
    frame:SetPoint(source.point or "CENTER", UIParent, source.relativePoint or source.point or "CENTER", source.x or 0, source.y or 0)
end

ns.modules, ns.moduleOrder = {}, {}
function C.RegisterModule(id, definition)
    assert(type(id) == "string" and type(definition) == "table", "Invalid CC RaidTools module")
    if not ns.modules[id] then ns.moduleOrder[#ns.moduleOrder + 1] = id end
    ns.modules[id] = definition
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, _, loadedAddon)
    if loadedAddon ~= addonName then return end
    C.InitializeDatabase()
    for _, id in ipairs(ns.moduleOrder) do
        local module = ns.modules[id]
        if module.Initialize then module:Initialize() end
    end
end)

SLASH_CCRAIDTOOLS1 = "/ccrt"
SlashCmdList.CCRAIDTOOLS = function()
    if ns.ToggleWindow then ns.ToggleWindow() end
end
