# IOb RISC-V PLIC (Platform Level Interrupt Controller)

## Overview
This PLIC (Platform Level Interrupt Controller) core is a high-performance, parameterizable interrupt controller generated using **SpinalHDL** and **Py2HWSW**.
It aggregates multiple interrupt sources and routes them to processor "targets" (Harts/Privilege modes) based on priority and threshold levels.
This specific implementation is tailored for Linux-capable SoCs, like [SoCLinux](https://github.com/IObundle/soc-linux).

<!--
## How to build the core with Py2HWSW
The python-setup workflow allows to automatically generate verilog components used by the projects core Verilog. It allows to create bus interfaces with ease and use existing Verilog modules. To use python-setup the project should have a *project*_setup.py file in the root directory. The main commands to use the python-setup workflow are:
- `make setup`: creates a build directory in the projects parent directory.
- `make clean`: removes the build directory.

An example of cleaning a previous build, creating a new build and simulating the project is:
- `make clean && make setup && make -C ../iob_plic_V0.10 sim-run`

-->

## Documentation

A pre-built preliminary version of the IOb-PLIC user guide is available at [document/ug.pdf](document/ug.pdf).

A preliminary version of the IOb-PLIC user guide can be generated using the following command:

```bash
make doc-build
```

Generic information about PLICs and their integration with linux is available in the [GENERIC\_PLIC\_INFO.md](/GENERIC_PLIC_INFO.md).


## Features
- **31 Interrupt Sources:** Supports up to 31 unique external interrupt signals.
- **2 Targets:** Configured for a single-core system with two privilege contexts (e.g., M-Mode and S-Mode).
- **Programmable Priorities:** 2-bit priority width per interrupt source (Levels 0-3).
- **Per-Target Thresholds:** Allows masking of interrupts below a specific priority level for each target.
- **Claim/Complete Mechanism:** Atomic hardware-assisted interrupt identification and acknowledgement.
- **SiFive Register Map:** Fully compatible with the standard SiFive PLIC register layout used by the Linux kernel.

## Compatibility
- **Software:** Fully compatible with the standard RISC-V PLIC driver in the Linux kernel (`drivers/irqchip/irq-riscv-plic.c`).
- **Hardware:** Designed for integration into RISC-V systems (e.g., VexRiscv, Rocket, or custom cores).
- **OS Support:** Linux, FreeBSD, Zephyr, and various RTOS/Bare-metal environments.

## Interfaces
The core provides the following top-level interfaces in the generated Verilog:
- Clock, clock enable and reset interface.
- Interrupt sources interface.
- RISC-V interrupt interface.
- Control and status register interface.

More information about the interfaces can be found in the [IOb-PLIC user guide](document/ug.pdf).

### Memory Map (SiFive Compatible)
| Base Offset | Register Name | Description |
|-------------|---------------|-------------|
| `0x000000` | `priority` | Source priority (4 bytes per source) |
| `0x001000` | `pending` | Pending bit array (1 bit per source) |
| `0x002000` | `enable` | Target 0 enables (1 bit per source) |
| `0x002080` | `enable` | Target 1 enables (1 bit per source) |
| `0x200000` | `threshold` | Target 0 priority threshold |
| `0x200004` | `claim` | Target 0 claim/complete register |
| `0x201000` | `threshold` | Target 1 priority threshold |
| `0x201004` | `claim` | Target 1 claim/complete register |

## License
Released under [MIT](/LICENSE)

## References
- [RISC-V PLIC Specification](https://github.com/riscv/riscv-plic-spec)
- [SpinalHDL Documentation: PLIC](https://spinalhdl.github.io/SpinalDoc-RTD/master/SpinalHDL/Libraries/Misc/PLIC/plic_mapper.html)
- [SiFive Core Complex Manual (Reference Map)](https://sifive.cdn.prismic.io/sifive/9169d157-0d50-4005-a289-36c684de671b_e31_core_complex_manual_21G1.pdf)
