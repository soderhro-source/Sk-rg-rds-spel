# HANDOVER — Skärgårdsspaning (sailing trip game)

**Purpose of this doc:** full context for continuing development in a new chat. Read this + skim `index.html` before making changes.

## What this is

Multiplayer deck game (PWA-style web app, Swedish UI) for Roope's sailing trip in the Turku archipelago, **departing Monday 2026-07-13**. Crew: Roope, Tiina, Pernilla (join by car at Hangö), Patrik & Martin (depart by boat from Storören). **Martin is captain.** Boat: s/y Sun-Day, Degerö 33 (LOA 9,81 m, beam 3,52 m, draft 1,5 m, mast 15 m, 5 200 kg, sloop).

Route (15 board tiles, editable by captain): STORÖREN → Barösund (Mon night, boat crew only) → Hangö (crew meetup "Mönstring") → Airisto → Själö → Brännskär → Korpoström → Aspö → Nötö → Björkö → Helsingholm → Högsåra → Örö → Dalsbruk → 🏁 KASNÄS (spa finale).

## Files (all in this folder)

| File | Role |
|---|---|
| `index.html` | The entire app (~2300 lines: CSS + HTML + one `<script>`) |
| `config.js` | Supabase URL + anon key (filled, working) |
| `schema.sql` | Original schema (superseded by migrations, kept for reference) |
| `gemma_bridge.py` | Runs on Roope's home PC: polls chat, answers @gemma via local Ollama |
| `boat.jpg` | Watercolor hero image (login screen) |
| `SETUP.md` | User-facing setup guide |
| `sounds/` (optional) | Not created yet — see Bird sounds below |

## Infrastructure (all live, all free tier)

- **Hosting:** Netlify site `sunday-spaning` → https://sunday-spaning.netlify.app (site id `ef94bbc0-ba0c-4443-b146-d582def9d81a`, team `soderhro`). **Deploy = drag the folder onto the Deploys tab** at app.netlify.com/projects/sunday-spaning. The Netlify MCP's npx upload does NOT work from the Cowork sandbox (network blocked).
- **Backend:** Supabase project `wptovqfypslbneobnjim` (eu-west-2, "Söderholm's Org"), managed via the Supabase MCP connector. Tables: `sailors` (name+PIN hash+emoji), `logs` (all points: kind ∈ spot/quiz/checkpoint/knot/surprise/minigame/bonus, unique indexes prevent duplicates; surprise unique per crew per day), `chat`, `port_notes` (harbor logbook incl. `photo_url`), `settings` (key/value jsonb: `captain`="Martin", `route`=array of 14 names), `track_points` (GPS log: lat/lng/sog/ts). Storage bucket `photos` (public, anon upload). RLS: open for anon (friends-level security). Realtime enabled on logs, chat, settings.
- **Auth:** name + 4-digit PIN, SHA-256 client-side. No email.
- **Offline-first:** localStorage write-queue for logs, auto-flush every 15 s + on `online`. Chat/photos/map need signal.

## Game design (current state)

