# AGENTS.md

## Purpose

This repository contains a World of Warcraft addon.

Act as an experienced World of Warcraft addon developer.

The primary objectives are:

1. Correctness
2. Compatibility with the targeted WoW client
3. Minimal taint
4. Combat lockdown safety
5. Good performance
6. Maintainable Lua code
7. Minimal unnecessary complexity

Never invent World of Warcraft APIs.

When an API is uncertain, deprecated, restricted, or version-dependent, verify its usage against the current WoW UI implementation or existing project code before using it.

---

# 1. Determine the Target WoW Client

Before making significant changes, inspect the repository.

In particular, inspect:

```text
*.toc
```

Determine whether the addon targets:

* Retail
* Classic Era
* Cataclysm Classic / current Classic progression client
* PTR
* Beta

Do not assume the target client when the repository already provides this information.

Inspect the `## Interface:` value from the TOC.

Example:

```toc
## Interface: XXXXX
## Title: MyAddon
## Author: Eric
## Version: 1.0.0
```

Do not arbitrarily modify the Interface version.

If multiple TOC files exist, assume the addon supports multiple WoW clients and preserve that compatibility unless explicitly instructed otherwise.

---

# 2. World of Warcraft API

Use the modern WoW API appropriate for the targeted client.

Prefer namespaced APIs when available.

For example, prefer APIs in namespaces such as:

```lua
C_AddOns
C_ChatInfo
C_Container
C_CurrencyInfo
C_Item
C_Map
C_QuestLog
C_Spell
C_Timer
C_UnitAuras
```

instead of old/deprecated global APIs when the target client provides the newer API.

However:

DO NOT replace existing APIs simply because a newer-looking API exists.

First verify that:

* the target WoW client supports it;
* the behavior is equivalent;
* the return values are compatible;
* the change does not break Classic compatibility.

---

# 3. API Verification

Never hallucinate a WoW function, event, widget method, mixin, constant, enum, or return value.

When unsure about an API:

1. Search the existing project.
2. Inspect Blizzard UI code when available.
3. Check how Blizzard itself calls the API.
4. Verify function arguments.
5. Verify return values.
6. Verify whether values can be unavailable or restricted.
7. Verify whether the API behaves differently in combat.

Do not rely blindly on old addon examples from the internet.

WoW addon APIs change regularly.

Existing Blizzard FrameXML/AddOns implementation is preferred evidence for actual API behavior.

---

# 4. Modern WoW API Restrictions

Modern WoW versions may restrict access to some information, especially during combat.

Treat combat-related data conservatively.

Do not attempt to bypass Blizzard restrictions.

Do not create logic designed to circumvent:

* protected functions;
* secure execution;
* combat lockdown;
* restricted combat information;
* secret/restricted values;
* protected frames;
* restricted unit information.

Never attempt to extract restricted information through:

* string conversion;
* arithmetic tricks;
* comparisons;
* table serialization;
* UI side effects;
* error messages;
* indirect API calls.

If Blizzard marks information as unavailable to addons, design around the restriction.

---

# 5. Combat Lockdown

Always consider:

```lua
InCombatLockdown()
```

before modifying protected UI elements.

Operations affecting protected frames may need to be deferred until combat ends.

Typical pattern:

```lua
if InCombatLockdown() then
    -- Defer the protected operation.
    return
end
```

When appropriate, wait for:

```text
PLAYER_REGEN_ENABLED
```

before performing the deferred action.

Do not repeatedly attempt forbidden operations while in combat.

---

# 6. Secure Frames

Be extremely careful when working with:

```text
SecureActionButtonTemplate
SecureHandlerStateTemplate
SecureHandlerClickTemplate
SecureUnitButtonTemplate
```

or any other secure template.

Never casually modify:

* protected attributes;
* protected frame hierarchy;
* secure state drivers;
* action attributes;

during combat.

Before changing secure-frame logic, understand the taint implications.

