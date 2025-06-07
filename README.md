# Array WAH: Widefield Acoustics Heuristic for 3D Localisation of Bat Calls

**Author**: Ravi Umadi
**Affiliation**: Technical University of Munich
**License**: [CC BY-NC-SA 4.0](LICENSE.md)

---

## 🔍 Overview

**Array WAH** is a MATLAB-based simulation and analysis toolkit designed for designing, simulating, and benchmarking 3D microphone array geometries for precise acoustic localisation of ultrasonic bat calls.

It supports:

- Virtual bat call simulation
- Frequency-dependent propagation
- Time Difference of Arrival (TDOA) multilateration
- 3D grid sweep error mapping
- Statistical and visual analyses of localisation performance

The toolkit supports multiple array geometries including:

- Tetrahedron
- Planar Square
- Pyramid
- Octahedron
- Custom Geometry

---

## Theory and Approach

Array WAH models the entire localisation chain:

###  1. Call Generation

Simulated calls are modelled as **quadratic FM sweeps**, mimicking natural bat calls. A Hanning window smooths the onset/offset.

###  2. Signal Propagation

Signals experience frequency-dependent **atmospheric attenuation** and **geometric spreading**. Delays are applied using **fractional delay filters**.

###  3. Microphone Reception

Each mic receives a scaled and delayed version of the original call, according to its distance and orientation relative to the source.

### 4. TDOA Estimation

Cross-correlation is used to estimate **relative time delays** between each mic and a reference.

###  5. Localisation (Multilateration)

Using the TDOA vector, **nonlinear least squares** is used to estimate the 3D source position via multilateration.

###  6. Grid Sweep & Error Mapping

The process is repeated over a 3D grid of source locations. Positional and angular errors are computed and saved.

###  7. Analysis and Visualisation

- 3D scatter plots
- Histograms and boxplots
- Contour maps across elevation slices
- Statistics

---

##  Folder Structure

```
Array_WAH/
│
├── src/                      # All class definitions
│   ├──wah_analyzer.m
│   ├──mic_array_configurator.m
│   ├──BatCallLocaliser.m
│
├── configs/                  # Saved mic array configurations (auto-generated)
├── results/                  # Output CSVs and figures
│   └── figures/
│
├── simulate_batcall_localisation.m      # Simulates calls and saves localisation results
├── demo_wah_analyzer.m       # Loads CSVs and performs statistical analysis
├── demo_mic_array_configurator.m      # Demo for mic_array_configurator
├── demo_test_single_point.m # Run a single point analysis for test mic configration and source location
├── startup.m          # Adds src/ to path and checks dependencies
├── LICENSE
└── README.md
```

---

##  Quickstart

### 1. Initialise

```matlab
run startup.m
```

This script:

- Adds `src/` to path
- Verifies required toolboxes

### 2. Simulate Localisation Data

```matlab
run simulate_batcall_localisation.m
```

Generates TDOA-based localisation results over a 3D grid for each array config.

### 3. Run Analysis

```matlab
run demo_wah_analyzer.m
```

Loads results and:

- Separates inliers/outliers
- Generates visualisations
- Performs ANOVA and Tukey tests

### 4. Visualise and Export Microphone Arrays

```matlab
run demo_mic_array_configurator.m
```

---

### Test Run a Single Point
```matlab
run demo_test_single_point.m
```

---
## 📦 Dependencies

| Toolbox                                 | Required                        |
| --------------------------------------- | ------------------------------- |
| Signal Processing Toolbox               | ✅                               |
| Statistics and Machine Learning Toolbox | ✅                               |
| Curve Fitting Toolbox                   | ⚠️ Optional (for fitting trends) |

If any are missing, install via:

```matlab
matlab.addons.install('toolboxName.mltbx')
```

---

##  Cite This Work

This toolkit was developed for the manuscript:

> **Widefield Acoustics Heuristic: Advancing Microphone Array Design for Accurate Spatial Tracking of Echolocating Bats**  

<div style="font-family: sans-serif; line-height: 1.6; max-width: 600px; border: 1px solid #ccc; padding: 1em; border-radius: 8px;">
  <p>The preprint is available at:</p>
  <p>
    <strong>DOI:</strong>
    <a href="https://doi.org/10.1101/2025.06.03.657701" target="_blank">10.1101/2025.06.03.657701</a>
  </p>
  <div style="text-align: center; margin-top: 1em;">
    <img src="img/qr_img.png" alt="DOI QR Code" style="width: 150px; height: auto; border: 1px solid #eee; border-radius: 4px;">
  </div>
</div>

---

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0** license ([CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)).

> ✔️ Free to use and modify  
> ❌ No commercial use  
> 📝 Please attribute: "Ravi Umadi, Array WAH (2025)"

---

##  Acknowledgements

This project is part of my ongoing research and technological development into field-deployable, portable MCU-based multichannel microphone arrays. I thank my supervisor and colleagues at the Lehrstuhl für Zoologie at Weihenstephan.

---

##  Bug Reports / Feature Requests

Please open an issue or pull request on GitHub.