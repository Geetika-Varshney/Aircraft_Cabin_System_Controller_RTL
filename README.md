# Aircraft Cabin System Controller (RTL Verilog)

An RTL-based aircraft cabin control system designed and verified in Vivado using Verilog and SystemVerilog.

## Overview
This project models how aircraft cabin systems are managed across different flight phases using deterministic control logic.

The design uses:
- Moore finite state machines for control
- Counters with enable/hold behavior for timing
- Registers for command sampling
- Simulation-based verification (no physical FPGA required)

## Features
- Flight phase–based cabin control (ground, taxi, takeoff, cruise, landing)
- Command gating based on safety rules
- Timed transitions using counters
- Maintenance freeze mode
- Fault-safe behavior with emergency overrides
- Fully verified via waveform analysis

## Project Structure
- src/
- sequential/ Flip-flops, registers, command latching
- counters/ Timing and stabilization counters
- fsm/ Moore finite state machine
- top/ Top-level system integration

- tb/
- tb_cabin_system.sv System-level testbench

- waveforms/
- Simulation screenshots and verification evidence

---

##  How to Run the Simulation
1. Open the project in **Vivado**
2. Set `cabin_system_top.v` as the **Design Top**
3. Set `tb_cabin_system.sv` as the **Simulation Top**
4. Run **Behavioral Simulation**
5. Inspect waveforms to observe state transitions, timing delays, and safety behavior

---

##  Tools Used
- Xilinx Vivado (Simulation)
- Verilog / SystemVerilog
- RTL-based design and verification methodology

---

##  Author
Geetika Varshney