Avoid insecure hooks or modifications that can propagate taint into Blizzard UI.

---

# 7. Taint

Avoid introducing taint into Blizzard frames.

Do not overwrite Blizzard functions unless absolutely necessary.

Never do:

```lua
SomeBlizzardFunction = function()
    ...
end
```

when a hook can be used instead.

Prefer:

```lua
hooksecurefunc(...)
```

when appropriate.

Do not modify Blizzard-owned tables unless the API explicitly expects addons to do so.

Do not modify protected frames unnecessarily.

Do not globally monkey-patch WoW UI behavior.

---

# 8. Lua Version and Style

World of Warcraft uses its embedded Lua environment.

Do not assume support for arbitrary Lua versions or external Lua runtimes.

Do not introduce syntax unsupported by the WoW client.

Prefer simple, idiomatic Lua.

Use:

```lua
local
```

aggressively.

Avoid unnecessary globals.

Bad:

```lua
MyVariable = 42
```

Preferred:

```lua
local myVariable = 42
```

Addon globals should only be created intentionally.

---

# 9. Addon Namespace

Prefer the standard addon namespace pattern:

```lua
local addonName, ns = ...
```

Example:

```lua
local addonName, ns = ...

ns.Constants = ns.Constants or {}
ns.Utils = ns.Utils or {}
```

Avoid filling `_G` with addon internals.

Expose a global only when WoW requires it or when it is part of the addon's intentional public API.

---

# 10. Naming Conventions

Use descriptive names.

Preferred:

```lua
local playerGUID
local spellID
local itemID
local unitToken
local configFrame
```

Avoid:

```lua
local x
local tmp
local thing
local data2
```

unless the scope is extremely small and the meaning is obvious.

Use WoW terminology consistently:

```text
spellID
itemID
questID
achievementID
mapID
unitToken
GUID
frame
texture
aura
```

Do not rename established WoW concepts into custom terminology without a good reason.

---

# 11. Functions

Prefer small functions with a single responsibility.

Preferred:

```lua
local function UpdatePlayerHealth()
    ...
end
```

Avoid giant event handlers containing unrelated logic.

Instead of:

```lua
frame:SetScript("OnEvent", function(self, event, ...)
    -- hundreds of lines
end)
```

prefer:

```lua
local function HandlePlayerLogin()
    ...
end

local function HandleEnteringWorld()
    ...
end

local function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        HandlePlayerLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        HandleEnteringWorld()
    end
end

frame:SetScript("OnEvent", OnEvent)
```

---

# 12. Events

Prefer event-driven logic over polling.

Use WoW events whenever possible.

Preferred:

```lua
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    ...
end)
```

Avoid `OnUpdate` unless continuous updates are genuinely required.

---

# 13. OnUpdate

`OnUpdate` executes every rendered frame.

Treat it as expensive.

Do not use it when an event or timer can perform the same task.

Bad:

```lua
frame:SetScript("OnUpdate", function()
    UpdateEverything()
end)
```

Prefer events or timers.

If `OnUpdate` is required, throttle expensive work.

Example:

```lua
local elapsedSinceUpdate = 0
local UPDATE_INTERVAL = 0.1

frame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed

    if elapsedSinceUpdate < UPDATE_INTERVAL then
        return
    end

    elapsedSinceUpdate = 0

    UpdateSomething()
end)
```

---

# 14. Timers

Prefer WoW's timer API when delayed or periodic execution is appropriate.

Examples:

```lua
C_Timer.After(...)
C_Timer.NewTimer(...)
C_Timer.NewTicker(...)
```

Do not create unnecessary permanent tickers.

Cancel timers/tickers when they are no longer needed.

---

# 15. Performance

WoW addons execute on the game's main UI thread.

Performance matters.

Avoid unnecessary work in:

* combat events;
* aura updates;
* nameplate events;
* UNIT_* events;
* COMBAT_LOG_EVENT_UNFILTERED;
* BAG_UPDATE-related events;
* OnUpdate handlers.

