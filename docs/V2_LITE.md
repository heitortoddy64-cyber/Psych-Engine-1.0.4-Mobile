# Psych Engine 1.0.4 Mobile — V2 Lite

Branch: `optimization-v2-lite`. Based on V1 plus the Android Discord fix from PR #2 (`8947d619c2f803506af6401b3f0c40f6dcd3558b`). The PR targets `main`; merging is a separate user action.

## Included content

The built-in Story Mode and Freeplay reference is Tutorial. Its Easy, Normal, Hard, events, week metadata, menu graphic, instrumentals and both vocal tracks are unchanged. Test remains an internal chart-editor reference and has no playable week entry.

Week 1–7 and Weekend 1 song audio, charts, week metadata and dedicated media are removed. The exact 665 deleted paths and original byte sizes are in [V2_ASSET_MANIFEST.json](V2_ASSET_MANIFEST.json). Six original week1 images move to `shared/images` without changing their bytes: four support Tutorial/editor backgrounds and two support the generic spotlight event. BF, GF, death sprites, dialogue resources, editor UI, notes, generic icons, the default Dad editor character and example mods remain.

Source assets, measured across all files under `assets/`:

| Measurement | Bytes | Files |
| --- | ---: | ---: |
| Before | 565,566,450 | 1,089 |
| Deleted media | 469,658,055 | 665 |
| After (including small metadata/list edits) | 95,908,087 | 424 |

