# 🔬 CDC-Safe Asynchronous FIFO — RTL to GDS Physical Design

## 📋 Project Overview

This project implements a **CDC-safe Asynchronous FIFO** (First-In-First-Out buffer) from **RTL to GDS** using open-source EDA tools on the **SkyWater 130nm HD PDK**.

The design safely transfers data between two independent clock domains using **Gray-code pointers** and **2-FF synchronizers** to prevent metastability.

---

## 🎯 Design Specification

| Parameter | Value |
|-----------|-------|
| **Data Width** | 8 bits |
| **FIFO Depth** | 16 entries (2^4) |
| **Write Clock** | 100 MHz |
| **Read Clock** | 100 MHz (independent) |
| **CDC Mechanism** | Gray-code pointers + 2-FF synchronizers |
| **Full/Empty flags** | Write domain / Read domain |
| **Reference** | Cliff Cummings, SNUG 2002 |

---

## 🧠 Why Asynchronous FIFO?

When two systems run on different clocks, direct data transfer causes **metastability**.

**Example:** Ethernet controller (fast) → System memory (slow)

Ethernet (100MHz) ──writes──▶ [ASYNC FIFO] ──reads──▶ System Memory (80MHz)

**Depth calculation:**
- Write clock = 100MHz, Read clock = 80MHz, Burst = 50 packets
- Data written in 500ns: 50 packets
- Data read in 500ns: 40 packets
- **FIFO depth needed = 50 - 40 = 10 → rounded to 16 (2^4)**

---

## 🏗️ RTL Architecture

```
async_fifo (top)
├── Dual-port FIFO memory     (16×8 flop array)
├── Write pointer             (binary + Gray encoder)
├── Read pointer              (binary + Gray encoder)
├── 2-FF synchronizer         wr_gray → rd_clk domain
├── 2-FF synchronizer         rd_gray → wr_clk domain
├── Full flag logic           (write domain)
└── Empty flag logic          (read domain)
```

### Module Hierarchy

### CDC Safety Mechanism

```
Write Domain                        Read Domain
────────────────────────────────────────────────
wr_bin → b2g → wr_gray ──[2FF]──▶ wg_s2
                                      │
                                 empty flag

rd_bin → b2g → rd_gray ──[2FF]──▶ rg_s2
                                      │
                                  full flag
```

### Key RTL Features
- `(* ASYNC_REG = "TRUE" *)` on all synchronizer FFs
- Gray code: only 1 bit changes per increment → metastability safe
- Full detection: MSB pair inverted + lower bits equal
- Empty detection: Gray pointers match

---

## 🔄 Complete Physical Design Flow

```
async_fifo.v  (RTL)
      │
      ▼
  ┌────────┐
  │ Yosys  │  Logic Synthesis
  └────────┘
      │
      ▼
async_fifo_netlist.v
      │
      ▼
  ┌──────────┐
  │ OpenROAD │
  └──────────┘
      ├── Step 1: Floorplan       → 120×120 µm die, 40 rows
      ├── Step 2: IO Placement    → 24 pins on chip boundary
      ├── Step 3: PDN             → met1 + met4 + met5 power grid
      ├── Step 4: Global Place    → NesterovSolve optimizer
      ├── Step 5: Detailed Place  → Legal row placement, 0 overlaps
      ├── Step 6: CTS             → H-Tree, wr_clk + rd_clk domains
      ├── Step 7: Global Route    → GRT with congestion analysis
      ├── Step 8: Detailed Route  → TritonRoute, 0 DRC violations
      └── Step 9: Fill Insertion  → 921 filler cells inserted
      │
      ▼
  ┌──────────┐
  │ OpenRCX  │  RC Parasitic Extraction
  └──────────┘
      │
      ▼
async_fifo.spef  (333 KB)
      │
      ▼
  ┌──────────┐
  │ OpenSTA  │  Sign-off STA (TT / SS / FF corners)
  └──────────┘
      │
      ▼
Sign-off Complete ✅
```

---

## 📊 Physical Design Results

### Implementation Results

| Metric | Value |
|--------|-------|
| **Technology** | SkyWater 130nm HD (sky130_fd_sc_hd) |
| **Total Cells** | 417 (post-synthesis) → 437 (post-CTS) |
| **Core Area** | 6568 µm² |
| **Die Area** | 120 × 120 µm |
| **Utilization** | 55% |
| **Fill Cells** | 921 |

### Cell Breakdown