Avoid unnecessary:

* table allocation;
* string concatenation;
* closures;
* table copies;
* sorting;
* full-table scans;

inside high-frequency paths.

---

# 16. Tables

Reuse tables when appropriate in performance-sensitive code.

Do not allocate temporary tables repeatedly inside hot paths unless necessary.

Example to avoid in a high-frequency event:

```lua
local data = {
    unit = unit,
    spellID = spellID,
    timestamp = GetTime(),
}
```

when the table is immediately discarded and the event occurs extremely frequently.

Do not optimize harmless code prematurely, however.

Prioritize readability unless profiling demonstrates that optimization is useful.

---

# 17. Table Iteration

Use the appropriate iterator.

For arrays:

```lua
for index, value in ipairs(values) do
    ...
end
```

For dictionaries:

```lua
for key, value in pairs(values) do
    ...
end
```

Do not depend on `pairs()` iteration order.

If order matters, define it explicitly.

---

# 18. Nil Safety

WoW APIs frequently return `nil` when information is not currently available.

Handle this explicitly.

Bad:

```lua
local name = SomeAPI(...)
print(name:upper())
```

Preferred:

```lua
local name = SomeAPI(...)

if not name then
    return
end

print(name:upper())
```

Do not introduce pointless nil checks when the API contract guarantees a value, but when uncertain prefer defensive behavior.

---

# 19. IDs vs Names

Prefer stable identifiers over localized names.

Prefer:

```lua
spellID
itemID
questID
```

over comparisons against:

```lua
spellName
itemName
questTitle
```

Avoid:

```lua
if spellName == "Fireball" then
```

when a stable spell ID can be used instead.

Names can be localized and can change.

---

# 20. Localization

Never assume the user is running the English client.

Avoid business logic based on localized strings.

Bad:

```lua
if className == "Warrior" then
```

Prefer stable identifiers or WoW constants.

UI strings visible to users should eventually support localization.

Recommended layout:

```text
Locales/
    enUS.lua
    frFR.lua
    deDE.lua
```

Example:

```lua
local L = ns.L

L["Settings"] = "Settings"
```

Do not duplicate localization strings throughout the codebase.

---

# 21. SavedVariables

SavedVariables must be treated as persistent user data.

Never destroy or reset user settings without a migration strategy.

Example TOC:

```toc
## SavedVariables: MyAddonDB
```

Initialize defensively:

```lua
MyAddonDB = MyAddonDB or {}
```

Prefer versioned configuration when the structure may evolve.

Example:

```lua
local CURRENT_DB_VERSION = 2

local function MigrateDatabase(db)
    local version = db.version or 1

    if version < 2 then
        -- migration
        version = 2
    end

    db.version = CURRENT_DB_VERSION
end
```

Never assume SavedVariables contain the latest schema.

Users may upgrade from old addon versions.

---

# 22. Default Configuration

Keep default values centralized.

Example:

```lua
ns.defaults = {
    enabled = true,
    scale = 1,
    locked = false,
}
```

Do not scatter default values across multiple files.

---

# 23. TOC File

Treat the `.toc` file as part of the application.

Preserve load order.

Example:

```toc
## Interface: XXXXX
## Title: MyAddon
## Notes: Description
## Author: Eric
## Version: 1.0.0
## SavedVariables: MyAddonDB

Core.lua
Config.lua
Utils.lua
UI.lua
Events.lua
```

Lua files are loaded sequentially.

Never reorder files without checking their dependencies.

---

# 24. File Organization

For a medium-sized addon, prefer a structure such as:

```text
MyAddon/
├── MyAddon.toc
├── Core.lua
├── Constants.lua
├── Config.lua
├── Events.lua
├── Utils.lua
├── UI/
│   ├── MainFrame.lua
│   ├── Options.lua
│   └── Widgets.lua
├── Modules/
│   ├── ModuleA.lua
│   └── ModuleB.lua
└── Locales/
    ├── enUS.lua
    └── frFR.lua
```

