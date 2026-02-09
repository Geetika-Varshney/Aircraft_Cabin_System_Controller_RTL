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
