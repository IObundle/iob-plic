# PLIC (Platform-Level Interrupt Controller) Guide

A PLIC acts as a central hub that aggregates many interrupt sources (from peripherals) and routes them to specific "targets" (processor contexts).

## 1. How the PLIC Works (The Pipeline)

The PLIC processes interrupts through three main stages:

1.  **Gateway:** Each peripheral connects to a Gateway. The Gateway manages the arrival of the signal (e.g., edge-triggered or level-triggered) and sets a "Pending" bit. It won't accept another interrupt from that same source until the current one is serviced.
2.  **Enable & Priority:** For every source, the PLIC checks:
    *   Is this interrupt **Enabled** for the specific target?
    *   What is its **Priority** level? (Higher number = higher priority).
3.  **Target Arbitration:** The PLIC compares the highest priority pending interrupt against the target's **Threshold**. If the interrupt's priority is strictly greater than the threshold, the PLIC pulls the external interrupt line of that target (e.g., the MEIP or SEIP pin on a RISC-V Hart).

---

## 2. What are PLIC "Targets"?

In RISC-V terminology, a **Target** is a specific privilege context on a specific Hart (Hardware Thread/Core).

A single physical Core (Hart 0) usually has multiple targets:
*   **Target 0:** Hart 0, Machine Mode (M-Mode)
*   **Target 1:** Hart 0, Supervisor Mode (S-Mode) — *This is where Linux lives.*

If you have a 4-core system, you might have 8 targets (4 M-mode, 4 S-mode). Each target has its own unique set of Enable bits, Threshold, and Claim/Complete registers, allowing the OS to manage interrupts independently for each core.

---

## 3. How the Linux Driver Interacts with it

The Linux PLIC driver (usually `drivers/irqchip/irq-riscv-plic.c`) interacts with the core via memory-mapped I/O (MMIO) following this lifecycle:

1.  **Initialization:** The driver reads the Device Tree to find the PLIC's base address. It sets the Priority for each source and sets the Threshold for the local CPU's S-mode target (usually to 0 to allow all interrupts).
2.  **Enablement:** When a driver (like a UART driver) requests an IRQ, the PLIC driver sets the corresponding bit in that CPU's Enable register array.
3.  **The "Claim" (Interrupt Arrival):**
    *   When an interrupt occurs, the CPU jumps to the trap handler.
    *   The Linux driver reads the **Claim** register.
    *   **The Magic:** Reading this register returns the ID of the highest priority pending interrupt and automatically clears the "Pending" bit in the PLIC for that source.
4.  **Servicing:** Linux executes the specific ISR (Interrupt Service Routine) for that ID.
5.  **The "Complete":** Once the ISR is done, the driver writes the ID back into the **Claim/Complete** register. This signals the PLIC Gateway that it can now accept new interrupts from that peripheral.

### Summary for your SoC
Since you generated a core with 2 targets, you likely intended to support:
*   **Target 0:** Core 0 M-Mode (for bootloaders/firmware).
*   **Target 1:** Core 0 S-Mode (for Linux).

When you write your Device Tree, you will map these targets to the `interrupts-extended` property of the CPU nodes so Linux knows which MMIO region belongs to which core.

---

## Target Mapping & Register Offsets

In a standard Linux-compatible RISC-V SoC (following the SiFive/RISC-V PLIC specification), the "Targets" (often called "Contexts") are mapped to the privilege modes of the CPU cores.

For your configuration with `targetCount = 2` on a single-core system:

*   **io_targets[0] (Target 0 / Context 0):** Machine Mode External Interrupt (MEIP).
    *   This is typically handled by the firmware (e.g., OpenSBI or BBL).
*   **io_targets[1] (Target 1 / Context 1):** Supervisor Mode External Interrupt (SEIP).
    *   This is the signal Linux will use to receive and manage interrupts.

### Address Mapping for these Modes
The memory offsets for the registers change based on the target index:

| Register           | Machine Mode (Target 0) | Supervisor Mode (Target 1) |
| :----------------- | :---------------------- | :------------------------- |
| Interrupt Enables  | `0x002000`              | `0x002080`                 |
| Priority Threshold | `0x200000`              | `0x201000`                 |
| Claim / Complete   | `0x200004`              | `0x201004`                 |

### Device Tree Integration
To ensure Linux recognizes this mapping, your Device Tree (`.dts`) should specify the interrupts for the CPU core as follows:

```dts
plic0: interrupt-controller@40000000 {
    compatible = "sifive,plic-1.0.0";
    #interrupt-cells = <1>;
    interrupt-controller;
    interrupts-extended = <&cpu0_intc 11 &cpu0_intc 9>;
    reg = <0x0 0x40000000 0x0 0x400000>;
    riscv,ndev = <31>;
};
```

In `interrupts-extended`:
*   `11` corresponds to Machine External Interrupt (connected to `io_targets[0]`).
*   `9` corresponds to Supervisor External Interrupt (connected to `io_targets[1]`).

> **Note:** If you are building a multi-core SoC where Linux runs only in S-mode across multiple Harts, you would need to increase `targetCount` to `2 * num_cores` and map them accordingly (Target 0=H0-M, 1=H0-S, 2=H1-M, 3=H1-S, etc.).
