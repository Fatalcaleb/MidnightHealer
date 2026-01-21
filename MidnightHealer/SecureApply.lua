-- Author: Fatalcaleb
-- SecureApply.lua
local ADDON, NS = ...

NS.PendingSecureApply = false

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function()
  if NS.PendingSecureApply and not InCombatLockdown() then
    NS.PendingSecureApply = false
    if NS.ReapplyClickCast then NS.ReapplyClickCast() end
    if NS.RebuildFrames then NS.RebuildFrames() end
  end
end)

function NS.RequestSecureApply()
  if InCombatLockdown() then
    NS.PendingSecureApply = true
    return false
  end
  return true
end
