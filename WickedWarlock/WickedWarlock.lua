-- Wicked Warlock BG Companion v2.0.1
-- TBC Anniversary-oriented. Lua 5.1 compatible.
-- Scoreboard is polled locally for UI suggestions; chat lines require a click.
-- Spell buttons are secure user-click actions. The addon does not bypass protected-action rules.

local ADDON = ...
WickedWarlockDB = WickedWarlockDB or {}
local DB = WickedWarlockDB

if DB.locked == nil then DB.locked = false end
if DB.hidden == nil then DB.hidden = false end
if DB.autoScan == nil then DB.autoScan = true end
if DB.chatChannel == nil then DB.chatChannel = "BATTLEGROUND" end
if DB.errorLog == nil then DB.errorLog = {} end
if DB.errorCount == nil then DB.errorCount = 0 end

local function randomLine(list)
  if not list or #list == 0 then return nil end
  return list[math.random(1, #list)]
end

local LINES = {
  intro = {
    "Free magic rocks! Click now! Side effects may include demonic possession.",
    "Welcome, heroes! Please click my suspiciously glowing rock. No refunds!",
    "Click the rock for health stones. Management denies all responsibility for demons.",
    "Step right up! Free rocks, questionable magic, premium-grade evil customer service."
  },
  start = {
    "Plan A: victory. Plan B: blame the lag.",
    "Focus the healer! If you can't find the healer, become the problem.",
    "Stay together, hit hard, and remember: running in alone is a bold fashion choice.",
    "Let's make questionable decisions at an unusually professional level.",
    "Teamwork makes the dream work. Fel magic makes the paperwork disappear."
  },
  healers = {
    "Their healer is carrying harder than a dungeon taxi. Apply pressure!",
    "Enemy healing is looking suspiciously generous. Interrupt the wellness program!",
    "Focus heals, team. Otherwise this fight is getting a second season."
  },
  tanks = {
    "Welcome to the annual shield convention. Bring snacks.",
    "Their frontline is built like a bank vault. Find the squishy bits!",
    "Lots of armor, little urgency. We may be here until next reset."
  },
  damage = {
    "Their damage leader has been promoted to today's suspicious person.",
    "Big damage on the enemy side. Let's make their meters less exciting.",
    "So many glass cannons. Let's see who breaks first."
  },
  ahead = {
    "We're winning! Act natural. Nobody panic!",
    "Score advantage acquired. Please maintain your regularly scheduled chaos.",
    "We're ahead! The strategy is clearly working. Do not ask follow-up questions."
  },
  behind = {
    "This is not a defeat. It's an advanced comeback strategy.",
    "We're behind, not doomed. Activate the dramatic third act!",
    "The scoreboard is being rude. Let's correct its attitude."
  },
  healerLead = {
    "Our healer is carrying the health bars. Protect the legend!",
    "Someone give our healer a medal and a vacation after this BG.",
    "Friendly healer MVP detected. Please stop standing in the fire."
  },
  damageLead = {
    "Our damage MVP is putting in overtime. Keep that pressure rolling!",
    "Our damage leader is doing the heavy lifting. The rest of us are emotional support.",
    "Damage machine spotted. Feed them targets, not excuses."
  },
  warlocks = {
    "Too many Warlocks. This battleground needs an exorcist.",
    "The enemy also chose the dark arts. Imitation is a form of flattery."
  },
  paladins = {
    "Light help us. They've brought the entire church.",
    "So much holy light. Someone bring a blackout curtain."
  },
  rogues = {
    "Check your pockets. The local thieves have arrived.",
    "If your health suddenly vanishes, check for a tiny person with daggers."
  },
  unknown = {
    "Enemy composition unclear. Our plan remains aggressively optimistic.",
    "I have studied the enemy. Conclusion: hit them until they stop moving.",
    "Mystery opponents! How exciting. I definitely meant to do that."
  }
}

local function safeChatChannel()
  if DB.chatChannel == "SAY" then return "SAY" end
  if IsInInstance then
    local inside, instanceType = IsInInstance()
    if inside and instanceType == "pvp" then return "BATTLEGROUND" end
  end
  return "SAY"
end

local function announce(text, forceSay)
  if not text then return end
  local channel = forceSay and "SAY" or safeChatChannel()
  if channel == "BATTLEGROUND" then
    local inside, instanceType = IsInInstance()
    if not inside or instanceType ~= "pvp" then channel = "SAY" end
  end
  if SendChatMessage then SendChatMessage(text, channel) end
end

local function doEmote(emote)
  if DoEmote then DoEmote(emote) end
end

local function getMapName()
  if GetRealZoneText then
    local name = GetRealZoneText()
    if name and name ~= "" then return name end
  end
  return "Battleground"
end

local function getFactionIds()
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  if faction == "Horde" then return 1 end -- legacy scoreboard: Alliance=1, Horde=0
  if faction == "Alliance" then return 0 end
  return nil
end

local function readScoreboard()
  if not GetNumBattlefieldScores or not GetBattlefieldScore then
    return nil, "Scoreboard API unavailable on this client."
  end
  local enemyFaction = getFactionIds()
  local rows = {
    friendly = {}, enemy = {},
    totals = {friendlyDamage=0, friendlyHealing=0, enemyDamage=0, enemyHealing=0,
      friendlyKills=0, enemyKills=0, friendlyDeaths=0, enemyDeaths=0}
  }
  local count = GetNumBattlefieldScores() or 0
  for i = 1, count do
    -- Legacy Classic/TBC scoreboard tuple:
    -- name, killingBlows, honorableKills, deaths, honorGained,
    -- faction, race, className, damageDone, healingDone
    local name, killingBlows, honorableKills, deaths, honorGained, faction,
      race, className, damageDone, healingDone = GetBattlefieldScore(i)
    if faction ~= nil then
      local row = {
        name = name or "Unknown",
        class = (className and string.upper(className)) or "UNKNOWN",
        killingBlows = tonumber(killingBlows) or 0,
        honorableKills = tonumber(honorableKills) or 0,
        deaths = tonumber(deaths) or 0,
        damage = tonumber(damageDone) or 0,
        healing = tonumber(healingDone) or 0
      }
      local isEnemy = enemyFaction ~= nil and faction == enemyFaction
      local side = isEnemy and "enemy" or "friendly"
      table.insert(rows[side], row)
      local prefix = isEnemy and "enemy" or "friendly"
      rows.totals[prefix .. "Damage"] = rows.totals[prefix .. "Damage"] + row.damage
      rows.totals[prefix .. "Healing"] = rows.totals[prefix .. "Healing"] + row.healing
      rows.totals[prefix .. "Kills"] = rows.totals[prefix .. "Kills"] + row.killingBlows
      rows.totals[prefix .. "Deaths"] = rows.totals[prefix .. "Deaths"] + row.deaths
    end
  end
  if #rows.friendly == 0 and #rows.enemy == 0 then
    return nil, "No scoreboard rows yet. Open the scoreboard (Tab), wait, then scan."
  end
  rows.enemyFactionKnown = enemyFaction ~= nil
  return rows
end

local function topBy(rows, field)
  local best
  for _, row in ipairs(rows or {}) do
    if not best or (row[field] or 0) > (best[field] or 0) then best = row end
  end
  return best
end

local function countClasses(rows)
  local counts = {}
  for _, row in ipairs(rows or {}) do counts[row.class] = (counts[row.class] or 0) + 1 end
  return counts
end

local function fmt(n)
  n = tonumber(n) or 0
  if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
  if n >= 1000 then return string.format("%.1fk", n / 1000) end
  return tostring(math.floor(n))
end

local function chooseTacticalLine(rows)
  if not rows then return randomLine(LINES.unknown) end
  local enemyClasses = countClasses(rows.enemy)
  local enemyHeal = topBy(rows.enemy, "healing")
  local friendlyHeal = topBy(rows.friendly, "healing")
  local friendlyDmg = topBy(rows.friendly, "damage")
  local enemyDmg = topBy(rows.enemy, "damage")
  local t = rows.totals

  if (enemyClasses.WARLOCK or 0) >= 3 then return randomLine(LINES.warlocks) end
  if (enemyClasses.PALADIN or 0) >= 3 then return randomLine(LINES.paladins) end
  if (enemyClasses.ROGUE or 0) >= 3 then return randomLine(LINES.rogues) end
  if enemyHeal and enemyHeal.healing > 0 and enemyHeal.healing > (enemyDmg and enemyDmg.damage or 0) * 0.20 then
    return randomLine(LINES.healers)
  end
  if t.friendlyDamage > t.enemyDamage * 1.15 and t.friendlyDamage > 0 then
    return randomLine(LINES.ahead)
  end
  if t.enemyDamage > t.friendlyDamage * 1.15 and t.enemyDamage > 0 then
    return randomLine(LINES.behind)
  end
  if friendlyHeal and friendlyHeal.healing > 0 and (not enemyHeal or friendlyHeal.healing >= enemyHeal.healing) then
    return randomLine(LINES.healerLead)
  end
  if friendlyDmg and friendlyDmg.damage > 0 then return randomLine(LINES.damageLead) end
  return randomLine(LINES.start)
end

-- Capture d'erreurs addon-scopée (ne remplace PAS le gestionnaire d'erreurs global).
-- Les erreurs sont enregistrées dans WickedWarlockDB.errorLog (SavedVariables) et
-- conservées après un rechargement / une sortie normale du jeu.
local MAX_ERROR_LOG = 50

local function addError(err, context)
  DB.errorCount = (DB.errorCount or 0) + 1
  local entry = {
    time = (date and date("%H:%M:%S")) or "?",
    version = "2.0.1",
    source = "WickedWarlock",
    context = tostring(context or "unknown"),
    message = tostring(err or "unknown error"),
    count = 1
  }
  for _, e in ipairs(DB.errorLog) do
    if e.context == entry.context and e.message == entry.message then
      e.count = (e.count or 1) + 1
      e.time = entry.time
      return
    end
  end
  table.insert(DB.errorLog, 1, entry)
  while #DB.errorLog > MAX_ERROR_LOG do table.remove(DB.errorLog) end
end

local function safeCall(fn, context)
  local ctx = tostring(context or "unknown")
  local msg = nil
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then
      msg = tostring(err)
      addError(msg, ctx)
      local e = DB.errorLog[1]
      if e and e.count == 1 and e.message == msg and e.context == ctx then
        print("|cffff6038Wicked Warlock erreur|r: " .. msg .. " (" .. ctx .. ")")
      end
    end
  end
end

-- Main panel
local frame = CreateFrame("Frame", "WickedWarlockFrame", UIParent)
frame:SetSize(340, 395)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
  if not DB.locked then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local point, _, relativePoint, x, y = self:GetPoint(1)
  DB.point, DB.relativePoint, DB.x, DB.y = point, relativePoint, x, y
end)
if frame.SetBackdrop then
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = {left=3, right=3, top=3, bottom=3}
  })
  frame:SetBackdropColor(0.055, 0.025, 0.085, 0.96)
