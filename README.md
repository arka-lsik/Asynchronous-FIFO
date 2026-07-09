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

### Sign-off Results

#### Timing (PVT Corners)

| Corner | Condition | Setup WNS | Hold WNS | TNS | Status |
|--------|-----------|-----------|----------|-----|--------|
| **TT** | 25°C, 1.80V | +4.09 ns | +0.33 ns | 0.0 | ✅ PASS |
| **SS** | 100°C, 1.60V | +1.33 ns | +0.68 ns | 0.0 | ✅ PASS |
| **FF** | -40°C, 1.95V | +5.10 ns | +0.20 ns | 0.0 | ✅ PASS |

#### Power Analysis

| Component | Power |
|-----------|-------|
| Sequential | 0.739 mW (67%) |
| Combinational | 0.364 mW (33%) |
| **Total** | **1.10 mW @ 100MHz** |

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

## 🕰️ Clock Tree Synthesis

| Clock | Sinks | Buffers | Path Depth | Avg Wire Length |
|-------|-------|---------|------------|-----------------|
| **wr_clk** | 147 | 17 | 2-2 | 119.94 µm |
| **rd_clk** | 19 | 3 | 2-2 | 88.55 µm |

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

---

## 📈 Visualizations

### Step-by-Step Physical Design

| Step | View |
|------|------|
| Floorplan | ![Floorplan](Results/viz_step1_floorplan.png) |
| IO Pins | ![IO Pins](Results/viz_step2_pins.png) |
| PDN | ![PDN](Results/viz_step3_pdn.png) |
| Global Placement | ![Global Placement](Results/viz_step4_placement.png) |
| Detailed Placement | ![Detailed Placement](Results/viz_step5_detailed.png) |
| CTS | ![CTS](Results/viz_step6_cts.png) |
| Global Routing | ![Routing](Results/viz_step7_routing.png) |

---

---

## 📐 Floorplan Details

```
Die Area  : 120 × 120 µm  (120,000 × 120,000 nm)
Core Area : 109.94 × 108.80 µm
Core Origin: (5.06, 5.44) µm  ← snapped to site grid

Standard Cell Site : 0.46 µm wide × 2.72 µm tall
Total Rows         : 40 rows
Sites per Row      : 239 sites
Total Sites        : 40 × 239 = 9,560 available positions
Cells Placed       : 417 out of 9,560
Utilization        : 55%

IO Pins            : 24 pins placed on bottom edge
  - Write domain   : wr_clk, wr_rst_n, wr_en, wr_data[7:0]
  - Read domain    : rd_clk, rd_rst_n, rd_en, rd_data[7:0]
  - Status flags   : full, empty
```

---

## ⏱️ Timing Reports

### Pre-CTS Timing (Estimated Parasitics)

**Worst Setup Path (rd_clk domain):**
```
Startpoint : _614_/CLK  (FF clocked by rd_clk)
Endpoint   : rd_data[0] (output port)
Path Type  : max (setup check)

  Clock network delay   :  0.228 ns
  FF output delay       :  1.482 ns
  Mux4 delay            :  0.632 ns
  Mux4 delay            :  0.516 ns
  Output pin            :  0.001 ns
  ─────────────────────────────────
  Data arrival time     :  2.859 ns
  Data required time    :  7.000 ns  (10ns - 3ns output delay)
  ─────────────────────────────────
  Slack                 : +4.141 ns  ✅ MET
```

**Pre-CTS Summary:**

| Path Group | WNS | TNS | Status |
|------------|-----|-----|--------|
| rd_clk (setup) | +4.14 ns | 0.0 ns | ✅ MET |
| wr_clk (setup) | +5.60 ns | 0.0 ns | ✅ MET |
| rd_clk (hold)  | +0.35 ns | 0.0 ns | ✅ MET |
| wr_clk (hold)  | +0.33 ns | 0.0 ns | ✅ MET |

---

### Post-CTS Timing (Propagated Clock)