Do not create dozens of tiny files without benefit.

Do not put the entire addon into one giant Lua file when responsibilities can clearly be separated.

Follow the existing architecture before introducing a new one.

---

# 25. Core / Modules

Prefer explicit module boundaries.

Example:

```lua
local addonName, ns = ...

local Module = {}
ns.MyModule = Module

function Module:Initialize()
end

function Module:Enable()
end

function Module:Disable()
end
```

Do not introduce a complex dependency injection framework.

WoW addons should remain lightweight.

---

# 26. UI Frames

Create frames only when necessary.

Example:

```lua
local frame = CreateFrame("Frame", nil, UIParent)
```

Avoid unnecessary globally named frames.

Use a global frame name only when required by XML, secure templates, bindings, or another WoW mechanism.

Anchor frames explicitly.

Example:

```lua
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
```

---

# 27. XML

Lua is preferred for ordinary addon logic and dynamic UI.

Use XML when it provides a concrete advantage, such as:

* templates;
* inheritance;
* complex static frame definitions;
* compatibility with an existing XML-based architecture.

Do not introduce XML simply because WoW supports it.

Follow the existing project's style.

---

# 28. UI Reuse

Do not create a new frame every time an event occurs.

Reuse frames or use appropriate pools when many transient UI objects are required.

This is particularly important for:

* icons;
* nameplate elements;
* combat indicators;
* aura widgets;
* scrolling lists.

---

# 29. Hooks

Prefer secure hooking.

Example:

```lua
hooksecurefunc("SomeFunction", function(...)
    ...
end)
```

or method hooks where appropriate.

Do not replace Blizzard functions unless there is no safe alternative and the consequences are understood.

---

# 30. Blizzard Frames

Avoid depending on private Blizzard implementation details unless necessary.

If accessing Blizzard UI internals:

* document why;
* isolate the dependency;
* expect it to change between patches.

Prefer public APIs over internal implementation details.

---

# 31. Slash Commands

Slash commands should be simple and defensive.

Example:

```lua
SLASH_MYADDON1 = "/myaddon"

SlashCmdList.MYADDON = function(message)
    message = message and message:trim() or ""

    if message == "config" then
        ns.OpenConfig()
        return
    end

    ns.PrintHelp()
end
```

Keep parsing separate from business logic when commands become complex.

---

# 32. Error Handling

Do not silently swallow errors.

Avoid:

```lua
pcall(function()
    ...
end)
```

simply to hide bugs.

Use `pcall` only when failure is expected and can be handled correctly.

Development errors should remain visible.

---

# 33. Debug Logging

Create centralized debug behavior.

Example:

```lua
local DEBUG = false

function ns.Debug(...)
    if not DEBUG then
        return
    end

    print("|cff8888ffMyAddon:|r", ...)
end
```

Do not leave high-frequency debug messages enabled in production.

Do not spam chat during normal gameplay.

---

# 34. User Messages

Prefix addon messages consistently.

Example:

```lua
local PREFIX = "|cff00ccffMyAddon:|r"

local function Print(...)
    print(PREFIX, ...)
end
```

Use chat output for meaningful user-facing information only.

---

# 35. Addon Communication

When using addon communication channels:

* use an explicit prefix;
* register it correctly;
* validate received payloads;
* do not trust messages from other clients blindly;
* limit message frequency;
* avoid flooding addon channels.

Do not build unnecessary custom protocols if an existing mechanism already solves the problem.

---

# 36. External Libraries

Before adding a dependency such as:

```text
Ace3
LibStub
CallbackHandler
LibDataBroker
LibSharedMedia
```

inspect whether the project already uses it.

Do not add Ace3 or another framework for trivial functionality.

If the addon already uses Ace3 consistently, follow the existing architecture rather than replacing it with custom equivalents.

