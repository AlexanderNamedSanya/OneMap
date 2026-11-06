# Validation — 2026-11-06

Automated checks pass in Lua 5.1: 52 routing assertions and 29 UI integration assertions using ESO's native hook helpers. Eight Lua files compile; 123 API/constant symbols were checked against the API 101051 documentation and owning UI sources. English/Russian string keys and placeholders match. The generated 128×128 RGBA DDS and addon manifest pass validation.

Observed in the live client:

- The first load exposed an unsupported method on the shared left background fragment. It was removed; the native zone-story lifecycle now manages the background. The installed copy was updated, and the next UI reload opened the map without that error.
- The enlarged map and hidden Area Completion panel are visible, with all eight sidebar tabs accessible.
- The Dungeons tab populates with dungeon/location rows.
- The Trials tab populates with trial/location rows, and Houses shows house/location pairs on one line.
- The in-progress antiquity context menu retains its native Abandon action and includes Teleport; no antiquity action was executed.
- Right-clicking Arx Corinium opens the native recall confirmation, showing 73 gold. The dialog was cancelled without performing that travel.
- After another UI reload, the revised Trials panel opens without a duplicate heading or a Lua error. Native POI labels can retain localized "Dungeon:"/"Trial:" prefixes too; interior-zone matching now handles exact activity/zone names and complete names after a colon, with regression checks that reject unrelated partial names.

Full acceptance remains pending. In particular, server-completed social jumps, actual instance/house arrivals, quest/dig-site nearest-shrine results, pulse appearance, settings changes across resolutions and other addons require the scenarios in ACCEPTANCE.md. Automated routing checks and an opened confirmation dialog do not establish these outcomes.

No ESOUI upload was performed.

## Map regression corrections

84 automated routing/UI assertions pass after replacing whole-control scaling with a 5% native viewport resize, removing map-pin and map-background travel hooks, eliminating map changes during price hovers, and restoring native Antiquities left-click behavior. Tests cover unchanged viewport dimensions during zoom, repeated layout, native pin handling and the original control scale. Live acceptance of these latest corrections is pending UI reload.

Latest settings/sidebar revision: 85 automated assertions pass. Native sidebar button scale is preserved; enlargement is 10%; the three remaining map settings are verified, and older disabled travel/trial values are migrated to enabled. Live verification after reload remains pending.

Compact tooltip / paid-confirmation revision: 95 automated assertions pass, covering content-sized tooltip dimensions, default confirmation, immediate paid recall when opted in, insufficient currency and cooldown rejection, and retained native free-shrine dialogs. Live appearance and completed server travel remain pending UI reload and in-game verification.
