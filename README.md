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

async_fifo (top)
├── Dual-port FIFO memory (16×8 flop array)
├── Write pointer (binary + Gray encoder)
├── Read pointer (binary + Gray encoder)
├── 2-FF synchronizer: wr_gray → rd_clk domain
├── 2-FF synchronizer: rd_gray → wr_clk domain
├── Full flag logic (write domain)
└── Empty flag logic (read domain)

### Module Hierarchy

### CDC Safety Mechanism

Write Domain          │          Read Domain
─────────────────────────────────────────────
wr_bin → b2g → wr_gray──[2FF sync]──▶ wg_s2
│
empty flag
rd_bin → b2g → rd_gray──[2FF sync]──▶ rg_s2
│
full flag

### Key RTL Features
- `(* ASYNC_REG = "TRUE" *)` on all synchronizer FFs
- Gray code: only 1 bit changes per increment → metastability safe
- Full detection: MSB pair inverted + lower bits equal
- Empty detection: Gray pointers match

---

## 🔄 Complete Physical Design Flow

async_fifo.v (RTL)
│
▼
[Yosys]
│ Logic Synthesis
▼
async_fifo_netlist.v
│
▼
[OpenROAD]
├── 1. Floorplan      → 120×120 µm die
├── 2. IO Placement   → 24 pins on boundary
├── 3. PDN            → met1+met4+met5 power grid
├── 4. Global Place   → NesterovSolve optimizer
├── 5. Detailed Place → Legal row placement
├── 6. CTS            → H-Tree, 2 domains
├── 7. Global Route   → GRT with congestion analysis
├── 8. Detailed Route → TritonRoute, 0 DRC violations
└── 9. Fill Insertion → 921 filler cells
│
▼
[OpenRCX]
│ RC Extraction
▼
async_fifo.spef (333KB)
│
▼
[OpenSTA]
│ Sign-off STA (TT/SS/FF corners)
▼
Sign-off Complete ✅


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

async_fifo_pd/
├── rtl/
│   └── async_fifo.v              ← RTL design
├── netlist/
│   └── async_fifo_netlist.v      ← Synthesized netlist
├── results/
│   ├── step1_floorplan.def/gds   ← Each PD stage
│   ├── step2_pins.def/gds
│   ├── step3_pdn.def/gds
│   ├── step4_placement.def/gds
│   ├── step5_detailed.def/gds
│   ├── step6_cts.def/gds
│   ├── step7_routed.def/gds
│   ├── step8_detailed_route.def/gds
│   ├── step9_fill.def
│   ├── async_fifo.spef           ← RC parasitics
│   ├── pvt_sta.rpt               ← PVT timing sign-off
│   ├── power.rpt                 ← Power analysis
│   ├── antenna.rpt               ← Antenna check
│   ├── ir_drop_vdd.rpt           ← IR drop
│   ├── em_vdd.rpt                ← Electromigration
│   └── density.rpt               ← Metal density
├── logs/
│   ├── synth.log                 ← Yosys synthesis log
│   ├── openroad_final.log        ← OpenROAD PnR log
│   ├── rcx.log                   ← RC extraction log
│   └── pvt_sta.log               ← PVT STA log
├── async_fifo.sdc                ← Timing constraints
├── synth.ys                      ← Yosys script
└── flow.tcl                      ← OpenROAD flow script

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

## 📄 CV Line

**Long:**
> Designed CDC-safe Asynchronous FIFO (8b×16d, Gray-code pointers, 2-FF synchronizers) through complete RTL-to-GDS flow using Yosys + OpenROAD on SkyWater 130nm HD PDK. Synthesis: 417 cells. Physical design: 6568 µm² core area (55% utilisation), CTS across 2 clock domains (wr_clk: 147 sinks, rd_clk: 19 sinks), detailed routing with 0 DRC violations, RC extraction (333KB SPEF). Sign-off: multi-corner PVT STA — TT WNS +4.09ns, SS WNS +1.33ns, FF WNS +5.10ns (all timing closed), power 1.10mW @ 100MHz, IR drop, EM, antenna check (0 violations), ERC, metal density analysis.

**Short:**
> • Async FIFO RTL-to-GDS | Sky130 130nm | 417 cells | 6568 µm² | 55% util | WNS +1.33ns (SS) | 1.10mW | 0 DRC | 0 antenna ✅

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


