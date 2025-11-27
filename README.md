# DRN-PSH: Distributed Reservoir Network Pumped Storage Hydropower

Source code and data for the paper:

> Furukakoi, M., Nakadomari, A., Uehara, A., Krishnan, N., Mandal, P., & Senjyu, T. (2025). **Distributed Reservoir Network Pumped Storage Hydropower Using Dam-Pond Clusters: Optimal Site Selection and Operation for Enhanced Renewable Energy Integration.** *Submitted to Renewable Energy.*

**Note**: This paper is currently under review.

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
DRN-PSH/
├── src/
│   ├── OptPlace.m              # GIS-based site selection (generates Fig.5-6 & Table 3)
│   ├── MILP_Optimization.m     # MILP optimization model (generates Fig.4,7-9 & Table 5)
│   ├── DataAll.mat             # Input data (PV, price, water inflow)
│   ├── yamaguchi_pond.xlsx     # Pond database
│   ├── yamaguchi_dam.xlsx      # Dam database
│   └── N03-20240101_35.shp     # Yamaguchi Prefecture boundary (optional)
├── README.md
└── LICENSE.txt
```

## Usage

### 1. Site Selection

```matlab
% Run GIS-based site selection algorithm
run('src/OptPlace.m')
```

### 2. Operation Optimization

```matlab
% Run MILP optimization
% Set CasePara to select system configuration:
% CasePara=[1;1;1];
%   [0;0;0] - w/o PSH
%   [1;0;0] - S-PSH (Single-stage)
%   [1;1;0] - C-PSH (Cascade)
%   [1;1;1] - DRN-PSH (Distributed Reservoir Network)

run('src/MILP_Optimization.m')
```


## Input Data

| File | Description | Source |
|------|-------------|--------|
| Electricity price | JEPX spot market (2018) | [JEPX](https://www.jepx.jp/) |
| PV generation | Solar irradiance data | [NEDO](https://www.nedo.go.jp/) |
| Water inflow | Dam inflow data | [METI](https://www.enecho.meti.go.jp/) |
| Dam locations | National Land Information | Ref.[18](https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-W01.html) |
| Pond locations | Agricultural reservoir data | Ref.[19](https://www.maff.go.jp/j/nousin/bousai/bousai_saigai/b_tameike/ichiran.html) |

## Citation

**Note**: Citation information will be updated upon publication.

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

## Contact

Masahiro Furukakoi  
Sanyo-Onoda City University  
Email: furukakoi@rs.socu.ac.jp  
ORCID: [0000-0002-1169-017X](https://orcid.org/0000-0002-1169-017X)