This is a source/package reduction. It does not establish a RAM or FPS improvement. The actual V1 Android release APK from run [43635199059](https://github.com/heitortoddy64-cyber/Psych-Engine-1.0.4-Mobile/actions/runs/43635199059) is **487,009,422 bytes** (`PsychMobile1.0.4-release.apk`); its download ZIP is 374,453,841 bytes. Compare the new APK with the APK size, not with that ZIP. The V2 PR records its measured build result and artifact size.

## Editing with a phone

Tap **EDITORS** in Main Menu, then one of the eight named editor buttons. `MOD <` / `MOD >` chooses the mod directory used by the existing editors. The generated EDITORS text button needs no new atlas. Five central items fit above Achievements/Options and the version labels.

Every editor has a compact bottom touch bar. Tap `TOUCH …` to expand/collapse it; `PAGE <` / `PAGE >` changes the contextual actions. `VIEW → Dock` moves it to the top when it covers a control. Modes:

- `EDIT`: regular left-pointer editing; Chart retains its existing tap-to-add/delete behavior.
- `SELECT`: Chart Shift+tap selection. Use this before selecting existing notes to avoid toggling them.
- `MOVE`: Chart Control+drag selection movement.
- `DRAG`: right-pointer drag, used by Chart selection rectangles and Character/Stage offsets/movement.
- `VIEW → UI pan`: drag the panels rather than the editing canvas; `UI zoom` enlarges the existing widgets from 1× through 4×. `Reset UI` restores their original position/size. World camera controls remain on their own contextual page.

`FAST` and `PRECISE` supply the existing Shift/Control modifiers. Movement buttons support hold/repeat; destructive commands and normal UI buttons activate after a stationary release. One canvas finger is captured until release; toolbar fingers are handled separately. Menus use the captured touch's real camera coordinates. No fake system keyboard events are generated. Hardware mouse input remains available when no touch is present; touch contacts suppress emulated mouse clicks.

Text fields use Android's existing soft keyboard path. Enter/Done or Back dismisses focus; Back in the touch bar closes focus first. Dropdowns scroll by dragging and do not open the keyboard. The contextual bar yields to text entry, prompts and SAF pickers. Existing gameplay hitboxes and substate mobile controls remain available; the large legacy editor pads are replaced by labeled commands. Input and listeners clear on focus loss and editor destruction. A state-owned Flixel input plugin polls after input managers update and before state/substate update. Changing toolbar pages cancels existing contacts; cancelled Chart drags finish at their last valid position instead of resuming on the next tap.

## Open and save

Core JSON operations use Android Storage Access Framework `ACTION_OPEN_DOCUMENT` / `ACTION_CREATE_DOCUMENT`. No storage permission was added. The provider's actual display filename is returned. Cancel, null URI/stream, missing Activity and I/O errors finish the operation and release the input lock.

- Chart: File → Open Chart / Open Events / Save / Save As / Save Events / Reload Chart. Android Reload asks for the document again; Ctrl+S opens SAF instead of treating a provider filename as a local filesystem path. Autosaves still use the engine's app-accessible backups folder.
- Character: Settings → Open JSON; Character tab → Save Character.
- Stage: Stage → Open JSON; existing Save button exports JSON. Existing import-image action imports PNG or atlas XML/JSON/TXT into the selected mod's `images/` directory, with confirmation before overwrite. Import matching files with the same basename; for an animated sprite, import the PNG then its atlas. Images already in a mod remain usable by their normal asset path. Imported image filenames currently allow letters, numbers, `_` and `-`.
- Week, Menu Character, Dialogue and Dialogue Portrait retain their existing load/save UI with the shared picker fixes.
- Note Splash gains Open JSON alongside Save; its existing TXT converter remains available. The JSON refers to the selected splash image; it does not bundle that image.

The three advanced Chart folder-based V-Slice batch converters remain available on desktop. They were not functional through the Android directory picker and are omitted from the Android menu. SAF tree/batch export is not implemented. This does not affect core chart/event JSON editing or desktop converters.

## Compatibility and validation

V1 gameplay changes, the Android no-Discord configuration, Lua, HScript, shaders, custom events/notes, animated stages/sprites, mod scanning, touchscreen gameplay and note/audio timing code are retained. `PlayState.hx` is unchanged from the V1/Discord-fix base. New custom-week templates reference Tutorial; removed-week achievements are no longer registered. Mod week discovery is unchanged.

**Mods that reference removed vanilla media must include those assets themselves.** Independent mod media and scripts are retained; compatibility with every third-party mod has not been tested.

`backend.LiteAssets.validate()` runs during BASE_GAME_FILES compilation and fails for missing/changed protected Tutorial files or relocated images, invalid Tutorial JSON or the wrong Tutorial stage directory. `tests/lite_v2.py` exercises that real macro's success, missing-file and changed-file paths, asset accounting and the actual Haxe command state. An additional headless routing harness executes 28 assertions against the actual helper/input/pointer source with framework stand-ins. Existing V1 and platform guard tests remain in CI.

Local Haxe 4.3.7 Android release type checking passed with all configured Lua/HScript/shader dependencies and without Discord. Native Android release compilation runs in `mainBuild.yml` through the reusable `android.yml` PR entry point; other platform jobs run only on manual Main Build dispatch. A successful type check alone is not an APK build. See the PR checks/artifact for native compilation results.

[EDITOR_TOUCH_TEST_MATRIX.md](EDITOR_TOUCH_TEST_MATRIX.md) separates source review, automated checks, CI compilation and the **UNTESTED** Android device workflows. No actual touch-only device run, restart/persistence/provider test, audio-sync measurement, RAM/FPS benchmark or device screenshot was performed in this environment.

## Changed source/configuration files

- `Project.xml`; `.github/workflows/android.yml`, `.github/workflows/mainBuild.yml`.
- `assets/shared/weeks/weekList.txt`, `assets/shared/data/characterList.txt`, `assets/shared/data/stageList.txt`; `assets/base_game/shared/stages/stage.json`; removals/relocations are enumerated in the manifest.
- `source/backend/Achievements.hx`, `source/backend/WeekData.hx`, new `source/backend/LiteAssets.hx`.
- `source/backend/ui/`: new `EditorKeyState.hx`, `EditorInput.hx`, `EditorPointer.hx`; existing `PsychUIBox.hx`, `PsychUIButton.hx`, `PsychUICheckBox.hx`, `PsychUIDropDownMenu.hx`, `PsychUIInputText.hx`, `PsychUINumericStepper.hx`, `PsychUIRadioGroup.hx`, `PsychUISlider.hx`.
- New `source/mobile/controls/EditorTouchControls.hx`; `source/mobile/backend/java/FileUtils.java`.
- `source/states/MainMenuState.hx`; `source/states/editors/`: `MasterEditorMenu.hx`, `ChartingState.hx`, `CharacterEditorState.hx`, `StageEditorState.hx`, `WeekEditorState.hx`, `MenuCharacterEditorState.hx`, `DialogueEditorState.hx`, `DialogueCharacterEditorState.hx`, `NoteSplashEditorState.hx`.
- `source/states/editors/content/`: new `EditorFileTools.hx`; `FileDialogHandler.hx`, `Prompt.hx`, `EditorPlayState.hx`.
- New `tests/lite_v2.py`, `tests/editor_touch_routing.py`, `docs/V2_ASSET_MANIFEST.json`, `docs/EDITOR_TOUCH_TEST_MATRIX.md`, this guide.

These are V2 changes relative to `8947d61`; the PR also contains that unmerged Android/Discord fix, documented in `docs/ANDROID_DISCORD_FIX.md`.
