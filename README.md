# Leaf lens · MLR exercise 08

Page URL: **https://stedvorak.github.io/mlr-ex08/**

Configured for GitHub Pages from the root of the main branch. The publishing script verifies the live page before reporting success.

A single `index.html` with plain JavaScript and ONNX Runtime Web 1.20.1 from jsDelivr. No build step or application server is needed. Keep the supplied model/reference files and `check_image.png` next to `index.html`.

Open the HTTPS page in iPhone Safari, tap **Start rear camera**, and allow camera access. The video stays inline and uses the rear camera preference. **Choose photo** is the fallback if camera access is unavailable. The probabilities of apple, cherry, chestnut, and maple update after each prediction. Processing stays on the device; network access is used to load the runtime and model files.

For both video and uploaded photos, the page crops the central square, resizes it to 96×96, converts RGB to 0–1, applies `(channel - mean) / std` using `model_info.json`, and packs float32 input as `[1, 3, 96, 96]` in RGB channel order. The model's `logits` output is converted to probabilities using stable softmax. Camera inference is sequential, with a 100 ms pause between predictions. Single-threaded WASM avoids requiring cross-origin isolation or WebGPU on Safari.

Tap **Run reference check** to classify `check_image.png` through the same preprocessing code and compare all four probabilities with the unchanged `check_expected.json`. The absolute tolerance remains `0.0001` in probability units. The original `check_image.jpg` is retained. PNG is used for deterministic cross-browser reference verification because Safari and Chrome decoded the JPEG differently; camera and uploaded-photo preprocessing are unchanged.

| Class | Expected probability |
| --- | ---: |
| apple | 0.34354305267333984 |
| cherry | 0.6564558148384094 |
| chestnut | 0.000001200799374601047 |
| maple | 0.000000028531562890066198 |

Local verification passed using the page's actual JavaScript preprocessing and the supplied ONNX model in native ONNX Runtime: maximum absolute probability error **0.00000501**. Crop coordinates were checked for square, landscape and portrait frames; every RGB channel and NCHW element was checked. The embedded SVG was independently decoded to the URL below. This earlier native-runtime check is separate from the user-confirmed browser diagnostics below. A physical iPhone camera was not tested by the coding agent.

The footer QR code is an SVG generated locally with OpenCV and embedded inside `index.html`. It decodes to **https://stedvorak.github.io/mlr-ex08/**, matching the adjacent clickable link. No external QR image service is used.

For a local preview, run `python -m http.server 8000` from this folder and open `http://localhost:8000/`. Camera access from a phone requires an HTTPS deployment; plain HTTP over a local network does not qualify.

To publish from an environment with GitHub network access and an authenticated `gh` account for `Stedvorak`, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\publish.ps1
```

The script creates the public `mlr-ex08` repository, pushes `main`, enables Pages from the branch root, invites `MLRteacher` with write permission, and waits for a successful Pages build and an HTTP 200 response. It checks the deployed HTML and embedded QR against the Pages URL. It can resume an interrupted deployment.

Runtime configuration follows [ONNX Runtime's environment flags documentation](https://onnxruntime.ai/docs/tutorials/web/env-flags-and-session-options.html).

## Cross-browser reference verification

The following measurements were reported and confirmed by the user from the separate diagnostics. They are not claims of production-page testing after this update. Hashes are FNV-1a over decoded RGBA bytes and float32 input tensor bytes.

| Reference | Browser/device | RGBA hash | Tensor hash | Maximum absolute probability error | Result |
| --- | --- | --- | --- | ---: | --- |
| Original JPEG | Windows Chrome | `eeb06748` | `3d21aad1` | `4.364e-6` (reported rounded) | PASS |
| Original JPEG | iPhone Safari | `c45e9ef4` | `f6171ff8` | `0.1004956` | FAIL |
| Lossless PNG | Windows Chrome | `eeb06748` | `3d21aad1` | `4.3638705657933485e-6` | PASS |
| Lossless PNG | iPhone Safari | `eeb06748` | `3d21aad1` | `4.3638705657933485e-6` | PASS |

For example, JPEG pixel 4096 decoded as RGB `[162,162,150]` in Chrome and `[164,161,154]` in Safari. The PNG preserves the verified Chrome pixels; both browsers then produced identical input hashes and probabilities. The original JPEG failure is not relabelled as passing. `debug.html` retains the JPEG diagnostic; `debug_png.html` checks the PNG.

The finalized main page now loads PNG for its internal reference check. The model, metadata, expected probabilities, labels and camera/photo pipeline are unchanged. **User verification of the updated production page remains pending**, even after a successful push or deployment. See `REFERENCE_PNG_TEST.md` for the verification procedure.
