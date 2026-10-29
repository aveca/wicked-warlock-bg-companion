-- WickedWarlock mock WoW API harness
-- Requires Lua 5.1. Run from this folder:
--   lua5.1 tests/mock_wow_harness.lua
-- This mocks the UI/API surface; it is not a WoW client emulator.

local realPrint = print
local failures, passes = 0, 0
local function check(name, condition)
  if condition then
    passes = passes + 1
    realPrint("PASS " .. name)
  else
    failures = failures + 1
    realPrint("FAIL " .. name)
  end
end

local mockFrames, sentChat = {}, {}
UIParent = {}
WickedWarlockDB = {}
function time() return 12345 end
function GetTime() return 100 end
function GetRealZoneText() return "Warsong Gulch" end
function UnitFactionGroup() return "Alliance" end
function IsInInstance() return true, "pvp" end
function SendChatMessage(text, channel) sentChat[#sentChat + 1] = {text=text, channel=channel} end
function DoEmote(emote) _G.lastEmote = emote end
function GetNumBattlefieldScores() return 4 end
function GetBattlefieldScore(i)
  local rows = {
    {"FriendlyWarrior", 3, 8, 2, 10, 1, "Human", "Warrior", 12000, 300},
    {"FriendlyPriest", 0, 4, 1, 5, 1, "Human", "Priest", 1000, 9000},
    {"EnemyWarlock", 5, 9, 1, 12, 0, "Orc", "Warlock", 18000, 500},
    {"EnemyPriest", 1, 3, 2, 4, 0, "Undead", "Priest", 1500, 14000},
  }
  return unpack(rows[i])
end

function CreateFrame(kind, name, parent, template)
  local obj = {scripts={}, attributes={}, shown=true, points={}}
  function obj:SetSize(w,h) self.width,self.height=w,h end
  function obj:SetPoint(...) self.points={...} end
  function obj:ClearAllPoints() self.points={} end
  function obj:SetMovable(v) self.movable=v end
  function obj:SetClampedToScreen(v) self.clamped=v end
  function obj:EnableMouse(v) self.mouse=v end
  function obj:RegisterForDrag(...) end
  function obj:RegisterEvent(event) self.events=self.events or {}; self.events[event]=true end
  function obj:SetScript(k,v) self.scripts[k]=v end
  function obj:SetBackdrop(v) self.backdrop=v end
  function obj:SetBackdropColor(...) end
  function obj:CreateFontString()
    local fs = {}
    function fs:SetPoint(...) end
    function fs:SetText(t) self.text=t end
    function fs:SetWidth(w) end
    function fs:SetJustifyH(v) end
    return fs
  end
  function obj:StartMoving() end
  function obj:StopMovingOrSizing() end
  function obj:GetPoint() return "CENTER", UIParent, "CENTER", 0, 100 end
  function obj:SetAttribute(k,v) self.attributes[k]=v end
  function obj:GetAttribute(k) return self.attributes[k] end
  function obj:SetText(t) self.text=t end
  function obj:Hide() self.shown=false end
  function obj:Show() self.shown=true end
  function obj:IsShown() return self.shown end
  mockFrames[#mockFrames + 1] = obj
  return obj
end

GameFontNormalLarge, GameFontHighlightSmall, GameFontNormalSmall = {}, {}, {}
UIPanelButtonTemplate, SecureActionButtonTemplate, UIPanelCloseButton = {}, {}, {}
SlashCmdList = {}

-- Suppress only the addon's startup prints.
print = function(...) end
local chunk, compileErr = loadfile("WickedWarlock.lua")
print = realPrint
check("addon file compiles", chunk ~= nil)
if not chunk then
  realPrint(compileErr)
  os.exit(1)
end

print = function(...) end
local ok, runtimeErr = pcall(chunk, "WickedWarlock")
print = realPrint
check("addon initializes with mocked WoW APIs", ok)
if not ok then
  realPrint(runtimeErr)
  os.exit(1)
end
check("slash command registered", type(SlashCmdList.WICKEDWARLOCK) == "function")

local before = #sentChat
local scanOk, scanErr = pcall(SlashCmdList.WICKEDWARLOCK, "scan")
check("scoreboard scan does not throw", scanOk)
check("scan emits one battleground message",
  #sentChat == before + 1 and sentChat[#sentChat].channel == "BATTLEGROUND")
if not scanOk then realPrint(scanErr) end

local secureCount = 0
for _, frame in ipairs(mockFrames) do
  if frame.attributes.type == "macro" and frame.attributes.macrotext then secureCount = secureCount + 1 end
end
check("secure macro buttons are configured", secureCount >= 5)

realPrint("Mock harness summary: " .. passes .. " passed, " .. failures .. " failed")
if failures > 0 then os.exit(1) end