---

# 37. No External Lua Runtime Assumptions

Do not assume standard desktop Lua libraries are available.

Avoid dependencies on things such as:

```lua
io
os
package
require
```

unless they are explicitly available through the WoW addon environment.

WoW addons run inside Blizzard's sandboxed Lua environment.

---

# 38. Dependencies

Inspect the TOC for:

```toc
## Dependencies:
## OptionalDeps:
```

Preserve dependency semantics.

Do not make an optional dependency mandatory unless explicitly required.

If integrating with another addon, check whether it is loaded before accessing its API.

---

# 39. Addon Loading

For optional addons/modules, use the modern addon-loading API appropriate for the target client.

Do not assume another addon has already loaded.

Handle load-on-demand addons correctly.

Avoid attempting to access Blizzard modules before they are available.

---

# 40. Initialization

Initialization should happen at the appropriate lifecycle stage.

Understand the difference between events such as:

```text
ADDON_LOADED
PLAYER_LOGIN
PLAYER_ENTERING_WORLD
```

Do not put all initialization blindly in `PLAYER_ENTERING_WORLD`.

Use the earliest correct lifecycle event for the operation.

SavedVariables are typically initialized after the addon has been loaded.

---

# 41. Event Registration

Only register events a module actually needs.

Unregister events when they are no longer necessary.

Example:

```lua
frame:RegisterEvent("PLAYER_LOGIN")

local function OnEvent(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        Initialize()
    end
end
```

Do not leave one-time events permanently registered.

---

# 42. UNIT Events

When using UNIT_* events, filter units as early as possible.

Example:

```lua
local function HandleUnitHealth(unit)
    if unit ~= "player" then
        return
    end

    ...
end
```

Use unit-specific event registration facilities when supported and appropriate.

---

# 43. Combat Log

`COMBAT_LOG_EVENT_UNFILTERED` is a high-frequency event.

Do as little work as possible before filtering the event.

Preferred structure:

```lua
local function HandleCombatLog()
    local timestamp,
        subEvent,
        hideCaster,
        sourceGUID,
        sourceName,
        sourceFlags,
        sourceRaidFlags,
        destGUID,
        destName,
        destFlags,
        destRaidFlags = CombatLogGetCurrentEventInfo()

    if subEvent ~= "SPELL_CAST_SUCCESS" then
        return
    end

    -- Further filtering...
end
```

Filter early.

Avoid table allocations and expensive operations before determining whether the event matters.

---

# 44. Caches

Use caching only when it provides a real benefit.

Caches must have:

* a clear ownership;
* a clear invalidation strategy;
* bounded or predictable lifetime.

Do not create caches that grow forever.

---

# 45. Configuration UI

Configuration UI should modify persistent configuration, not duplicate state unnecessarily.

Prefer:

```text
SavedVariables
    ↓
configuration API
    ↓
UI refresh
```

rather than maintaining multiple competing copies of configuration.

---

# 46. Backward Compatibility

When changing public addon behavior:

* preserve SavedVariables;
* preserve slash commands where practical;
* preserve module APIs used elsewhere;
* provide migrations when required.

Do not break existing configuration simply to simplify implementation.

---

# 47. Refactoring

When refactoring:

1. Preserve behavior.
2. Preserve WoW API compatibility.
3. Preserve TOC load order.
4. Preserve SavedVariables.
5. Preserve user-facing commands.
6. Preserve integration APIs unless explicitly changing them.

Do not mix a large architecture rewrite with an unrelated bug fix.

Make focused changes.

---

# 48. Code Duplication

Extract reusable behavior when duplication is meaningful.

Do not create an abstraction merely because two functions contain two similar lines.

Favor straightforward Lua over excessive abstraction.

---

# 49. Comments

Comments should explain why, not restate the code.

Bad:

```lua
-- Set enabled to true
enabled = true
```

Useful:

```lua
-- This update cannot run during combat because the button is protected.
if InCombatLockdown() then
    return
end
```

