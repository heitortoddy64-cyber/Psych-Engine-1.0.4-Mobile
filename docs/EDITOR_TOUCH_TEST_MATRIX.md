# Editor touch audit and test matrix — V2

**Status definitions:** SOURCE = binding/callback reviewed in source; AUTOMATED = executed Haxe/Python checks; CI = actual native release status in this PR's checks; DEVICE UNTESTED = no Android device/emulator interaction performed. SOURCE and compilation are not evidence of touch usability, provider persistence or gameplay correctness.

Shared implementation: `backend/ui/EditorInput`, `EditorKeyState`, `EditorPointer`; `mobile/controls/EditorTouchControls`; existing `PsychUI*` widgets; `FileDialogHandler` and `mobile/backend/java/FileUtils.java`. These helpers activate only in editors on mobile; desktop pointer input keeps its original path. Large editor pads previously covered UI, used letter-only labels, and left keyboard/mouse-only commands inaccessible. Essential bindings now use named contextual pages plus the original UI.

| Editor | Existing binding/capability | Touch implementation reviewed (SOURCE) | Execution status |
| --- | --- | --- | --- |
| Master menu | Up/Down select; Left/Right mod directory; Accept/Back | Eight direct buttons; MOD arrows; Back; navigation commands. No debug key required. | Android and desktop Haxe type checking; DEVICE UNTESTED |
| Chart | Left tap add/delete; Shift/Alt tap select; Control drag move; right drag rectangle | EDIT, SELECT, MOVE, DRAG modes; same real captured pointer. Notes/events/property widgets retained. | SOURCE; DEVICE UNTESTED |
| Chart | W/S seek; A/D sections; Home/End; Space; R; Enter/F12 playtest/preview | PLAY page, reset/preview actions; existing mobile playtest hitboxes; Back exits playtest. | SOURCE; DEVICE UNTESTED, including note/audio sync |
| Chart | Q/E sustain; Left/Right quantize; Z/X zoom; brackets playback rate; Alt+bracket reset; 1–8 Vortex | TIMING, TOOLS and eight-lane VORTEX pages. Existing View menu enables Vortex. | SOURCE; DEVICE UNTESTED |
| Chart | Ctrl+A/C/X/V/Z/Y/S; Delete/Backspace; File/Edit/View menus; F1 | NOTES actions and existing pointer menus. Core chart/event JSON picker operations; SAF save/reopen. Desktop-only folder batch converters documented. | SOURCE; device selection/undo/save/restart UNTESTED |
| Character | J/K/L/I camera; Q/E/R zoom; W/S animation; Space replay; A/D frames; F12 ghosts; F1 | CAMERA, ANIMATION and VIEW pages; tabs and animation list use shared pointer/zoomable UI. | SOURCE; DEVICE UNTESTED |
| Character | Arrow offsets; right drag; Shift/Control speed; Ctrl+C/V/R/Z | OFFSETS, OFFSET TOOLS, DRAG mode and modifiers; Settings Open JSON and original Save Character. | SOURCE; offset accuracy and persisted JSON DEVICE UNTESTED |
| Stage | W/S sprite select; arrows nudge; right drag; Shift/Control precision; J/K/L/I; Q/E/R | STAGE, OFFSETS, CAMERA pages; sprite/layer/property panels stay intact. Existing add/duplicate/delete/layer controls use stationary release. | SOURCE; DEVICE UNTESTED, including drag-vs-delete |
| Stage | F1/F2/F3/F12 UI/help/selection; animation substate W/S/Space, arrows, Ctrl+R | Contextual actions and existing animation popup. Blocking prompts yield toolbar input; active animation editing retains named commands. | SOURCE; modal workflows DEVICE UNTESTED |
| Stage | Stage selector/template/save; desktop FileReference image browse | Open JSON and SAF Save; binary PNG/atlas import to selected mod, sanitized leaf names, overwrite prompt. | SOURCE; real providers, image/atlas previews and restart DEVICE UNTESTED |
| Week | Song list/name/metadata/characters; Load/Save; character chooser Up/Down/Back | Existing editable widgets via captured touch + UI zoom/pan; original character chooser mobile pad; corrected Back; existing SAF callbacks. New template uses Tutorial. | SOURCE; SOURCE assets validated; DEVICE UNTESTED |
| Menu Character | Arrows position; Shift fast; Space confirm animation; image/animation fields; Load/Save | POSITION page and original widgets/pickers; choose Confirm preview in the existing radio selector. | SOURCE; DEVICE UNTESTED |
| Dialogue | A/D line; W/S animation; Space replay; O/P add/remove; text/character fields; Load/Save | DIALOGUE page; soft keyboard; original widgets and JSON picker callbacks. Desktop line direction semantics retained (D previous, A next). | SOURCE; IME/edit/restart DEVICE UNTESTED |
| Dialogue Portrait | J/K/L/I pan; Q/E/R zoom; H ghosts/bubble; Space; W/S animation; WASD loop vs arrows idle offsets | CAMERA, ANIMATION, LOOP OFFSET and OFFSETS pages; independent idle/loop commands on mobile; original properties and JSON Load/Save. | SOURCE; DEVICE UNTESTED |
| Note Splash | Arrows offsets; Shift fast; Ctrl+C/V/R; Space preview; F1; strum taps; anim/RGB fields | OFFSETS/TOOLS pages, original animation/RGB widgets and tappable strums; Save, new Open JSON, existing Convert TXT. | SOURCE; shader preview, offsets and saved/reopened config DEVICE UNTESTED |

## Executed automated checks

- `tests/lite_v2.py`: actual Haxe command-state transitions for press/hold/repeat/release, duplicate hold, modifier combos, clearing on cancellation and re-entry; 17 assertions. Exact asset bytes/paths, protected Tutorial hashes, six relocations, only Tutorial built-in week, all supplied charts/events and both audio formats. Actual build macro positive and two negative tests.
- `tests/optimization_v1.py`: 87 assertions across each of mobile/desktop × debug/release (348 total), using the existing regression harness.
- `tests/discord_platforms.py`: actual Lime guard parsing for Android/iOS/html5 vs desktop; disabled Discord Haxe module type checking.
- Full project Android release Haxe `--no-output`: uses actual configured dependencies, including editor source, Lua, HScript and shaders. Native APK status is reported separately by CI.
- `actionlint` validates both Android workflow definitions; `git diff --check` checks whitespace.

## Required device acceptance (all UNTESTED)

On a real Android phone, download the release artifact from the PR's successful Android run. Use touch only. Open Main Menu → EDITORS, choose each of the eight editors and a mod directory, edit a value, save a JSON through a document provider, exit/restart and reopen that saved JSON. For each editor execute every SOURCE row above. Verify Tutorial Easy/Normal/Hard in Story/Freeplay, startup/return paths, and an independent mod using Lua/HScript, shader, custom event/note and animated sprite.

Repeat with a second finger on the canvas while a toolbar button is held; slide off destructive controls; expand/collapse/dock the bar; pan/zoom panels; scroll long dropdowns; dismiss IME using Enter/Done/Back; cancel SAF, revoke provider access, background/restore the app, open/close help and confirmation prompts. Confirm no duplicate action, retained direction/modifier or accidental editor exit. Check narrow/wide landscape screens, Android navigation insets and readability/target sizes. The logical layout uses the engine's 1280×720 viewport; notch/system-bar handling and physical target sizes need device confirmation.

No screenshots or clips are supplied because none were captured from an Android run. No RAM, FPS, battery or sync performance claim is made.
