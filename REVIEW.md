# MLR Exercise 08 — Code and mobile review

Repository: https://github.com/Stedvorak/mlr-ex08  
Published application: https://stedvorak.github.io/mlr-ex08/  
Candidate E5 mobile page: https://stedvorak.github.io/mlr-ex08/e5/

## 1. Application and implementation review (Task 2)

The application is a static HTML/JavaScript page using ONNX Runtime Web 1.20.1 and single-threaded WASM. The ONNX model and `model_info.json` are loaded from the repository. Inference runs locally in the browser, not on a remote prediction server. The UI provides a rear-camera option, photo upload fallback, all four class probabilities (apple, cherry, chestnut, maple), prediction time, a QR code and a reference check.

The shared `preprocess()` function takes a central square crop, resizes to 96 × 96 pixels, reads RGB values from canvas, scales to [0, 1], normalizes with the mean and standard deviation from `model_info.json`, and constructs a float32 NCHW tensor `[1,3,96,96]`. The model outputs logits, which the page converts to probabilities using numerically stable softmax. The camera loop serializes inference to avoid overlapping predictions. The page requests the environment-facing camera over HTTPS and allows a photo when camera permission is unavailable.

### Code-review findings

| Requirement / aspect | Finding | Evidence or limitation |
| --- | --- | --- |
| Public mobile page | Implemented | GitHub Pages URL above |
| ONNX inference in browser | Implemented | `index.html`, ONNX Runtime Web with WASM |
| Input preprocessing | Implemented | Shared `preprocess()` for camera, upload and reference check |
| Four class probabilities | Implemented | Softmax of four logits, progress bars and numeric values |
| Rear camera and upload fallback | Implemented | `getUserMedia` and file input; camera operation not independently measured in this report |
| QR / link to public page | Implemented | Footer link and embedded QR |
| Reference image numerical comparison | Implemented, **cross-browser issue remains on main page** | See measured JPEG/PNG comparison below |
| Model and metadata consistency | Verified in published Task 4 checks | Class order and input/output shapes reported in `task4/README.md` |

## 2. Reference check on desktop and phone

The original reference file `check_image.jpg` produced different decoded pixels on Windows Chrome and iPhone Safari, even though both used the same 96 × 96 image and the same code. The difference was already visible in the canvas RGBA data, before inference. Pixel 4096, for example, was `[162,162,150,255]` on Chrome but `[164,161,154,255]` on Safari. Therefore this was a browser JPEG decoding/color-processing discrepancy, not evidence that the ONNX model itself changed.

| Reference / browser | RGBA FNV-1a | Tensor FNV-1a | Apple | Cherry | Maximum absolute error | Result |
| --- | --- | --- | ---: | ---: | ---: | --- |
| JPEG / Windows Chrome | `eeb06748` | `3d21aad1` | 0.343547320 | 0.656451451 | 0.000004364 | PASS |
| JPEG / iPhone Safari | `c45e9ef4` | `f6171ff8` | 0.243047744 | 0.756951413 | 0.100495598 | FAIL |
| PNG / Windows Chrome | `eeb06748` | `3d21aad1` | 0.343547320 | 0.656451451 | 0.000004364 | PASS |
| PNG / iPhone Safari | `eeb06748` | `3d21aad1` | 0.343547320 | 0.656451451 | 0.000004364 | PASS |

Expected probabilities from `check_expected.json`: apple `0.34354305267333984`, cherry `0.6564558148384094`, chestnut `0.000001200799374601047`, maple `0.000000028531562890066198`. The absolute tolerance is `0.0001`.

The lossless `check_image.png` preserves the reference pixel values. Independent runs of `debug_png.html` on Windows Chrome and iPhone Safari both returned `rgbaMatchesChrome: true`, `tensorMatchesChrome: true`, `numericalPass: true`, and `pass: true`. Their maximum error was `4.3638705657933485e-6`. The original JPEG and expected-probability file were retained unchanged.

**Important status at submission preparation:** The published root `index.html` was still referencing `check_image.jpg` when inspected. Its main **Run reference check** consequently still failed on iPhone Safari. The separate PNG diagnostic **passed** on both devices. Do not report the main production check as fixed unless the `index.html` reference is actually changed and retested. The minimal fix is to use `check_image.png` for the reference check only; the model and camera/photo pipeline should remain unchanged.

## 3. Mobile candidate test (Task 4)

The separate E5 candidate page was opened on iPhone and a photo of a maple leaf was classified as **maple with 89.313267% probability**, with a displayed inference time of **54 ms**. This is a single functional test, **not** a benchmark over many frames, phones or images.

## 4. Screenshots / visual evidence

The screenshots below were captured on iPhone Safari and are included in the `screenshots/` directory. PNG diagnostic PASS on both platforms is documented by the numerical measurements in Section 2; there is no screenshot of that diagnostic.

### Task 2 — original JPEG reference check (FAIL on Safari)

![Original JPEG reference check on iPhone Safari showing FAIL](screenshots/safari_jpeg_reference_fail.png)

This documents the original JPEG mismatch; it is **not** evidence of a passing production reference check.

### Task 2 — original model probabilities

![Original classifier probabilities on iPhone Safari](screenshots/safari_original_model_probabilities.jpeg)

The displayed result is cherry (~75.695%), with a single displayed prediction time of 14 ms.

### Task 4 — E5 candidate on iPhone

![Uploaded maple leaf on the E5 candidate page](screenshots/e5_maple_photo.jpeg)

![E5 candidate probabilities: maple 89.313267%, 54 ms](screenshots/e5_maple_probabilities.png)

The E5 model predicted maple at 89.313267% with 54 ms displayed for this one example. It is a functional test, not a multi-image benchmark.

## 5. Review conclusion

The static ONNX web application implements the core classification and mobile interaction flow. A genuine cross-browser JPEG decoding difference was identified through pixel hashes and tensor hashes. A lossless PNG reference passed independently on Chrome and Safari without changing the model or expected values. At the time of this review, the root-page reference check had not yet been switched to PNG; this is an explicit outstanding limitation rather than a claimed success.
