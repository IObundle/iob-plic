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

---

# PLIC, Linux `irq-sifive-plic`, and OpenSBI Interaction Guide

## 1. Overview of OpenSBI on RISC‑V

OpenSBI (RISC‑V Open Source Supervisor Binary Interface) is the standard firmware layer that sits below the operating system on RISC‑V platforms. Its main job is to:

- Provide a **hardware‑abstraction layer** between the RISC‑V platform and the OS (Linux, Zephyr, etc.).
- Implement the **RISC‑V SBI specification**, including:
  - Machine‑timer setup (`sbi_set_timer`).
  - Inter‑processor interrupts (IPIs) via `sbi_send_ipi`.
  - CPU‑management functions (start/stop/suspend).
  - System‑reset and other platform services.
- Handle **boot‑time platform initialization** (e.g., PLIC, CLINT, UART).
- **Not** expose arbitrary “peripheral‑control ecalls”; instead it focuses on **CPU‑centric services**, leaving most device drivers (UART, PLIC, GPIO, etc.) to live either in Linux itself or in platform‑specific firmware hooks.

In other words, **OpenSBI touches peripherals only to the extent needed to set up time, interrupts, console, and boot flow**, not as a general device‑driver API.

---

## 2. The PLIC in RISC‑V

The **Platform‑Level Interrupt Controller (PLIC)** is a memory‑mapped interrupt controller shared by all harts (CPUs) on a RISC‑V SoC. It:

- Has multiple **interrupt sources** (devices: UART, timer, GPIO, Ethernet, etc.).
- Has multiple **interrupt contexts** (one per hart per mode: often M‑context and S‑context for each CPU).
- Each context exposes:
  - `enable[N]` registers (enable/disable sources for that context).
  - `priority[N]` (source priorities).
  - `threshold` (minimum priority to deliver).
  - `claim` / `complete` (take and ack an interrupt).

External device interrupts can be routed to:

- **M‑mode** (machine‑mode context, handled by firmware such as OpenSBI).
- **S‑mode** (supervisor‑mode context, handled by Linux via `irq-sifive-plic`).

---

## 3. OpenSBI’s PLIC driver

OpenSBI includes a **generic PLIC driver** that:

- **Discovers** the PLIC base address from the device tree (if `FDT` is enabled).
- **Writes PLIC‑specific registers** once at boot:
  - Enables external interrupt sources for the contexts it wants to use.
  - Sets initial thresholds and clears any pending interrupts.
- **Handles M‑context PLIC IRQs**:
  - If external interrupts are delivered to M‑mode (e.g., MEIP), OpenSBI runs the trap handler in M‑mode.
  - OpenSBI can:
    - Handle firmware‑internal IRQs (e.g., low‑level platform events).
    - Delegate or forward certain IRQs into S‑mode if the platform uses `mideleg` for SEIP.
- **Does not** normally expose PLIC‑source IRQs to Linux as a Linux‑level IRQchip; instead it prepares the PLIC so that Linux’s `irq-sifive-plic` can safely take over.

In short: **OpenSBI’s PLIC role is initialization and M‑mode handling**, not per‑device IRQ dispatch.

---

## 4. Linux `irq-sifive-plic` driver

Linux’s `irq-sifive-plic.c` is the **S‑mode PLIC IRQchip driver**. It:

- **Uses the device tree** PLIC node and `interrupts-extended` to know which PLIC context corresponds to each CPU’s **S‑mode**:
  ```dts
  interrupts-extended = < &CPU0_intc 11 &CPU0_intc 9 >;
  ```
  - `11` → PLIC line 11 wired to **MEIP** (M‑mode).
  - `9` → PLIC line 9 wired to **SEIP** (S‑mode).
- **Ignores the M‑mode entries** (e.g., `11`) for its IRQ‑routing logic.
- **Uses the S‑mode entries** (e.g., `9`) to:
  - Determine which **PLIC context** (offsets in the PLIC register map) belongs to that CPU’s S‑mode.
  - Read/write `enable`, `threshold`, `claim`, and `complete` for that S‑context.
- **Exposes device IRQs** to Linux IRQ numbers, so UART, timer, Ethernet, etc., can register normal Linux IRQ handlers.

Under a typical OpenSBI + Linux stack, **Linux never sees PLIC IRQs delivered to M‑mode**; it only sees those delivered to S‑mode contexts, and the PLIC driver is solely responsible for them.

---

## 5. End‑to‑end flow (M‑mode vs S‑mode IRQs)

### Case A: M‑mode PLIC interrupt

- An external device triggers an interrupt routed to the **M‑context** of a hart.
- The CPU raises **MEIP**, enters **M‑mode trap**.
- **OpenSBI’s PLIC handler**:
  - Reads PLIC `claim` in the M‑context.
  - Handles or forwards the event (e.g., platform firmware, logging, or delegation).
- **Linux never sees this IRQ** as a standard device IRQ.

### Case B: S‑mode PLIC interrupt

- Device interrupt is routed to the **S‑context** of a hart.
- `mideleg.SEIP = 1` so SEIP is delivered to **S‑mode**.
- CPU jumps to **Linux S‑mode trap**.
- Linux’s `irq-sifive-plic` driver:
  - Reads `claim` from the S‑context.
  - Maps the source number to a Linux IRQ.
  - Invokes the device driver’s IRQ handler.
- **OpenSBI is not involved** per‑IRQ; it only did the one‑time setup (PLIC, `mideleg`, SBI timer/IPI).

---

## 6. Practical takeaway

- **OpenSBI**: firmware‑level PLIC initialization and M‑mode IRQ handling.
- **`irq-sifive-plic`**: Linux‑level S‑mode IRQ dispatch; it uses `interrupts-extended` to know which PLIC context is S‑mode, and ignores M‑mode context mappings for normal device IRQs.
- **Peripherals**: remain controlled by device‑specific drivers in Linux or firmware; SBI is CPU‑centric and does not expose generic “UART‑/GPIO‑control ecalls” for arbitrary devices.
