# Quantum ESPRESSO DFT Tutorial

[English](README.md) | [简体中文](README_zh.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Quantum ESPRESSO](https://img.shields.io/badge/Quantum%20ESPRESSO-v7.0-brightgreen.svg)](https://www.quantum-espresso.org/)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live%20Demo-orange.svg)](https://hyfaust.xyz/qe-learn/)

> A progressive, hands-on tutorial series for learning Density Functional Theory (DFT) with Quantum ESPRESSO — from first SCF calculation to advanced phonon, spectroscopy, and molecular dynamics simulations.

**🌐 Live Site:** [https://hyfaust.xyz/qe-learn/](https://hyfaust.xyz/qe-learn/)

## Table of Contents

- [Introduction](#introduction)
- [Chapters](#chapters)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Building the Web Site](#building-the-web-site)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Introduction

This project provides a structured, 12-chapter tutorial for learning computational materials science with **Quantum ESPRESSO**, one of the most widely used open-source plane-wave DFT codes. Each chapter includes:

- **Detailed Markdown documentation** explaining key concepts, input parameters, and physics
- **Tested input files** (`.in`) ready to run with `pw.x`, `ph.x`, `bands.x`, `dos.x`, `projwfc.x`, `dynmat.x`, `q2r.x`, `matdyn.x`, `epsilon.x`, `hp.x`, `cp.x`, and `neb.x`
- **Automation scripts** (`.sh`, `.py`) for convergence testing and workflow execution

All 59 input files have been verified against a local Quantum ESPRESSO v7.0 installation.

## Chapters

| # | Chapter | Topics | Difficulty |
|---|---------|--------|:----------:|
| 01 | [QE Basics & DFT Theory](chapters/01_qe_basics/) | Hohenberg-Kohn, Kohn-Sham equations, input file structure, first SCF | ⭐ |
| 02 | [Plane Waves & Pseudopotentials](chapters/02_plane_waves_pseudopotentials/) | Plane wave basis, ecutwfc convergence, NC/USPP/PAW | ⭐ |
| 03 | [k-Point Sampling](chapters/03_k_sampling/) | Brillouin zone, Monkhorst-Pack grids, k-point convergence | ⭐ |
| 04 | [Band Structure & DOS](chapters/04_bands_and_dos/) | NSCF, high-symmetry paths, DOS, projected DOS | ⭐⭐ |
| 05 | [Metallic Systems](chapters/05_metallic_systems/) | Smearing methods, Fermi surface, Al and Cu | ⭐⭐ |
| 06 | [Structural Optimization](chapters/06_structural_optimization/) | Hellmann-Feynman forces, BFGS, variable-cell relax | ⭐⭐⭐ |
| 07 | [Magnetism](chapters/07_magnetism/) | Spin-polarized DFT, ferromagnetic/antiferromagnetic NiO, Fe | ⭐⭐⭐ |
| 08 | [Phonon Basics](chapters/08_phonon_basics/) | DFPT, ph.x, phonon dispersion, dynamical matrix | ⭐⭐⭐⭐ |
| 09 | [Dielectric & Spectroscopy](chapters/09_dielectric_spectroscopy/) | Dielectric constant, Born charges, IR/Raman, epsilon.x | ⭐⭐⭐⭐ |
| 10 | [Advanced Functionals](chapters/10_advanced_functionals/) | DFT+U, van der Waals (DFT-D3), hybrid HSE06 | ⭐⭐⭐⭐ |
| 11 | [MD & Reaction Paths](chapters/11_md_neb/) | Born-Oppenheimer MD, Car-Parrinello MD, NEB | ⭐⭐⭐⭐⭐ |
| 12 | [Automation Capstone](chapters/12_automation_capstone/) | Full SiC characterization workflow, Python automation | ⭐⭐⭐⭐⭐ |

## Prerequisites

| Dependency | Version | Notes |
|------------|---------|-------|
| [Quantum ESPRESSO](https://www.quantum-espresso.org/) | >= 7.0 | Core DFT engine (`pw.x`, `ph.x`, etc.) |
| Python | >= 3.8 | For `build_web.py` and automation scripts |
| Bash | >= 4.0 | For workflow scripts |
| [matplotlib](https://matplotlib.org/) | >= 3.5 | Optional — for convergence plots |

## Quick Start

```bash
# Clone the repository
git clone https://github.com/hyfaust/qe-learn.git
cd qe-learn

# Run the first example (requires QE in PATH)
cd chapters/01_qe_basics
mkdir -p tmp
pw.x -in inputs/si_scf.in > si_scf.out

# Check the result
grep "JOB DONE" si_scf.out
grep "total energy" si_scf.out
```

## Project Structure

```
qe-learn/
├── index.html              # Web site entry point
├── styles.css              # Web site styles
├── app.js                  # Web site client-side logic
├── build_web.py            # Markdown → HTML build script
├── site/                   # Pre-built HTML pages (12 chapters)
│   ├── 01.html … 12.html
├── chapters/               # Tutorial source (Markdown + examples)
│   ├── 01_qe_basics/
│   │   ├── README.md       # Chapter documentation
│   │   ├── inputs/         # QE input files (.in)
│   │   └── scripts/        # Automation scripts
│   ├── 02_plane_waves_pseudopotentials/
│   │   └── ...
│   └── ... (12 chapters total)
├── .gitignore
└── LICENSE
```

## Building the Web Site

The interactive web site is built from the chapter Markdown files:

```bash
# Install the markdown library (optional — fallback converter included)
pip install markdown

# Generate HTML pages
python3 build_web.py

# Serve locally
python3 -m http.server 8888 --bind 0.0.0.0
# Open http://localhost:8888
```

The site features:
- Dark/light theme toggle
- Chapter navigation with progress tracking
- Syntax-highlighted code blocks
- KaTeX math rendering for LaTeX formulas
- Direct download links for all input files and scripts

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-addition`)
3. Test any new input files with a local QE installation
4. Ensure `python3 build_web.py` runs without errors
5. Submit a Pull Request

## License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Quantum ESPRESSO](https://www.quantum-espresso.org/) — the open-source DFT suite this tutorial is built around
- P. Giannozzi et al., *J. Phys.: Condens. Matter* **21**, 395502 (2009); **29**, 465901 (2017)
- [Pseudopotential Download Page](https://www.quantum-espresso.org/pseudopotentials/)
