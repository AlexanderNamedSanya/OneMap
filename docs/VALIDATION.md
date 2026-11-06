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

Quest-list regression: 100 automated assertions pass. The keyboard quest view now builds a separate list of all valid journal entries, retaining the native sorting and row rendering without changing the shared map-filtered singleton. Regression checks cover zone navigation, absent breadcrumb coordinates, quest addition/removal, and isolation of native shared data. Live verification after UI reload remains pending.

Smooth-scroll revision: the existing 100 routing/UI assertions and 33 dedicated scroll assertions pass under Lua 5.1 (133 total). Scroll coverage includes native zoom delegation, a 400ms boundary pause requiring continued input, interpolated fades, cursor-target changes, reverse direction, stale gestures, non-zoomable interiors, modifiers, map restrictions, disable/cancellation, and external navigation. Native UI API 101051 is the owning reference. Live animation and hierarchy acceptance after reload remains pending.

City navigation / shorter pause revision: 140 assertions pass (100 routing/UI + 40 scroll). The boundary pause is 200ms. Native city/subzone overlays lacking a map-list index are resolved to an exact map ID; tests verify city entry, parent navigation, early-wheel rejection, changed targets, and invalid/current-map overlays. Live city-map acceptance remains pending reload.

Zoom-delay / combined-tab revision: 149 assertions pass (101 routing/UI, 48 scroll). Regression checks hold rendered zoom away from its endpoint while requested zoom is at the limit and verify the same 200ms boundary pause in both directions. The combined list includes both instance types and excludes arenas; a separate Trials tab is no longer registered. Live timing acceptance after reload remains pending.

Top-level scroll boundary revision: 159 assertions pass (101 routing/UI + 58 scroll). World/cosmic maps reject outward level transitions before arming the boundary or starting a fade. Ordinary zoom inside the world map and inward navigation remain available; top-level state is rechecked before an already-pending transition. Live verification after reload remains pending.

All-travel confirmation revision: 168 automated assertions pass (110 routing/UI, 58 scroll). Opt-in bypass covers recall, free wayshrine travel and house destinations, including the native map platform dialogs. Regression checks preserve house interior/exterior targets, restore confirmations when disabled, and leave unrelated dialogs untouched. Existing setting values are retained. Live acceptance remains pending reload.

Player-wave visibility revision: thicker original DDS ring, higher-opacity blue waves and increased diameter (20–96 UI units). Native map pins remain above the waves. Existing 168 assertions, Lua 5.1 syntax, localization and DDS checks pass. Live visual review remains pending reload.

Shift interaction revision: 204 assertions pass (110 routing/UI, 63 scroll, 31 mouse input). Shift-click places a rally marker on release only within 200ms and 5 UI units of movement; movement away and back, wheel gestures, long holds and releases outside cannot mark. Native dragging and parent/child navigation remain available with Shift. The native mouse-up call restores the key reader even on failure; Ctrl/Alt and restricted maps retain native behavior. Live running/dragging acceptance remains pending reload.
