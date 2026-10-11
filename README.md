# MinimalGearbox

By Thomas Brauer · Version 1.0

A simple gear indicator for Assetto Corsa, with a large LED-style digit and a
small shift light. The window is transparent, with no frame or background.

## Features

- Forward gears 1–9, neutral and reverse.
- A 14-segment display with diagonal strokes for R and N.
- A shift light that comes on at about 93% of the car's rev limiter.
- Seven colours: red, blue, purple, yellow, cyan, white and green.
- Automatic scaling when the app window is resized.
- A colour choice that is remembered between sessions.

## Requirements

Assetto Corsa with [Custom Shaders Patch](https://github.com/ac-custom-shaders-patch)
installed.

## Installation

1. Extract the release ZIP into your Assetto Corsa installation folder.
2. Check that the files are in `assettocorsa/apps/lua/MinimalGearbox/`.
3. Start a driving session and open MinimalGearbox from the in-game apps sidebar.

For a manual installation, copy the `MinimalGearbox` folder into
`assettocorsa/apps/lua/`.

## Settings

Open the app's settings panel and select a colour swatch. White is the default.

## Code

The app is contained in `MinimalGearbox.lua` and has no build step.
`manifest.ini` registers two CSP callbacks: `gearMain` for the display and
`gearSettings` for the colour picker. All other functions are local.

`gearMain` looks up the current gear in `GEAR_SEGMENTS`, checks the shift-light
threshold, then calls `drawGearDisplay`. Each mask lists the segments to light;
-1 represents reverse and 0 represents neutral. The segment layout is shown
at the top of the Lua file.

The renderer fits the digit to the window and calls the horizontal, vertical
and diagonal drawing helpers. Each helper draws one pointed LED segment.

To change the shift-light threshold, edit `SHIFT_RPM_FRACTION`. To add a colour,
update both `COLORS` and `COLOR_ORDER`. Keep the `color` storage key unchanged
to preserve existing users' settings.

## License

PolyForm Noncommercial License 1.0.0 — see [LICENSE](LICENSE).

Noncommercial use, modification and redistribution are permitted under the license.
Commercial use requires separate permission from the copyright holder.
