# DRN-PSH: Distributed Reservoir Network Pumped Storage Hydropower

Source code and data for the paper:

> Furukakoi, M., Nakadomari, A., Uehara, A., Krishnan, N., Mandal, P., & Senjyu, T. (2025). **Distributed Reservoir Network Pumped Storage Hydropower Using Dam-Pond Clusters: Optimal Site Selection and Operation for Enhanced Renewable Energy Integration.** *Renewable Energy.*

## Overview

This repository contains MATLAB code for:
- GIS-based optimal site selection algorithm
- Mixed Integer Linear Programming (MILP) optimization model
- Visualization scripts for reproducing paper figures

## Requirements

- MATLAB R2024b (or later)
- Optimization Toolbox
- Mapping Toolbox

## Repository Structure

```
├── src/
│   ├── site_selection/
│   │   └── OptPlace.m              # GIS-based site selection (Fig.5)
│   ├── optimization/
│   │   └── MILP_Optimization.m     # MILP model (Fig.7-9)
│   └── visualization/
│       └── PlotResults.m           # Result visualization
├── data/
│   ├── input/
│   │   ├── CalData.mat             # Input data (price, PV, flow)
│   │   └── shapefiles/             # GIS data (.shp files)
│   └── results/
│       └── OptPlace.mat            # Site selection results
└── README.md
```

## Usage

### 1. Site Selection

```matlab
% Run GIS-based site selection algorithm
run('src/site_selection/OptPlace.m')
```

### 2. Operation Optimization

```matlab
% Run MILP optimization
% Set CasePara to select system configuration:
%   [1;0;0] - S-PSH (Single-stage)
%   [1;1;0] - C-PSH (Cascade)
%   [1;1;1] - DRN-PSH (Distributed Reservoir Network)

run('src/optimization/MILP_Optimization.m')
```

### 3. Reproduce Figures

```matlab
% Generate paper figures
run('src/visualization/PlotResults.m')
```

## Input Data

| File | Description | Source |
|------|-------------|--------|
| Electricity price | JEPX spot market (2018) | [JEPX](https://www.jepx.jp/) |
| PV generation | Solar irradiance data | [NEDO](https://www.nedo.go.jp/) |
| Water inflow | Dam inflow data | [METI](https://www.enecho.meti.go.jp/) |
| Dam locations | National Land Information | [MLIT](https://nlftp.mlit.go.jp/) |
| Pond locations | Agricultural reservoir data | [MAFF](https://www.maff.go.jp/) |

## Key Parameters

| Parameter | Value |
|-----------|-------|
| Dam-Dam threshold | 1.5 km |
| Dam-Pond threshold | 1.0 km |
| Generation efficiency | 0.85 |
| Pumping efficiency | 0.75 |
| Transmission capacity | 250 kW |

## Citation

```bibtex
@article{furukakoi2025drnpsh,
  title={Distributed Reservoir Network Pumped Storage Hydropower Using 
         Dam-Pond Clusters: Optimal Site Selection and Operation for 
         Enhanced Renewable Energy Integration},
  author={Furukakoi, Masahiro and Nakadomari, Akito and Uehara, Akie 
          and Krishnan, Narayanan and Mandal, Paras and Senjyu, Tomonobu},
  journal={Renewable Energy},
  year={2025},
  doi={10.1016/j.renene.2025.XXXXX}
}
```

## License

MIT License

## Contact

Masahiro Furukakoi  
Sanyo-Onoda City University  
Email: furukakoi@rs.socu.ac.jp  
ORCID: [0000-0002-1169-017X](https://orcid.org/0000-0002-1169-017X)
