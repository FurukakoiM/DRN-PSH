# DRN-PSH: Distributed Reservoir Network Pumped Storage Hydropower

Source code and data for the paper:

> Masahiro Furukakoi, Akito Nakadomari, Akie Uehara, Narayanan Krishnan, Paras Mandal and Tomonobu Senjyu (20**). **Distributed Reservoir Network Pumped Storage Hydropower Using Dam-Pond Clusters: Optimal Site Selection and Operation for Enhanced Renewable Energy Integration.** *Submitted to Renewable Energy.*

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
│   ├── OptPlace.m              # GIS-based site selection (generates Fig.5-6 & Tab.3)
│   ├── MILP_Optimization.m     # MILP optimization model (generates Fig.4,7-9 & Tab.5)
│   ├── DataAll.mat             # Input data (Price, PV, Water inflow)
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
| DataAll.mat (Price data) | JEPX spot market | Ref.[[21]](https://www.jepx.jp/electricpower/market-data/spot/)|
| DataAll.mat (PV data) | Solar irradiance data | Ref.[[22]](https://appww2.infoc.nedo.go.jp/appww/metpv.html?p=81481)|
| DataAll.mat (Water inflow data) | Dam inflow data | Ref.[[23]](https://www.enecho.meti.go.jp/category/saving_and_new/saiene/ryuryodatabase/search_water_dam_data/?ID=35224900011001) |
| yamaguchi_dam.xlsx (Dam data) | National Land Information | Ref.[[18]](https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-W01.html) |
| yamaguchi_pond.xlsx (Pond data) | Agricultural reservoir data | Ref.[[19]](https://www.maff.go.jp/j/nousin/bousai/bousai_saigai/b_tameike/ichiran.html) |

## Citation

**Note**: Citation information will be updated upon publication.

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

## Contact

Masahiro Furukakoi  
Sanyo-Onoda City University  
Email: furukakoi@rs.socu.ac.jp  
ORCID: [0000-0002-1169-017X](https://orcid.org/0000-0002-1169-017X)