Document non-obvious WoW restrictions.

---

# 50. TODOs

TODOs must be actionable.

Preferred:

```lua
-- TODO: Replace this fallback when the Retail API exposes the value directly.
```

Avoid:

```lua
-- TODO fix
```

---

# 51. Magic Numbers

Use constants for important IDs and values.

Example:

```lua
local SPELL_FIREBALL = 133
local UPDATE_INTERVAL = 0.1
```

Do not replace every obvious numeric value with a constant.

Prioritize meaningful domain constants.

---

# 52. WoW IDs

When adding a WoW object ID, indicate what it represents when useful.

Example:

```lua
local SPELL_ID_FIREBALL = 133
```

Avoid undocumented values:

```lua
if spellID == 133 then
```

when the ID is important to the domain logic.

---

# 53. Testing

World of Warcraft addons ultimately need testing inside the WoW client.

When making a change, identify relevant manual test scenarios.

Examples:

```text
/reload
/login
/logout
enter combat
leave combat
change zone
enter dungeon
enter raid
change specialization
change talent
change character
reload UI during combat
```

Only run external tests or linters if the repository provides them.

Possible tools include:

```text
luacheck
stylua
busted
```

Do not assume they are installed.

---

# 54. Lua Errors

Code should be tested with Lua errors visible.

Do not solve errors by suppressing the error display.

Pay attention to:

```text
attempt to index a nil value
attempt to call a nil value
ADDON_ACTION_BLOCKED
ADDON_ACTION_FORBIDDEN
```

`ADDON_ACTION_BLOCKED` and `ADDON_ACTION_FORBIDDEN` may indicate taint or protected-action issues rather than ordinary Lua bugs.

Investigate the actual source.

---

# 55. Profiling

Do not optimize based solely on intuition.

When performance matters, consider:

* call frequency;
* event frequency;
* allocations;
* CPU usage;
* UI updates.

High-frequency paths deserve significantly more scrutiny than startup code.

---

# 56. Change Scope

Before editing code:

1. Identify the requested behavior.
2. Locate the relevant module.
3. Understand its event lifecycle.
4. Check whether protected UI is involved.
5. Check SavedVariables impact.
6. Check client compatibility.
7. Make the smallest coherent change.

Do not modify unrelated files.

---

# 57. Existing Code Has Priority

Before creating:

```lua
ns.Utils
ns.Events
ns.Config
ns.Constants
ns.Modules
```

check whether an equivalent mechanism already exists.

Follow existing project conventions unless they are clearly problematic.

Do not introduce a second architecture into the same addon.

---

# 58. Do Not Guess

If code references an unknown:

* WoW API;
* Blizzard frame;
* mixin;
* template;
* event;
* library;
* addon API;

investigate it before modifying the surrounding code.

Never manufacture an implementation simply because its name looks plausible.

---

# 59. Before Completing a Change

Review the change for:

* Lua syntax errors;
* undefined globals;
* accidental global variables;
* incorrect API arguments;
* deprecated APIs;
* nil handling;
* event lifecycle;
* combat lockdown;
* protected frame interaction;
* taint risk;
* excessive OnUpdate work;
* SavedVariables compatibility;
* TOC load order;
* localization issues;
* Retail/Classic compatibility.

---

# 60. Final Response Expectations

When completing development work, explain:

1. What changed.
2. Which files changed.
3. Why the implementation was chosen.
4. Any WoW API assumptions.
5. Any combat-lockdown or taint considerations.
6. How to test the change in-game.

Keep the explanation concise when the change is simple.

---

# 61. Core Principle

For WoW addon development:

> Prefer simple, event-driven, API-correct Lua over clever abstractions.

When choosing between a sophisticated solution and a straightforward implementation that works correctly inside WoW's UI environment, prefer the straightforward implementation.

Correct behavior inside the WoW client is more important than theoretical architectural purity.