end
if DB.point then
  frame:ClearAllPoints()
  frame:SetPoint(DB.point, UIParent, DB.relativePoint or DB.point, DB.x or 0, DB.y or 0)
end

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 12, -10)
title:SetText("|cffff6038WICKED WARLOCK|r")

local mapText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mapText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
mapText:SetText("BG: waiting for battleground")

local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statusText:SetPoint("TOPLEFT", mapText, "BOTTOMLEFT", 0, -4)
statusText:SetText("Scores: waiting for first scan")

local suggestionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
suggestionText:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -6)
suggestionText:SetWidth(304)
suggestionText:SetJustifyH("LEFT")
suggestionText:SetText("Tip: open Tab scoreboard, then scan. Chat only sends when you click.")

local function makeButton(label, x, y, width, height, fn, secure)
  local template = secure and "SecureActionButtonTemplate, UIPanelButtonTemplate" or "UIPanelButtonTemplate"
  local b = CreateFrame("Button", nil, frame, template)
  b:SetSize(width or 148, height or 25)
  b:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  b:SetText(label)
  if fn then b:SetScript("OnClick", fn) end
  return b
end

local function updateStatus(rows, err)
  mapText:SetText("BG: " .. getMapName())
  if not rows then
    statusText:SetText("Scores: " .. (err or "not available"))
    suggestionText:SetText("Open the scoreboard with Tab, wait for it to fill, then scan.")
    return
  end
  local t = rows.totals
  statusText:SetText("DMG " .. fmt(t.friendlyDamage) .. " vs " .. fmt(t.enemyDamage) ..
    "  |  HEAL " .. fmt(t.friendlyHealing) .. " vs " .. fmt(t.enemyHealing))
  suggestionText:SetText("Suggestion: " .. (chooseTacticalLine(rows) or "Stay focused!"))
