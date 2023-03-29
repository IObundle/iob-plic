# IOb-SoC Platform-Level Interrupt Controller (PLIC)

## Overview

This Core is an adaptation of the fully parameterized & programmable Platform Level Interrupt Controller (PLIC), developed by RoaLogic, for RISC-V based Processor Systems supporting a user-defined number of interrupt sources and targets. From RoaLogic this IP contains the PLIC core system verilog files. Besides that it has a verilog wrapper that initializes the PLIC core, the PLIC registers and creates the interface with the iob-soc internal buses. Furthermore, in hardware/include directory can be found the files that allow for the integration of the iob-plic has one of iob-soc peripherals.
 
The core supports a programmable number of simultaneous pending interrupt requests per source and individual routing of those interrupt requests to each target, full interrupt prioritisation of each interrupt source and separate enables per target via a matrix of interrupt enable bits.

To reduce latency, the PLIC core presents all asserted interrupts to the target in priority order, queuing them so that a software interrupt handler can service all pending interrupts without the need to restore the interrupted context.

## How to build the core w/ python-setup
The python-setup workflow allows to automatically generate verilog components used by the projects core Verilog. It allows to create bus interfaces with ease and use existing Verilog modules. To use python-setup the project should have a *project*_setup.py file in the root directory. The main commands to use the python-setup workflow are:
- `make setup`: creates a build directory in the projects parent directory.
- `make clean`: removes the build directory.

An example of cleaning a previous build, creating a new build and simulating the project is:
- `make clean && make setup && make -C ../iob_clint_V0.10 sim-run`

## Documentation


## Features

- User defined number of Interrupt Sources & Targets
- User defined priority level per Interrupt Source
- Interrupt masking per target via Priority Threshold support
- User defined Interrupt Pending queue depth per source

## Compatibility

Compliant to the [RISC-V Privilege Level 1.9, 1.9.1, 1.10 specifications](https://github.com/riscv/riscv-isa-manual/releases/tag/archive)

## Interfaces

- Dynamic Registers

The PLIC core implements Dynamic Registers, which means the registers and register mapping are automatically generated based on the parameters provided to the core. The core prints the register mapping during simulation (and for some tools during synthesis).

## License

Released under the RoaLogic [BSD License](/LICENSE.md)

## References

-  RoaLogic plic : https://github.com/RoaLogic/plic