**Worst Setup Path (rd_clk domain):**
```
Startpoint : _614_/CLK  (FF clocked by rd_clk)
Endpoint   : rd_data[6] (output port)
Path Type  : max (setup check)

  Clock network delay   :  0.230 ns  (propagated through CTS buffers)
  FF output delay       :  1.613 ns
  Mux4 delay            :  1.239 ns  ← wire RC effect visible here
  Mux4 delay            :  0.545 ns
  Output pin            :  0.001 ns
  ─────────────────────────────────
  Data arrival time     :  3.628 ns
  Data required time    :  7.000 ns
  ─────────────────────────────────
  Slack                 : +3.372 ns  ✅ MET
```

**Pre vs Post CTS Comparison:**

| Metric | Pre-CTS | Post-CTS | Delta | Reason |
|--------|---------|----------|-------|--------|
| Clock delay | 0.228 ns | 0.230 ns | +0.002 ns | Real CTS buffer delay |
| FF delay | 1.482 ns | 1.613 ns | +0.131 ns | Output wire cap |
| Mux delay | 0.632 ns | 1.239 ns | +0.607 ns | Wire RC between muxes |
| **Total arrival** | **2.859 ns** | **3.628 ns** | **+0.769 ns** | Wire RC contribution |
| **WNS** | **+4.141 ns** | **+3.372 ns** | **-0.769 ns** | Still timing closed ✅ |

---

### Pre vs Post Routing Timing

| Stage | WNS (Setup) | WNS (Hold) | TNS | Status |
|-------|------------|------------|-----|--------|
| **Pre-route** (placement) | +4.141 ns | +0.347 ns | 0.0 | ✅ |
| **Post-route** (global route) | +3.372 ns | +0.332 ns | 0.0 | ✅ |
| **Post-RC** (extracted) | +4.087 ns | +0.332 ns | 0.0 | ✅ |

**Key observation:**
> Wire RC extraction actually improved WNS from +3.37ns to +4.09ns  
> This is because RC extraction gave more accurate (less pessimistic) wire models

---

### PVT Corner Sign-off

| Corner | Condition | Setup WNS | Hold WNS | TNS | Status |
|--------|-----------|-----------|----------|-----|--------|
| **TT** | 25°C, 1.80V | +4.09 ns | +0.33 ns | 0.0 | ✅ PASS |
| **SS** | 100°C, 1.60V | +1.33 ns | +0.68 ns | 0.0 | ✅ PASS |
| **FF** | -40°C, 1.95V | +5.10 ns | +0.20 ns | 0.0 | ✅ PASS |

> **SS corner is critical for setup** — slowest transistors, highest temp, lowest voltage  
> **FF corner is critical for hold** — fastest transistors, lowest temp, highest voltage  
> All corners pass both setup AND hold ✅

---

## 🔌 Global Routing Results

```
Tool            : OpenROAD GRT (Global Router)
Algorithm       : FastRoute
Layer adjustments:
  met1 : 0.65 (65% capacity reduction — congested layer)
  met2 : 0.65 (65% capacity reduction)

Routing guide file : results/route.guide

Routing segments per layer:
  met1 : 791 segments  (horizontal — most used)
  met2 : 188 segments  (vertical)
  met3 :  90 segments  (horizontal)
  met4 :   6 segments  (vertical — mostly power)
```

---

## 🔌 Detailed Routing Results

```
Tool       : TritonRoute (OpenROAD)
Algorithm  : Iterative rip-up and reroute

Iteration  Violations  Time
─────────────────────────────
    1         1594     1m 02s   ← initial rough routing
    2           25     0m 20s   ← major fixing (98% resolved)
    3           23     0m 12s   ← fine tuning
    4            0     0m 01s   ← ✅ all violations fixed
  5-8            0     0m 01s   ← verification passes

Final result   : 0 DRC violations ✅
Peak memory    : 525 MB
Total time     : ~1 min 37 sec

Layers used:
  li1   → Local interconnect (19,221 shapes)
  mcon  → Metal contact li1→met1 (11,687 shapes)
  met1  → Power rails + local routing (4,283 shapes)
  met2  → Signal routing (vertical)
  met3  → Signal routing (horizontal)
  met4  → Long routes + power stripes
  met5  → Power stripes only
```

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