end

local lastRows
local function scanScores(quiet)
  local rows, err = readScoreboard()
  if rows then
    lastRows = rows
    updateStatus(rows)
    if not quiet then
      local t = rows.totals
      print("|cffff6038Wicked Warlock|r " .. getMapName() ..
        " | DMG ours/enemy " .. fmt(t.friendlyDamage) .. "/" .. fmt(t.enemyDamage) ..
        " | HEAL " .. fmt(t.friendlyHealing) .. "/" .. fmt(t.enemyHealing) ..
        " | Kills " .. t.friendlyKills .. "/" .. t.enemyKills ..
        " | Deaths " .. t.friendlyDeaths .. "/" .. t.enemyDeaths)
      local ed, eh = topBy(rows.enemy, "damage"), topBy(rows.enemy, "healing")
      local fd, fh = topBy(rows.friendly, "damage"), topBy(rows.friendly, "healing")
      if ed then print("Enemy damage leader: " .. ed.name .. " (" .. fmt(ed.damage) .. ")") end
      if eh then print("Enemy healing leader: " .. eh.name .. " (" .. fmt(eh.healing) .. ")") end
      if fd then print("Friendly damage leader: " .. fd.name .. " (" .. fmt(fd.damage) .. ")") end
      if fh then print("Friendly healing leader: " .. fh.name .. " (" .. fmt(fh.healing) .. ")") end
    end
  else
    updateStatus(nil, err)
    if not quiet then print("|cffff6038Wicked Warlock:|r " .. (err or "Score scan unavailable.")) end
  end
  return rows
