-- Author: Fatalcaleb
-- ClickCast.lua
local ADDON, NS = ...

local function UnitForButton(btn)
  if not btn then return nil end
  local unit = btn:GetAttribute("unit") or btn.unit
  if unit then btn.unit = unit end
  return unit
end

local function SetSpellBinding(btn, prefix, button, spell)
  local typeKey = prefix .. "type" .. button
  local spellKey = prefix .. "spell" .. button

  if spell and spell ~= "" then
    btn:SetAttribute(typeKey, "spell")
    btn:SetAttribute(spellKey, spell)
  else
    btn:SetAttribute(typeKey, nil)
    btn:SetAttribute(spellKey, nil)
  end
end

local function ApplyBindingsToButton(btn)
  if InCombatLockdown() then return end
  if not btn or not UnitForButton(btn) or not NS.DB then return end

  local db = NS.DB.bindings or {}

  SetSpellBinding(btn, "", "1", db["BUTTON1"])
  SetSpellBinding(btn, "", "2", db["BUTTON2"])
  SetSpellBinding(btn, "", "3", db["BUTTON3"])
  SetSpellBinding(btn, "", "4", db["BUTTON4"])
  SetSpellBinding(btn, "", "5", db["BUTTON5"])

  SetSpellBinding(btn, "shift-", "1", db["SHIFT-BUTTON1"])
  SetSpellBinding(btn, "shift-", "2", db["SHIFT-BUTTON2"])
  SetSpellBinding(btn, "shift-", "3", db["SHIFT-BUTTON3"])

  SetSpellBinding(btn, "ctrl-", "1", db["CTRL-BUTTON1"])
  SetSpellBinding(btn, "ctrl-", "2", db["CTRL-BUTTON2"])

  SetSpellBinding(btn, "alt-", "1", db["ALT-BUTTON1"])
  SetSpellBinding(btn, "alt-", "2", db["ALT-BUTTON2"])

  SetSpellBinding(btn, "", "-wheelup", db["MOUSEWHEELUP"])
  SetSpellBinding(btn, "", "-wheeldown", db["MOUSEWHEELDOWN"])
  SetSpellBinding(btn, "shift-", "-wheelup", db["SHIFT-MOUSEWHEELUP"])
  SetSpellBinding(btn, "shift-", "-wheeldown", db["SHIFT-MOUSEWHEELDOWN"])
  SetSpellBinding(btn, "ctrl-", "-wheelup", db["CTRL-MOUSEWHEELUP"])
  SetSpellBinding(btn, "ctrl-", "-wheeldown", db["CTRL-MOUSEWHEELDOWN"])
  SetSpellBinding(btn, "alt-", "-wheelup", db["ALT-MOUSEWHEELUP"])
  SetSpellBinding(btn, "alt-", "-wheeldown", db["ALT-MOUSEWHEELDOWN"])
end

local function ApplyAll()
  if InCombatLockdown() then return false end
  local header = _G["MidnightHealerHeader"]
  if not header then return false end

  local children = { header:GetChildren() }
  for _, child in ipairs(children) do
    if child and child.GetAttribute and child:GetAttribute("unit") then
      ApplyBindingsToButton(child)
    end
  end
  return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function()
  if not NS.DB then return end
  if InCombatLockdown() then
    if NS.RequestSecureApply then NS.RequestSecureApply() end
    return
  end
  ApplyAll()
end)

function NS.ReapplyClickCast()
  if InCombatLockdown() then
    if NS.RequestSecureApply then NS.RequestSecureApply() end
    return false
  end
  return ApplyAll()
end
