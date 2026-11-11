# Leaf lens · MLR exercise 08

Page URL: **https://stedvorak.github.io/mlr-ex08/**

Configured for GitHub Pages from the root of the main branch. The publishing script verifies the live page before reporting success.

A single `index.html` with plain JavaScript and ONNX Runtime Web 1.20.1 from jsDelivr. No build step or application server is needed. Keep the four supplied model/reference files next to `index.html`.

Open the HTTPS page in iPhone Safari, tap **Start rear camera**, and allow camera access. The video stays inline and uses the rear camera preference. **Choose photo** is the fallback if camera access is unavailable. The probabilities of apple, cherry, chestnut, and maple update after each prediction. Processing stays on the device; network access is used to load the runtime and model files.

For both video and uploaded photos, the page crops the central square, resizes it to 96×96, converts RGB to 0–1, applies `(channel - mean) / std` using `model_info.json`, and packs float32 input as `[1, 3, 96, 96]` in RGB channel order. The model's `logits` output is converted to probabilities using stable softmax. Camera inference is sequential, with a 100 ms pause between predictions. Single-threaded WASM avoids requiring cross-origin isolation or WebGPU on Safari.

Tap **Run reference check** to classify `check_image.jpg` through the same preprocessing code and compare all four probabilities with `check_expected.json`. The absolute tolerance is `0.0001` in probability units, allowing minor JPEG-decoder and floating-point differences.

| Class | Expected probability |
| --- | ---: |
| apple | 0.34354305267333984 |
| cherry | 0.6564558148384094 |
| chestnut | 0.000001200799374601047 |
| maple | 0.000000028531562890066198 |

Local verification passed using the page's actual JavaScript preprocessing and the supplied ONNX model in native ONNX Runtime: maximum absolute probability error **0.00000501**. Crop coordinates were checked for square, landscape and portrait frames; every RGB channel and NCHW element was checked. The embedded SVG was independently decoded to the URL below. Browser WASM inference and a physical iPhone camera have not been tested in this restricted environment.

The footer QR code is an SVG generated locally with OpenCV and embedded inside `index.html`. It decodes to **https://stedvorak.github.io/mlr-ex08/**, matching the adjacent clickable link. No external QR image service is used.

For a local preview, run `python -m http.server 8000` from this folder and open `http://localhost:8000/`. Camera access from a phone requires an HTTPS deployment; plain HTTP over a local network does not qualify.

To publish from an environment with GitHub network access and an authenticated `gh` account for `Stedvorak`, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\publish.ps1
```

The script creates the public `mlr-ex08` repository, pushes `main`, enables Pages from the branch root, invites `MLRteacher` with write permission, and waits for a successful Pages build and an HTTP 200 response. It checks the deployed HTML and embedded QR against the Pages URL. It can resume an interrupted deployment.

Runtime configuration follows [ONNX Runtime's environment flags documentation](https://onnxruntime.ai/docs/tutorials/web/env-flags-and-session-options.html).