end

-- Header controls
local hideButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
hideButton:SetPoint("TOPRIGHT", -1, -1)
hideButton:SetScript("OnClick", safeCall(function() frame:Hide(); DB.hidden = true end, "hideButton"))

makeButton("😈 INTRO", 10, -103, 148, 25, function()
  doEmote("grin")
  announce(randomLine(LINES.intro))
end)
makeButton("⚔ BG PEP TALK", 170, -103, 148, 25, function()
  doEmote("roar")
  announce(randomLine(LINES.start))
end)
makeButton("📊 SCAN SCORES", 10, -133, 148, 25, function() scanScores(false) end)
makeButton("🎯 SAY TACTICAL TIP", 170, -133, 148, 25, function()
  local rows = scanScores(true) or lastRows
  announce(chooseTacticalLine(rows))
end)

-- Secure macro buttons: every physical click executes the macro.
-- Castsequence buttons progress one successful spell at a time, as requested.
-- Secure attributes are configured during addon load, not rewritten during combat.
local armorButton = makeButton("🛡 ARMOR", 10, -163, 148, 25, nil, true)
armorButton:SetAttribute("type", "macro")
armorButton:SetAttribute("macrotext", "/cast Fel Armor")

local healthstoneButton = makeButton("💚 STONE STEP", 170, -163, 148, 25, nil, true)
healthstoneButton:SetAttribute("type", "macro")
healthstoneButton:SetAttribute("macrotext", "/castsequence reset=target/10 Create Healthstone, Create Soulstone")

local soulstoneButton = makeButton("💀 SOULSTONE", 10, -193, 148, 25, nil, true)
soulstoneButton:SetAttribute("type", "macro")
soulstoneButton:SetAttribute("macrotext", "/cast Create Soulstone")

local soulwellButton = makeButton("🪨 HEALTHSTONE", 170, -193, 148, 25, nil, true)
soulwellButton:SetAttribute("type", "macro")
soulwellButton:SetAttribute("macrotext", "/cast Create Healthstone")

local prepSequenceButton = makeButton("⚡ PREP: ARMOR → STONE", 10, -283, 308, 25, nil, true)
prepSequenceButton:SetAttribute("type", "macro")
prepSequenceButton:SetAttribute("macrotext", "/castsequence reset=target/10 Fel Armor, Create Healthstone, Create Soulstone")

