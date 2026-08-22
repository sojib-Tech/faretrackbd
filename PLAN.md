# FareTrackBD — Multi-Route Journey Planner: Implementation Plan

## Critical Bug Analysis

The root cause of the 93-bus bug in `CorridorBusService.findBuses()` (`lib/services/corridor_bus_service.dart:62-136`) is:

1. **No walking radius threshold** — Lines 87-107 find the *closest* stop on each bus route to origin/destination, but never check if that stop is actually within walking distance. A bus whose nearest stop is 5km away still matches.
2. **Directional constraint** — Line 110: `if (bestOriginIdx >= bestDestIdx) continue;` — Since routes are bidirectional, this incorrectly rejects valid matches where the destination appears earlier in the array.

Additionally, `JourneyEngine` (used by Screen 2) only indexes `BusRouteData.allRoutes` (84 hardcoded routes), missing the 182 JSON routes entirely.

## Implementation Phases

### Phase 1: Fix the Matching Engine (CORRECTNESS TEST FIRST)

**1a. Create `lib/services/journey_planner_engine.dart`** — New pure-Dart service

- Loads `dhaka_bus_routes.json` via `DhakaBusRouteData.load()`
- Resolves each stop name to lat/lng via `DhakaBusRouteData.findStop()` (fuzzy/substring matching)
- Implements `isDirectCandidate(BusRoute bus, LatLng origin, LatLng destination)` exactly per the prompt's algorithm:
  - For EACH bus independently: find stop within `WALK_RADIUS_M` (800m) of origin AND a different stop within `WALK_RADIUS_M` of destination
  - Routes are bidirectional — no order constraint
- `WALK_RADIUS_M = 800.0` (configurable constant)
- Returns `List<CorridorBusMatch>` with: bus info, matched origin stop, matched destination stop, distance along route, computed fare
- Also finds 1-transfer candidates (cap at top 15)
- Computes per-candidate metrics: walking distance, bus distance, time, fare
- Scoring: configurable weights (40% time, 30% fare, 30% walk), normalized 0-100

**1b. Write `test/journey_planner_engine_test.dart`** — Correctness test

- Load `dhaka_bus_routes.json` in test
- Use real stop coordinates from `StopCoordinates`
- Query: origin=Mugda (23.7200, 90.4350), destination=Jamuna Future Park (23.7920, 90.4200)
- Assert exactly these 7 buses match (by `name_en`):
  - Anabil Super, Desh Bangla Bus, Green Anabil, J M Super Paribahan, Raida, Salsabil, Turag
- Assert NO other buses match
- Run: `flutter test test/journey_planner_engine_test.dart`

**This test MUST pass before any UI work.**

**1c. Fix `lib/services/corridor_bus_service.dart`** to use new engine

- Replace the broken matching logic with calls to `JourneyPlannerEngine.findDirectCandidates()`
- Remove directional constraint
- Add walking radius check

**1d. Update `JourneyEngine` to use JSON routes**

- In `_buildIndex()`, also index `DhakaBusRouteData` routes (or replace `BusRouteData` entirely for journey planning)
- Remove directional constraint in `_findDirectRoutes()` (line 328: `origInfo.index < destInfo.index` → allow both directions)

### Phase 2: Screen 1 UI — Journey Setup

The existing `JourneyPlannerScreen` already implements most of Screen 1. Enhancements:

- **Field labels**: Change hints to "যাত্রা শুরু" and "গন্তব্য" as specified
- **GPS status**: Already shows "GPS সক্রিয়" — verify it shows resolved area name
- **Nearby stops section**: Already shows "কাছের বাস স্টপ (Nটি)" with distance and walk time — verify it shows 8-10 stops with direction tags
- **Primary button**: Already shows "যাত্রা পরিকল্পনা করুন" with bus icon — verify disabled state works
- **Swap icon**: Already implemented

Files to modify: `lib/features/journey/journey_planner_screen.dart`

### Phase 3: Screen 2 UI — Journey Options

The existing `JourneyResultsScreen` already implements most of Screen 2. Enhancements:

- **Four tabs**: Already has সেরা/দ্রুত/সস্তা/কম হাঁটা — verify re-sorting works without re-running search
- **Card content**: Already shows সেরা badge, route-type tag, score, metrics row
- **Route summary badge**: Show "origin stop → destination stop"
- **Navigation**: Tapping card navigates to Screen 3

Files to modify: `lib/features/journey/journey_results_screen.dart`

### Phase 4: Screen 3 UI — Bus Suggestions

The existing `CorridorBusesScreen` already shows bus suggestions. Enhancements:

- **Screen title**: Change from "করিডর বাস" to "যাত্রা বিবরণ"
- **Bus name format**: Show both Bangla and English (e.g. "তুরাগ পরিবহন (Turag Paribahan)")
- **Metrics**: Show distance (km), fare (৳), stops between
- **Sort order**: By fare ascending (already done)
- **No silent drops**: Ensure ALL 7 matching buses appear for the test query

Files to modify: `lib/features/journey/corridor_buses_screen.dart`

### Phase 5: Wire & Polish

- Update `JourneyPlannerNotifier` to pass data correctly between screens
- Ensure caching of computed results for instant tab switching
- Verify Bangla numeral formatting throughout
- Run `flutter analyze` and fix any issues

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/services/journey_planner_engine.dart` | **CREATE** — Core matching + scoring engine |
| `test/journey_planner_engine_test.dart` | **CREATE** — Correctness test |
| `lib/services/corridor_bus_service.dart` | **MODIFY** — Use new engine |
| `lib/services/journey_engine.dart` | **MODIFY** — Use JSON routes, fix direction constraint |
| `lib/features/journey/journey_planner_screen.dart` | **MODIFY** — Screen 1 polish |
| `lib/features/journey/journey_results_screen.dart` | **MODIFY** — Screen 2 polish |
| `lib/features/journey/corridor_buses_screen.dart` | **MODIFY** — Screen 3 polish |
| `lib/providers/journey_planner_provider.dart` | **MODIFY** — Wire to new engine |
| `lib/core/constants/app_constants.dart` | **MODIFY** — Add WALK_RADIUS_M constant |

## Verification

1. `flutter test test/journey_planner_engine_test.dart` — 7 buses for Mugda→JFP
2. `flutter analyze` — no errors
3. Manual UI check: Screen 1 → Screen 2 → Screen 3 flow works
4. Bangla text matches spec exactly