| Cell Type | Count | Purpose |
|-----------|-------|---------|
| mux2_1 | 128 | FIFO memory (16×8 flop array) |
| dfrtp_1 | 166 | Flip-flops (pointers + sync) |
| mux4_2 | 40 | Memory read logic |
| clkbuf | 20 | Clock tree buffers |
| Logic | 63 | Full/empty flag logic |

---

## 📐 Floorplan Summary

| Parameter | Value |
|-----------|-------|
| Die Area | 120 × 120 µm |
| Core Area | 109.94 × 108.80 µm |
| Standard Cell Rows | 40 rows × 239 sites |
| Total Sites | 9,560 |
| Cells Placed | 417 |
| Utilization | 55% |
| IO Pins | 24 (on bottom edge) |

---

## ⚡ Power Analysis Summary

| Component | Internal | Switching | Leakage | Total | % |
|-----------|----------|-----------|---------|-------|---|
| **Sequential** | 0.711 mW | 0.027 mW | 1.41 pW | **0.739 mW** | 67% |
| **Combinational** | 0.203 mW | 0.161 mW | 1.06 pW | **0.364 mW** | 33% |
| **Macro** | 0 | 0 | 0 | 0 | 0% |
| **Total** | **0.914 mW** | **0.188 mW** | **2.47 pW** | **1.103 mW** | 100% |

### Power Breakdown

| Power Type | Value | Meaning |
|------------|-------|---------|
| **Internal Power** | 0.914 mW (83%) | Cell switching inside standard cells |
| **Switching Power** | 0.188 mW (17%) | Wire charging/discharging |
| **Leakage Power** | 2.47 pW (~0%) | Static transistor leakage |
| **Total Power** | **1.103 mW** | @ 100 MHz, 1.80V, TT corner |

### Key Observations
- Sequential cells dominate power (67%) — 166 DFFs switching every cycle
- Leakage power is negligible (2.47 pW) — good for low-power design
- Dynamic power (internal + switching) = 99.9% of total power
- Low total power (1.10 mW) — suitable for battery-powered applications

---

## 🕰️ Clock Tree Synthesis(H-Tree)

| Clock | Sinks | Buffers | Path Depth | Avg Wire Length |
|-------|-------|---------|------------|-----------------|
| **wr_clk** | 147 | 17 | 2-2 | 119.94 µm |
| **rd_clk** | 19 | 3 | 2-2 | 88.55 µm |

---

## ⏱️ Timing Summary

### Pre vs Post CTS

| Metric | Pre-CTS | Post-CTS | Skew |
|--------|---------|----------|-------|
| Clock delay | 0.228 ns | 0.230 ns | +0.002 ns |
| Data arrival | 2.859 ns | 3.628 ns | +0.769 ns |
| **WNS** | **+4.14 ns** | **+3.37 ns** | **-0.77 ns** |
| TNS | 0.0 ns | 0.0 ns | — |
| Status | ✅ MET | ✅ MET | — |

---

## 🔌 Routing Summary

| Layer | Direction | Usage |
|-------|-----------|-------|
| li1 | — | Local cell connections |
| met1 | Horizontal | Power rails + local routing |
| met2 | Vertical | Signal routing |
| met3 | Horizontal | Signal routing |
| met4 | Vertical | Power stripes + routing |
| met5 | Horizontal | Power stripes only |

**Detailed Routing:** TritonRoute resolved 1594 initial violations → **0 final violations**

| Stage | Tool | Result |
|-------|------|--------|
| Global Route | FastRoute | 791 met1 + 188 met2 + 90 met3 segments |
| Detailed Route | TritonRoute | 1594 → 0 violations in 4 iterations |
| Total Route Time | — | ~1 min 37 sec |
| Peak Memory | — | 525 MB |
| Final DRC | — | 0 violations ✅ |

---

### Timing of Pre vs Post Routing 

| Stage | WNS | Hold WNS | TNS | Status |
|-------|-----|----------|-----|--------|
| Pre-route | +4.14 ns | +0.35 ns | 0.0 | ✅ |
| Post-route | +3.37 ns | +0.33 ns | 0.0 | ✅ |
| Post-RC (SPEF) | +4.09 ns | +0.33 ns | 0.0 | ✅ |

---

## 🔋 IR Drop & Electromigration (EMIR) Analysis

### IR Drop Analysis (VDD Network)

```
Tool    : OpenROAD PSM (Power Static Margin)
Net     : VDD
Voltage : 1.800 V nominal
```

