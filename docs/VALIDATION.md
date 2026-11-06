# Validation — 2026-11-06

Automated checks pass in Lua 5.1: 48 routing assertions and 29 UI integration assertions using ESO's native hook helpers. Eight Lua files compile; 123 API/constant symbols were checked against the API 101051 documentation and owning UI sources. English/Russian string keys and placeholders match. The generated 128×128 RGBA DDS and addon manifest pass validation.

Observed in the live client:

- The first load exposed an unsupported method on the shared left background fragment. It was removed; the native zone-story lifecycle now manages the background. The installed copy was updated, and the next UI reload opened the map without that error.
- The enlarged map and hidden Area Completion panel are visible, with all eight sidebar tabs accessible.
- The Dungeons tab populates with dungeon/location rows.
- The Trials tab populates with trial/location rows, and Houses shows house/location pairs on one line.
- The in-progress antiquity context menu retains its native Abandon action and includes Teleport; no antiquity action was executed.
- Right-clicking Arx Corinium opens the native recall confirmation, showing 73 gold. The dialog was cancelled without performing that travel.
- Native node names contain localized "Dungeon:" prefixes. Instance labels and interior-zone matching now use the corresponding POI name instead, covered by a regression assertion.

Full acceptance remains pending. In particular, server-completed social jumps, actual instance/house arrivals, quest/dig-site nearest-shrine results, pulse appearance, settings changes across resolutions and other addons require the scenarios in ACCEPTANCE.md. Automated routing checks and an opened confirmation dialog do not establish these outcomes.

No ESOUI upload was performed.