- Candy Crush-style saga board, 15 nodes serpentine. **Everyone starts at Storören**; tile = `floor(points/30)` capped at 14; **MÅL at 420 p**. Passed harbors = green + ⭐, current = pulsing gold ring, fog-of-war ("— ? —") beyond next harbor. Crew ship ⛵ moves on sum of all points (leg = 30 × crew size).
- Points sources: species spotting (~90 cards, 6 categories in one 🔭 Spana tab with chips, each card has 📷 facit Google-Images link), harbor challenges (+5; unlock by points OR **GPS within 1.5 km**; Storören "Avfärdskontroll" open from start), knots (6), navigationsskolan (6 lessons, kind='knot', ref='nav:i'), quiz (bookable 1×/day), daily pop-quiz overlay (+2, ship+seamark theory, 16 Qs), daily surprise (first-to-claim crew-wide), arcade: Lastrummet/Tetris ≤5 p/day, Skärgårdsminne/memory ≤4, Bojkrossen/match-3 ≤5, Ålen/snake ≤4.
- Ranks: Jungman 0 → Lättmatros 30 → Matros 60 → Båtsman 130 → Styrman 220 → Skeppare 320 → Kommodor 420.
- **Captain (Martin):** `settings.captain` name match (case/space-insensitive) → sees "Ändra ruttordning" on board; reorder syncs live to all (KASNÄS locked as goal). Challenges keyed by harbor NAME (`cp:<name>`) so they follow reordering.
- UI: game HUD (avatar+rank chip → profile; gold ⭐ points coin; blue ⛵ crew coin), XP bar to next harbor, wind bar (Open-Meteo, cached offline, tap to refresh), bottom nav (5 + Mer sheet), splash screen, wave-sweep view transitions, confetti/floating-points/pulse juice.
- Views in Mer: Skeppschatt (realtime; @gemma → gemma_bridge.py), Galleri (logbook photos), Törnrapport (per-day sailing stats from track_points + per-member activity + crew totals), Navigationsskolan, Byssan (8 recipes), Frågesport, Läten (audio players w/ external fallback), Sjötermer (diagrams + boat specs), Live AIS (Fintraffic, often CORS-blocked → fallback text), Seglandet 2026 (harbor guide + Leaflet map).
- Map (Seglandet): Leaflet + OSM, markers for 14 PLACES + Storören; overlays: Väylävirasto WMS fairways (default ON — **layer names `vaylat,vaylaalueet` unverified**, check they render!) + OpenSeaMap seamarks. Buttons: ⛶ fullscreen, 📍 follow (live position+speed), ⏺ track recording (batches to `track_points` every 45 s), 🛤️ today's track replay. Offline fallback = schematic SVG.
- Harbor guide: 14 route harbors (fee+services+shared star-rating logbook with photo upload, client-side resize to 1280 px JPEG) + 9 alternatives + 17 more behind "+ Fler gästhamnar". Prices: Kasnäs from 34 €, Helsingholm 20 €, Högsåra 25+5 €, Ekenäs 25 €, Näsby 20 € all-incl <34 ft, Norrby 27 € (sourced); rest marked "ca".

## ⚠️ Open items / known issues

1. **UNVERIFIED FULL-FILE SYNTAX.** The Cowork sandbox's file mirror of `index.html` was frozen during the last work session, so the final ~10 edits (tracker, report, GPS unlock, facit buttons, map layers, Barösund) were verified only by isolated unit tests (all green) and inspection — NOT by a full `node --check` on the assembled file. **First action in a new session: extract the `<script>` block and run `node --check`, then fix any error.** Roope must also smoke-test locally (double-click index.html) before deploying.
2. **Live site is stale.** sunday-spaning.netlify.app still runs v1.0 (first deploy). Everything since (v2 skin, chat, captain, tracker…) ships with the next folder drag.
3. **Bird sounds not bundled.** Cards look for `sounds/<scientific-name>.mp3` (e.g. `haliaeetus-albicilla.mp3`), fall back to Xeno-canto links. Xeno-canto blocks bots (Anubis) — files must be downloaded manually by Roope.
4. **Väylävirasto WMS layer names unverified** (see Map above).
5. **Jarvis vault sync pending.** Two `vault_remember` calls timed out (Gemma server offline 11.7). Full history is in Claude's auto-memory (`robert-sailing-game` memory) and mirrored here.
6. Pop-quiz answered wrong still writes a 0-point log (marks the day used) — intended, but crew may ask.
7. `logs.kind='bonus'` is allowed by schema but unused/not duplicate-protected.

## Conventions for future edits

- Single-file app; all JS in ONE `<script>` at the end of `index.html`. Function declarations (hoisted) — order rarely matters; top-level `const/let` data lives at the top of the script.
- All UI text in Swedish, playful nautical tone. Points refs: `spot:<cat>:<idx>`, `cp:<harborName>`, `knot:<i>`/`nav:<i>`, `quiz:<date>`/`pop:<date>`, `sur:<date>`, `<game>:<date>`.
- Supabase MCP is connected in Roope's Cowork — use `apply_migration` for DDL, `execute_sql` with `set local role anon` to test RLS (supabase.co is NOT reachable from the sandbox shell).
- Sandbox mirror of index.html can lag minutes behind edits: verify new logic in a fresh scratch `.js` file (they sync instantly), run with node, delete after.
- Roope's preference: save agreed decisions/learnings to the Jarvis vault (`vault_remember`), problems to Knowledge Base.

## Wishlist / not built

- Bundle bird mp3s (manual download) · PWA manifest + service worker for true offline install · export Törnrapport as PDF/share text · date picker for track replay · sound effects · deleting/moderating chat & logbook posts (currently insert-only from app).
