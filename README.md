# VINI — Virtual Drug Screening & *In Silico* Cancer Modeling Platform

**VINI** is an open-source, multi-tier virtual drug-screening orchestrator designed for high-performance computing (HPC) clusters. It integrates molecular docking, structural modeling, and semiempirical quantum mechanical (SQM) calculations with metabolic pathway eigenvalue analysis to evaluate single-agent and multi-drug combination efficacy against cancer pathways.

## Key Capabilities & Integrated Engines
* **High-Throughput HPC Orchestration:** Dynamically generates and submits asynchronous SLURM jobs across multi-node CPU and GPU partitions.
* **Small-Molecule & Macromolecular Docking:** Integrates **AutoDock Vina** (Lamarckian genetic algorithm) and **Rosetta** (Monte Carlo protein–protein docking).
* **Quantum-Mechanical Scoring:** Uses **MOPAC (MOZYME)** for linear-scaling $\mathcal{O}(N)$ localized molecular orbital calculations and entropic corrections ($-T\Delta S$) at large biomolecular interfaces.
* **Structure Preparation & Prediction:** Incorporates **AlphaFold 2**, **Open Babel**, **UCSF Chimera**, **PDB2PQR**, **RDKit**, and **MDAnalysis**.

---

## System Requirements
* **Architecture:** Linux HPC cluster (tested on RHEL/CentOS and modern EuroHPC environments).
* **Workload Manager:** **SLURM** (recommended minimum of 10 compute nodes for pathway-scale screening).
* **Prerequisites:** Academic registration for **UCSF Chimera** is required prior to installation:
  * Register at: [https://ucsf.edu](https://ucsf.edu)

---

## Quick Start & Installation

1. **Clone the repository into your `$HOME` directory:**
   ```bash
   git clone https://github.com ~/Vini
   cd ~/Vini
   ```

2. **Launch VINI and follow the interactive setup instructions:**
   ./Vini

   VINI's automated installation framework (`install.sh`) will configure your workload manager settings and compile/link required dependencies against your cluster's environment.

---

## Citation & Reference
If you use VINI in your research, please cite:

> Tomić, D., Skala, K., Kranjčević, L., Pirkić, B., Stifter, S., & Šmit, I. (2018). Evaluation of the efficacy of cancer drugs by using the second largest eigenvalue of metabolic cancer pathways. *Journal of Computer Science & Systems Biology*, 11(3), 240–248. [https://doi.org](https://doi.org)

## License
This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)** — see the [COPYING](COPYING) file for details.
