# MidnightHealer

**Author:** Fatalcaleb  
**Version:** 0.12.2  
**Expansion:** Midnight  

MidnightHealer is a modern, triage-focused healing addon designed for raid and party healing in World of Warcraft.
It emphasizes clarity, speed, and flexibility while avoiding unnecessary bloat.

---

## Features

### Core
- Custom raid & party frames
- Secure click-casting (VuhDo-style)
- Large triage bars for fast decision-making
- 8-groups-across or 2-column layouts

### Customization
- Per-profile configuration (shared across characters)
- Per-spec support
- Lock/unlock movable frames
- Test mode (raid or party)

### Coloring System
- Class-based coloring
- Role-based coloring (Tank / Healer / DPS)
- Debuff-type border coloring (Magic, Curse, Disease, Poison)
- Fully custom colors (bar / name / border)
- Optional class color overrides

### Healing Tools
- HoT tracking
- Debuff display
- Aggro highlighting
- Cluster detection
- Health text: percent, numeric, or both

---

## Installation

1. Download the addon.
2. Extract into:
   ```
   World of Warcraft/_retail_/Interface/AddOns/MidnightHealer
   ```
3. Ensure the folder structure is:
   ```
   AddOns
   └── MidnightHealer
       ├── MidnightHealer.toc
       ├── Core.lua
       ├── Frames.lua
       └── ...
   ```
4. Restart WoW or `/reload`.

---

## Usage

### Layout Presets
- Apply Classic / VuhDo / Minimal from: Settings → MidnightHealer – Tools → Layout Presets

### Profile Sharing
- Export/Import a profile string from: Settings → MidnightHealer – Tools → Profile Sharing


- `/mh` — Open settings
- `/mh lock` — Lock frames
- `/mh unlock` — Unlock frames
- `/mh test` — Toggle test mode
- `/mh profile <name>` — Switch profiles

Settings are found in:
```
Esc → Options → AddOns → MidnightHealer
```

---

## Philosophy

MidnightHealer is built to feel:
- **Familiar** to veteran healers
- **Fast** in real raid conditions
- **Predictable** under pressure

No hand-holding. No clutter. Just information that matters.

---

## License

All rights reserved.  
You may modify for personal use. Redistribution requires permission.

---

## Links

- GitHub: https://github.com/Fatalcaleb/MidnightHealer
- Wago.io: https://wago.io/MidnightHealer
- CurseForge: https://www.curseforge.com/wow/addons/midnighthealer
