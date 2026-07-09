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
