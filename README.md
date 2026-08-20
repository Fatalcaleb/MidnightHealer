# MidnightHealer

**Author:** Fatalcaleb  
**Version:** 0.13.0  
**Expansion:** Midnight 12.1  

MidnightHealer is a custom healing-frame addon for World of Warcraft focused on clear raid/party presentation and secure click-casting.

> **12.1 status:** Version 0.13.0 is the compatibility rebuild. Blizzard's Midnight addon restrictions prevent addons from freely analyzing secret health/aura data in restricted combat. Health-based recommendations, legacy aura scanning, and cluster analysis are therefore disabled while those displays are rebuilt using supported 12.1 APIs.

---

## Working in 0.13.0

### Core
- Custom raid & party frames
- Secure click-casting (VuhDo-style)
- 8-groups-across or 2-column layouts
- Movable/lockable frames
- Profile and per-spec configuration
- Test mode

### Presentation
- Class-based coloring
- Role-based coloring
- Fully custom colors
- Range fading
- Dead/offline state text
- Threat highlight when threat state is not secret

### Temporarily disabled for 12.1 compatibility
- Legacy `UnitAura` HoT scanning
- Manual debuff-priority scoring
- Swiftmend-ready recommendation pip
- Health-percentage threshold glows/text
- Incoming-heal percentage analysis
- Injured-player cluster/AoE-heal recommendations

These features are not simply deprecated API calls: several relied on combat values Blizzard now protects as Secret Values. Aura presentation will be rebuilt around the 12.1 AuraContainer/AuraButton system instead of bypassing those protections.

---

## Installation

1. Download the addon.
2. Extract it into:
   ```
   World of Warcraft/_retail_/Interface/AddOns/MidnightHealer
   ```
3. Ensure the folder structure is:
   ```
   AddOns
   └── MidnightHealer
       ├── MidnightHealer.toc
       ├── Core.lua
       ├── Compat.lua
       ├── Frames.lua
       └── ...
   ```
4. Restart WoW or use `/reload` after replacing addon files.

---

## Usage

- `/mh` — Open settings
- `/mh lock` — Lock frames
- `/mh unlock` — Unlock frames
- `/mh test` — Toggle test mode
- `/mh profile <name>` — Switch profiles

Settings are found at:

```
Esc → Options → AddOns → MidnightHealer
```

Layout presets and profile import/export remain available from the MidnightHealer settings panels.

---

## 12.1 compatibility approach

MidnightHealer 0.13 keeps the parts Blizzard still supports—custom unit-frame presentation and player-chosen secure click casting—while avoiding arithmetic, comparisons, or recommendation logic based on protected combat values.

The next compatibility step is restoring customizable HoT/debuff presentation with Blizzard's 12.1 AuraContainer/AuraButton API.

---

## License

All rights reserved.  
You may modify for personal use. Redistribution requires permission.

---

## Links

- GitHub: https://github.com/Fatalcaleb/MidnightHealer
- Wago.io: https://wago.io/MidnightHealer
- CurseForge: https://www.curseforge.com/wow/addons/midnighthealer