local resetSequenceButton = makeButton("↻ RESET SEQUENCE (out of combat)", 10, -313, 308, 25, function()
  print("|cffff6038Wicked Warlock:|r castsequence resets naturally on target change or after 10 seconds. If stuck, use the individual spell buttons.")
end)

makeButton("😂 RANDOM TAUNT", 10, -223, 148, 25, function()
  local rows = scanScores(true) or lastRows
  announce(chooseTacticalLine(rows))
end)
makeButton("🔒 LOCK / UNLOCK", 170, -223, 148, 25, function()
  DB.locked = not DB.locked
  print("|cffff6038Wicked Warlock:|r panel " .. (DB.locked and "locked" or "unlocked") .. ".")
end)
makeButton("SHOW / HIDE", 10, -253, 148, 25, function()
  if frame:IsShown() then frame:Hide(); DB.hidden = true else frame:Show(); DB.hidden = false end
end)
makeButton("CHAT: BG / SAY", 170, -253, 148, 25, function()
  DB.chatChannel = DB.chatChannel == "BATTLEGROUND" and "SAY" or "BATTLEGROUND"
  print("|cffff6038Wicked Warlock:|r chat mode set to " .. DB.chatChannel .. ".")
end)

-- Event-driven refresh plus a low-frequency local UI poll while in a BG.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
eventFrame:SetScript("OnEvent", safeCall(function(_, event)
  if event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BATTLEFIELD_STATUS" then
    mapText:SetText("BG: " .. getMapName())
  end
  if DB.autoScan and event == "UPDATE_BATTLEFIELD_SCORE" then scanScores(true) end
end, "OnEvent"))

local elapsed = 0
frame:SetScript("OnUpdate", safeCall(function(_, delta)
  elapsed = elapsed + delta
  if elapsed >= 15 then
    elapsed = 0
    local inside, instanceType = IsInInstance()
    if DB.autoScan and inside and instanceType == "pvp" then scanScores(true) end
  end
end, "OnUpdate"))

SLASH_WICKEDWARLOCK1 = "/ww"
SLASH_WICKEDWARLOCK2 = "/wicked"
SlashCmdList["WICKEDWARLOCK"] = safeCall(function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  if msg == "show" then frame:Show(); DB.hidden = false
  elseif msg == "hide" then frame:Hide(); DB.hidden = true
  elseif msg == "intro" then doEmote("grin"); announce(randomLine(LINES.intro))
  elseif msg == "start" then doEmote("roar"); announce(randomLine(LINES.start))
  elseif msg == "scan" or msg == "stats" then scanScores(false)
  elseif msg == "tip" then announce(chooseTacticalLine(scanScores(true) or lastRows))
  elseif msg == "errors" then
    local n = #DB.errorLog
    print("|cffff6038Wicked Warlock erreurs|r: " .. n .. " enregistrée(s).")
    for i = 1, math.min(n, 10) do
      local e = DB.errorLog[i]
      print("  [" .. e.time .. "] " .. e.context .. ": " .. e.message .. " (x" .. (e.count or 1) .. ")")
    end
  elseif msg == "lock" then DB.locked = true; print("Wicked Warlock: panel locked.")
  elseif msg == "unlock" then DB.locked = false; print("Wicked Warlock: panel unlocked.")
  elseif msg == "autoon" then DB.autoScan = true; print("Wicked Warlock: automatic local scoreboard refresh ON.")
  elseif msg == "autooff" then DB.autoScan = false; print("Wicked Warlock: automatic local scoreboard refresh OFF.")
  else
    print("|cffff6038Wicked Warlock commands|r: /ww show, hide, intro, start, scan, stats, tip, errors, lock, unlock, autoon, autooff")
  end
end, "SlashCmd /ww")

if DB.hidden then frame:Hide() else frame:Show() end
math.randomseed((time and time() or 1) + math.floor((GetTime and GetTime() or 0) * 1000))
print("|cffff6038Wicked Warlock v2.0.1 loaded.|r Type /ww to control the panel. Type /ww errors to view captured Lua errors.")
