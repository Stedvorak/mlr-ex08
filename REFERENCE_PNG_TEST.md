# PNG reference diagnostic — awaiting browser verification

`check_image.png` is a lossless 96×96 RGB copy of the reference pixels. It was generated from Windows System.Drawing's JPEG decode, which matches both supplied verified Chrome hashes and pixel 4096. The PNG contains only IHDR, IDAT and IEND chunks, with no colour profile or gamma metadata.

Local checks passed: decoding the generated PNG reproduces all 36,864 RGBA bytes exactly, the hashes below match, and the diagnostic JavaScript passes its syntax check. ONNX inference and browser/device checks have **not** been executed for this PNG.

The original `index.html`, `debug.html`, `leaf_model.onnx`, `model_info.json`, `check_image.jpg` and `check_expected.json` are unchanged. The main app still tests the JPEG. Its Safari mismatch remains unresolved until the PNG diagnostic is tested on both devices.

## Test on Chrome and Safari

1. Serve this folder over HTTPS at an address reachable from both devices. No files have been pushed or deployed automatically.
2. Open `debug_png.html` in Chrome on Windows, then in Safari on iPhone. Press **Run diagnostic** on each.
3. Confirm all of these on both devices:

   - `referenceImage`: width 96, height 96.
   - `rgbaFnv1aHash`: `eeb06748`; `rgbaMatchesChrome`: `true`.
   - `tensorFnv1aHash`: `3d21aad1`; `tensorMatchesChrome`: `true`.
   - Pixel 4096: `[162,162,150,255]`.
   - `maximumError` at most `0.0001`, against the unchanged `check_expected.json`.
   - `numericalPass` and overall `pass`: both `true`.

4. Use **Copy results** to retain the full JSON from each device, including its URL, user agent and all four class probabilities. Send both results back for comparison. Hash agreement alone is insufficient: both numerical checks must also pass.
5. Keep the original `debug.html` JPEG diagnostic separate; do not label its Safari result as passing based on the PNG result.

Only after both PNG browser results pass should the main app's internal reference image change from `check_image.jpg` to `check_image.png`. At that point its reference description should explain that the original JPEG is retained and the PNG is used for deterministic cross-browser verification. Camera preprocessing, model files, labels and expected probabilities require no changes.