| Metric | Value | Status |
|--------|-------|--------|
| **Supply Voltage** | 1.800 V | — |
| **Maximum Voltage** | 1.79972 V | — |
| **Minimum Voltage** | 1.79897 V | — |
| **Average Voltage** | 1.79942 V | — |
| **Maximum IR Drop** | 1.030 mV | ✅ < 10% VDD |
| **Average IR Drop** | 0.579 mV | ✅ Excellent |
| **Max Drop %** | 0.057% | ✅ Well within limit |

**Key observation:**
> Maximum IR drop of **1.03 mV** is only **0.057%** of VDD (1.8V)  
> Industry limit is typically 5-10% of VDD = 90-180 mV  
> Our design is **87× better** than the limit ✅

---

### Electromigration (EM) Analysis (VDD Network)

```
Tool    : OpenROAD PSM
Net     : VDD
Segments analyzed : 596 total, 515 active
```

| Metric | Value |
|--------|-------|
| **Total PDN segments** | 596 |
| **Active segments** | 515 |
| **Maximum current** | 0.446 mA |
| **Average current** | 0.026 mA |

**Key observation:**
> Maximum segment current = **0.446 mA**  
> Sky130 met4 EM limit ≈ 4-5 mA for 0.48µm width  
> Our design is well within EM limits ✅

---

### EMIR Summary

| Check | Result | Limit | Status |
|-------|--------|-------|--------|
| IR Drop (max) | 1.03 mV | 90 mV (5%) | ✅ PASS |
| IR Drop (avg) | 0.58 mV | — | ✅ PASS |
| EM (max current) | 0.446 mA | ~4 mA | ✅ PASS |

---

#### Sign-off Checklist

| Check | Result |
|-------|--------|
| DRC (OpenROAD) | ✅ 0 violations |
| Antenna Check | ✅ 0 violations |
| RC Extraction | ✅ 333KB SPEF |
| IR Drop | ✅ Analyzed |
| Electromigration | ✅ Analyzed |
| ERC (Power Grid) | ✅ PDN fully connected |
| Metal Density | ✅ Analyzed |
| Fill Insertion | ✅ 921 cells |

---
### PVT Corner Sign-off STA

| Corner | Condition | Setup WNS | Hold WNS | Status |
|--------|-----------|-----------|----------|--------|
| TT | 25°C, 1.80V | +4.09 ns | +0.33 ns | ✅ |
| SS | 100°C, 1.60V | +1.33 ns | +0.68 ns | ✅ |
| FF | -40°C, 1.95V | +5.10 ns | +0.20 ns | ✅ |
---
## 📈 Visualizations

---

## 📈 Physical Design Visualizations

| Step 1 — Floorplan | Step 2 — IO Pin Placement |
|---------------------|--------------------------|
| Die: 120×120 µm, 40 cell rows | 24 pins on chip boundary |
| ![Floorplan](Picture/viz_step1_floorplan.png) | ![IO Pins](Picture/viz_step2_pins.png) |

| Step 3 — PDN | Step 4 — Global Placement |
|--------------|--------------------------|
| met1+met4+met5 power grid | 417 cells roughly placed |
| ![PDN](Picture/viz_step3_pdn.png) | ![Global Placement](Picture/viz_step4_placement.png) |

| Step 5 — Detailed Placement | Step 6 — CTS |
|-----------------------------|--------------|
| 417 cells legally in rows, 0 overlaps | wr_clk(17 bufs) + rd_clk(3 bufs) |
| ![Detailed Placement](Picture/viz_step5_detailed.png) | ![CTS](Picture/viz_step6_cts.png) |

| Step 7 — Global Routing | Step 8 — Detailed Routing |
|-------------------------|--------------------------|
| 791 met1 + 188 met2 + 90 met3 segs | 1594 → 0 DRC violations |
| ![Global Routing](Picture/viz_step7_routing.png) | ![Detailed Route](Picture/Screenshot_2.png) |

| Step 9 — Final GDS (with Fill) | Clock Tree |
|--------------------------------|------------|
| 921 fill cells — final layout | Blue=wr_clk, Red=rd_clk, Green=bufs |
| ![Final GDS](Picture/Screenshot_3.png) | ![Clock Tree](Picture/clock_tree_1.png) |

| Netlist Analysis | RTL Schematic |
|-----------------|---------------|
| Cell type distribution | Gate-level Yosys schematic |
| ![Netlist](Results/netlist_analysis.png) | ![Schematic](Results/schematic.png) |

---

