# AI-Powered RF Digital Twin — ADALM-Pluto hardware stage

The "Future Work" stage from the mid review: a 1D CNN (2×128 I/Q in, 5 classes: AM-DSB, BPSK, QAM16, QPSK, WBFM) classifies **real RF signals** transmitted and received **over the air** by one ADALM-Pluto.

```
 MATLAB  ──USB──►  ADALM-PLUTO
 genModWaveform     TX1 antenna ))) air, ~2 cm ))) RX1 antenna
 (BPSK/QPSK/QAM16/      │                                │
  AM-DSB/WBFM)          └──── one board, shared clock ───┘
                                                         │
 Live dashboard ◄── CNN (net1D) ◄── 2×128 frames ◄── rx() I/Q
```

## 1. Setup that produced the results

| Item | Value |
|---|---|
| Radio | One ADALM-Pluto (AD9363), USB cable in the middle (data) micro-USB port |
| RF link | **Two antennas** on TX1 and RX1, about 2 cm apart, **over the air** (no cable, no attenuator) |
| Centre frequency / sample rate | 915 MHz / 1 MS/s |
| Gains | TX −30 dB, RX 30 dB (manual) — chosen by a gain sweep so the RX does not clip |
| Software | MATLAB R2026b + Communications, DSP System, Signal Processing, Deep Learning toolboxes + Communications Toolbox Support Package for ADALM-PLUTO Radio |

If you use an SMA cable from TX1 to RX1 instead of antennas, add a **30 dB attenuator** and retune the gains (step 1 warns about clipping).

## 2. Folder layout

Scripts are in `pluto/`, trained networks in `models/` and data in `data/`. `plutoConfig.m` finds them itself, so from the repository root just run:

```matlab
addpath('pluto')
```

## 3. Run order

| Step | Script | Hardware? | What it does |
|---|---|---|---|
| 1 | `pluto_step1_check` | Yes | Finds the Pluto, sends a 100 kHz tone, checks it arrives over the air without clipping |
| 2 | `pluto_step2_reference` | No (once) | `pluto_ref.mat`: RadioML reference RMS for normalising frames |
| – | `train_radioml_tvt` | No | Trains the CNN on RadioML with a **70/15/15** train/val/test split → `RF_Modulation_AI_v2.mat` |
| 4 | `pluto_step4_collect_dataset` | Yes | Records **25,000** real frames: 5 modulations × 5 TX power levels × 1,000 |
| 6 | `pluto_step6_finetune` | No | Fine-tunes on real frames with a **70/15/15** split → `RF_Modulation_AI_Pluto.mat` |
| 7 | `pluto_step7_independent_test` | Yes | Fresh recording (9,600 frames, new random data, never used in training) |
| 5 | `pluto_step5_evaluate` | No | Accuracy tables, confusion matrices, accuracy vs SNR |
| 3 | `pluto_step3_live_digital_twin` | Yes | **Live demo**: press 1–5 to switch modulation (uses the fine-tuned model) |
| – | `make_ppt_figures`, `make_annotated_confusion` | No* | Figures for the slides (*the tone plot needs the Pluto) |

## 4. Final results

| Stage | Training | Validation | Test |
|---|---|---|---|
| RadioML CNN (17,500 / 3,750 / 3,750 frames) | 84.9% | 83.3% | **85.25%** |
| Pluto fine-tuning (10,500 + 5,000 RadioML / 2,250 / 2,250) | 99.7% | 99.5% | **99.6%** |
| Fresh recording, original CNN | – | – | **74.1%** |
| Fresh recording, fine-tuned CNN | – | – | **96.7%** |

- The mid-review model (80/20 split, test used as validation) scored 85.86%; it was retrained with a proper 70/15/15 split → **85.25%**, which is the number used in the final slides.
- **Frame counts:** the Pluto recording has 25,000 frames over 5 power levels. Train/val/test use the 3 strongest levels = 15,000 frames (10,500 / 2,250 / 2,250). The 2 weakest levels (10,000 frames, near the noise floor) are only used to test accuracy vs SNR.
- **Comparison caution:** RadioML and Pluto numbers come from different conditions (many simulated channels vs one short-range lab link that the network was fine-tuned on), so 96.7% vs 85.25% is not a like-for-like comparison.
- Majority vote over consecutive frames on the fresh recording: 1 frame 96.7%, 8 frames 99.5%, 64 frames 100%.

## 5. How the hardware pipeline matches the dataset

| RadioML 2016.10a | This implementation |
|---|---|
| 128 complex samples per example | `cfg.frameLen = 128` |
| 8 samples/symbol, RRC pulse shaping | `cfg.sps = 8`, RRC roll-off 0.35 |
| Analog mods from real audio | Music clip `handel.mat` (built into MATLAB) |
| Frames stored as `[I; Q]` 2×128 | `frameAndNormalize` produces the same 2×128 single |
| Fixed amplitude scale | Each frame is scaled to the RadioML average RMS (`refRMS` = 0.00812) |

## 6. Troubleshooting

| Problem | Fix |
|---|---|
| `findPlutoRadio` returns nothing | Use the middle (data) USB port, re-plug, check Device Manager shows "PlutoSDR" |
| "Unrecognized function sdrtx" | Restart MATLAB (it was open before the support package was installed) |
| "RX is clipping" in step 1 | Lower `cfg.txGain` or `cfg.rxGain` |
| Signal only a few ADC steps / previous modulation leaks into the next | `startTransmit.m` must `release(rx)` before `transmitRepeat` (restarts the RX after the TX) |
| Accuracy stuck at ~20% | Check antennas are screwed on, run step 2 again, check the signal isn't clipping or buried in noise |

## 7. Files

| File | Purpose |
|---|---|
| `plutoConfig.m` | All settings (frequency, gains, sample rate, file paths) |
| `genModWaveform.m` | Generates BPSK / QPSK / QAM16 / AM-DSB / WBFM baseband waveforms |
| `plutoRadios.m` | Creates the `sdrtx` / `sdrrx` Pluto objects |
| `startTransmit.m` | Starts `transmitRepeat`, restarts the RX and flushes stale buffers |
| `captureBuffer.m` | One RX buffer (real Pluto or simulated) |
| `frameAndNormalize.m` | Buffer → normalised 2×128 CNN frames |
| `splitTVT.m` | Stratified train / validation / test split |
| `simChannel.m` | Simulated channel for testing without hardware |
