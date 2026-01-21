-- Author: Fatalcaleb
-- ClickCast.lua
local ADDON, NS = ...

local function ApplyBindingsToButton(btn)
  if InCombatLockdown() then return end
  if not btn or not btn.unit then return end

  local db = NS.DB.bindings

  -- Buttons 1-5
  btn:SetAttribute("type1", "spell")
  btn:SetAttribute("type2", "spell")
  btn:SetAttribute("type3", "spell")
  btn:SetAttribute("type4", "spell")
  btn:SetAttribute("type5", "spell")

  btn:SetAttribute("spell1", db["BUTTON1"])
  btn:SetAttribute("spell2", db["BUTTON2"])
  btn:SetAttribute("spell3", db["BUTTON3"])
  btn:SetAttribute("spell4", db["BUTTON4"])
  btn:SetAttribute("spell5", db["BUTTON5"])

  -- SHIFT
  btn:SetAttribute("shift-type1", "spell")
  btn:SetAttribute("shift-type2", "spell")
  btn:SetAttribute("shift-type3", "spell")
  btn:SetAttribute("shift-spell1", db["SHIFT-BUTTON1"])
  btn:SetAttribute("shift-spell2", db["SHIFT-BUTTON2"])
  btn:SetAttribute("shift-spell3", db["SHIFT-BUTTON3"])

  -- CTRL
  btn:SetAttribute("ctrl-type1", "spell")
  btn:SetAttribute("ctrl-type2", "spell")
  btn:SetAttribute("ctrl-spell1", db["CTRL-BUTTON1"])
  btn:SetAttribute("ctrl-spell2", db["CTRL-BUTTON2"])

  -- ALT
  btn:SetAttribute("alt-type1", "spell")
  btn:SetAttribute("alt-type2", "spell")
  btn:SetAttribute("alt-spell1", db["ALT-BUTTON1"])
  btn:SetAttribute("alt-spell2", db["ALT-BUTTON2"])

  -- Mousewheel (VuhDo-style)
  btn:SetAttribute("type-wheelup", "spell")
  btn:SetAttribute("type-wheeldown", "spell")
  btn:SetAttribute("spell-wheelup", db["MOUSEWHEELUP"])
  btn:SetAttribute("spell-wheeldown", db["MOUSEWHEELDOWN"])

  btn:SetAttribute("shift-type-wheelup", "spell")
  btn:SetAttribute("shift-type-wheeldown", "spell")
  btn:SetAttribute("shift-spell-wheelup", db["SHIFT-MOUSEWHEELUP"])
  btn:SetAttribute("shift-spell-wheeldown", db["SHIFT-MOUSEWHEELDOWN"])

  btn:SetAttribute("ctrl-type-wheelup", "spell")
  btn:SetAttribute("ctrl-type-wheeldown", "spell")
  btn:SetAttribute("ctrl-spell-wheelup", db["CTRL-MOUSEWHEELUP"])
  btn:SetAttribute("ctrl-spell-wheeldown", db["CTRL-MOUSEWHEELDOWN"])

  btn:SetAttribute("alt-type-wheelup", "spell")
  btn:SetAttribute("alt-type-wheeldown", "spell")
  btn:SetAttribute("alt-spell-wheelup", db["ALT-MOUSEWHEELUP"])
  btn:SetAttribute("alt-spell-wheeldown", db["ALT-MOUSEWHEELDOWN"])
end

local function ApplyAll()
  if InCombatLockdown() then return end
  local header = _G["MidnightHealerHeader"]
  if not header then return end

  local i = 1
  while true do
    local child = select(i, header:GetChildren())
    if not child then break end
    if child.unit then
      ApplyBindingsToButton(child)
    end
    i = i + 1
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function()
  if not NS.DB then return end
  if InCombatLockdown() then return end
  ApplyAll()
end)

function NS.ReapplyClickCast()
  if InCombatLockdown() then return end
  ApplyAll()
end
