# Task 4 deliverables

These files were supplied in `candidate_for_camera.zip` after execution in Google Colab. The notebook is the prepared source, with no stored outputs or dataset URL. Set `RUN_ALL=True` to reproduce the full B0–E8 suite; the shorter default runs the priority variants.

- `Task4_Colab.ipynb`: experimental code and Colab instructions.
- `results.csv`: 27 completed runs, B0–E8 with seeds 0, 1 and 2, each trained for 15 epochs.
- `summary.csv`: means and sample standard deviations across seeds.
- `paired_comparisons.csv`: differences against the declared baselines on matched seeds.
- `experiment_status.csv`: completed runs and E9 marked `not_run`.
- `comparison.png`: validation comparison chart.
- `candidate_leaf_model.onnx`: separately exported candidate, E5 seed 1.
- `model_info.json`: class order and preprocessing contract.
- `verification.json`: Colab export parity and CPU timing measurements; phone speed was not tested.

Publication checks recomputed the CSV aggregates and paired differences, checked the model's embedded metadata and input/output shapes, and independently evaluated the candidate on the 62 original validation images: **51 correct**, matching its recorded result. The reported camera-like result is **53/62**. The Colab parity report records 124/124 matching predictions and maximum probability error 0.00000602007; that PyTorch comparison was not repeated during publication.

Inputs are float32 RGB `[1,3,96,96]`, scaled to 0–1 and standardized using the supplied mean/std. Outputs are four logits in the metadata's class order. Central-square cropping and resizing happen before inference.

Original photographs, private dataset URLs, training checkpoints and generated camera-like photographs are excluded. Full per-epoch histories and runtime configuration remain in private Colab/Drive storage and are not in this bundle. The existing website and root `leaf_model.onnx` remain unchanged. The student's `REPORT.md` and `REVIEW.md` are separate pending submission items.