## 🛠️ Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| **Yosys** | 0.x | Logic Synthesis |
| **OpenROAD** | 2.0 | Physical Design (PnR) |
| **TritonCTS** | — | Clock Tree Synthesis |
| **TritonRoute** | — | Detailed Routing |
| **OpenRCX** | — | RC Parasitic Extraction |
| **OpenSTA** | — | Static Timing Analysis |
| **KLayout** | 0.28.16 | Layout Visualization |
| **Python/Matplotlib** | 3.x | Result Visualization |

---

## 📦 PDK

| Item | Value |
|------|-------|
| **PDK** | SkyWater 130nm (sky130A) |
| **Standard Cell Library** | sky130_fd_sc_hd (High Density) |
| **Liberty (TT)** | sky130_fd_sc_hd__tt_025C_1v80.lib |
| **Liberty (SS)** | sky130_fd_sc_hd__ss_100C_1v60.lib |
| **Liberty (FF)** | sky130_fd_sc_hd__ff_n40C_1v95.lib |

---

## 📁 Project Structure

```
async_fifo_pd/
├── rtl/
│   └── async_fifo.v                      ← RTL design
├── netlist/
│   └── async_fifo_netlist.v              ← Synthesized netlist
├── results/
│   ├── step1_floorplan.def + .gds        ← Floorplan
│   ├── step2_pins.def + .gds             ← IO Pin Placement
│   ├── step3_pdn.def + .gds              ← Power Distribution Network
│   ├── step4_placement.def + .gds        ← Global Placement
│   ├── step5_detailed.def + .gds         ← Detailed Placement
│   ├── step6_cts.def + .gds              ← Clock Tree Synthesis
│   ├── step7_routed.def + .gds           ← Global Routing
│   ├── step8_detailed_route.def + .gds   ← Detailed Routing
│   ├── step9_fill.def                    ← Fill Insertion
│   ├── async_fifo.spef                   ← RC Parasitics
│   ├── pvt_sta.rpt                       ← PVT Timing Sign-off
│   ├── power.rpt                         ← Power Analysis
│   ├── antenna.rpt                       ← Antenna Check
│   ├── ir_drop_vdd.rpt                   ← IR Drop
│   ├── em_vdd.rpt                        ← Electromigration
│   └── density.rpt                       ← Metal Density
├── logs/
│   ├── synth.log                         ← Yosys Synthesis Log
│   ├── openroad_final.log                ← OpenROAD PnR Log
│   ├── rcx.log                           ← RC Extraction Log
│   └── pvt_sta.log                       ← PVT STA Log
├── async_fifo.sdc                        ← Timing Constraints
├── synth.ys                              ← Yosys Script
└── flow.tcl                              ← OpenROAD Flow Script
```
---

## 🚀 How to Reproduce

### Prerequisites
- Ubuntu 20.04/22.04/24.04 (or WSL2)
- Yosys
- OpenROAD (via mamba)
- Sky130 PDK (via volare)

### Setup
```bash
# Install mamba
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p ~/miniforge3
source ~/miniforge3/bin/activate

# Install OpenROAD
mamba create -n openroad_env python=3.7 -y
mamba activate openroad_env
mamba install -y -c litex-hub -c conda-forge openroad

# Install Sky130 PDK
pip install volare
volare fetch --pdk sky130 --pdk-root ~/eda_tools/pdks cd1748bb197f9b7af62a54507de6624e30363943
volare enable --pdk sky130 --pdk-root ~/eda_tools/pdks cd1748bb197f9b7af62a54507de6624e30363943
```

### Run Flow
```bash
# Synthesis
yosys -l logs/synth.log synth.ys

# Physical Design
openroad -no_splash -exit flow.tcl
```

---

## 🏷️ Skills

`OpenROAD` `Yosys` `SkyWater 130nm` `Physical Design` `Floorplanning`
`Placement & Routing` `Clock Tree Synthesis` `Static Timing Analysis`
`RC Extraction` `SPEF` `Antenna Check` `IR Drop` `Electromigration`
`Clock Domain Crossing (CDC)` `Gray-code Synchronizer` `Asynchronous FIFO`
`RTL Design` `Verilog` `EDA` `WSL2` `KLayout`

---

## 📚 References

1. Cliff Cummings, "Simulation and Synthesis Techniques for Asynchronous FIFO Design", SNUG 2002
2. SkyWater SKY130 PDK Documentation 
3. OpenROAD Project Documentation

---

⭐ **If you find this project helpful, please star the repo!**


