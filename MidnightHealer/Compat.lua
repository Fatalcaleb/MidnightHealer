-- Author: Fatalcaleb
-- Compat.lua
-- Compatibility helpers for APIs removed before WoW Midnight 12.1.
local ADDON, NS = ...

local PLAYER_BANK = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0

-- These wrappers intentionally exist only when Blizzard's legacy globals are
-- absent. They let the existing options/preset code continue to work while the
-- addon is migrated to C_SpellBook/C_Spell directly.
if not GetNumSpellTabs and C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
  function GetNumSpellTabs()
    return C_SpellBook.GetNumSpellBookSkillLines()
  end
end

if not GetSpellTabInfo and C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo then
  function GetSpellTabInfo(tabIndex)
    local info = C_SpellBook.GetSpellBookSkillLineInfo(tabIndex)
    if not info then return nil end
    return info.name, info.iconID, info.itemIndexOffset or 0, info.numSpellBookItems or 0,
      info.isGuild or false, info.offSpecID or 0
  end
end

if not GetSpellBookItemInfo and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
  function GetSpellBookItemInfo(slotIndex)
    local info = C_SpellBook.GetSpellBookItemInfo(slotIndex, PLAYER_BANK)
    if not info then return nil end

    local itemType = info.itemType
    local legacyType
    if Enum and Enum.SpellBookItemType then
      if itemType == Enum.SpellBookItemType.Spell then
        legacyType = "SPELL"
      elseif itemType == Enum.SpellBookItemType.FutureSpell then
        legacyType = "FUTURESPELL"
      elseif itemType == Enum.SpellBookItemType.Flyout then
        legacyType = "FLYOUT"
      elseif itemType == Enum.SpellBookItemType.PetAction then
        legacyType = "PETACTION"
      end
    end

    return legacyType, info.spellID or info.actionID
  end
end

if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
  function GetSpellInfo(spellIdentifier)
    local info = C_Spell.GetSpellInfo(spellIdentifier)
    if not info then return nil end
    return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange,
      info.spellID, info.originalIconID
  end
end

-- Some old code still passes BOOKTYPE_SPELL into compatibility wrappers.
if BOOKTYPE_SPELL == nil then BOOKTYPE_SPELL = "spell" end
if BOOKTYPE_PET == nil then BOOKTYPE_PET = "pet" end
