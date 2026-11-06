# Azeroth Survivors — iPhone port candidate

Initial target: ARM64 iPhone, landscape orientation.

This is a source patch and build workflow, NOT a compiled or tested iPhone app.
There is no IPA yet. The native iOS build, touch regression tests, game-data
compatibility, rendering, audio, memory use, signing and physical-device play
test remain outstanding. Further porting fixes may be needed after compilation.

## Prepared changes

- Tap a world location to move there; hold and drag to update the destination.
- Stop, Jump, Ability and Pause / Resume buttons during play.
- Touch-to-mouse bridge for the existing menus; cancellation drops the cursor.
- Movement stops on pause, death, loading, and loss of focus.
- Separate writable iOS settings path; landscape ARM64 app bundle and Metal.
- Exclude desktop clipboard dependencies on iOS.

Controls use one active finger. Lift before tapping an action button.
The movement uses the game's existing terrain-height movement, not new obstacle
pathfinding. UI sizing and safe-area placement still need testing on the phone.

## Build without owning a Mac

This GitHub build repository contains only this folder: the workflow,
patch, assembly script, README and engine license notices. The workflow fetches
OutThisLife/azeroth-survivors-re at commit
72048f4056e2a57d99234e4fb658179e577d1d92, applies the patch, runs touch-input tests,
then compiles the native engine on a GitHub macOS runner. It does not upload or
download game archives. Standard GitHub-hosted runners are free for public
repositories. A private fork consumes the account's Actions allowance and can
incur charges according to its billing settings. Check the Actions page for
the current build result.

After a successful build, download the `iphone-engine` artifact and extract
`iphone-engine.zip`. Run this in PowerShell:

```powershell
.\Assemble-Ipa.ps1 -EngineZip 'C:\path\to\iphone-engine.zip'
```

The script reads the existing game Data folder and creates
`AzerothSurvivors-unsigned.ipa` beside itself. It never modifies the game folder.
The IPA must then be signed through an appropriate iPhone sideloading tool.
Do not enter Apple account credentials into these scripts or GitHub secrets.

## Verification so far

The source patch passes Git's whitespace and reverse-application checks. The
Cargo manifests and iOS plist parse correctly. The Windows assembly script
passes tests for copying data unchanged, retaining executable permissions,
rejecting Windows binaries and protecting an existing output file. These tests
use synthetic headers and do not validate a real iOS executable. There is no
Rust toolchain or Apple SDK available locally, so Rust compilation and the
included regression tests have NOT run. A successful compile alone will not
establish that the game is playable on iPhone.

## Source

https://github.com/OutThisLife/azeroth-survivors-re

Engine source is MIT OR Apache-2.0, with its upstream third-party notices.
Game data is kept local and is not included in this package.
