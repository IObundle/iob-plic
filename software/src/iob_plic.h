#pragma once

#define DATA_W 32

#ifndef N_SOURCES
#define N_SOURCES 31
#endif

#ifndef N_TARGETS
#define N_TARGETS 1
#endif

#define PRIORITY_BITS 3 //$clog2(PRIORITIES); PRIORITIES = 8;
#define HAS_THRESHOLD 1
#define HAS_CONFIG_REG 1
// Configuration Bits
#define MAX_SOURCES_BITS 16
#define MAX_TARGETS_BITS 16
#define MAX_PRIORITY_BITS MAX_SOURCES_BITS
#define HAS_THRESHOLD_BITS 1
// How many CONFIG registers are there (only 1)
#define CONFIG_REGS                                                            \
  (HAS_CONFIG_REG == 0                                                         \
       ? 0                                                                     \
       : ((MAX_SOURCES_BITS + MAX_TARGETS_BITS + MAX_PRIORITY_BITS +           \
           HAS_THRESHOLD_BITS + DATA_W - 1) /                                  \
          DATA_W))
// Amount of Edge/Level registers
#define EDGE_LEVEL_REGS ((N_SOURCES + DATA_W - 1) / DATA_W)
// Amount of Interrupt Enable registers
#define IE_REGS (EDGE_LEVEL_REGS * N_TARGETS)
// Each PRIORITY field starts at a new nibble boundary
// Get the number of nibbles in 'PRIORITY_BITS' ?
#define PRIORITY_NIBBLES ((PRIORITY_BITS + 3 - 1) / 4)
// How many PRIORITY fields fit in 1 register?
#define PRIORITY_FIELDS_PER_REG (DATA_W / (PRIORITY_NIBBLES * 4))
// Amount of Priority registers
#define PRIORITY_REGS                                                          \
  ((N_SOURCES + PRIORITY_FIELDS_PER_REG - 1) / PRIORITY_FIELDS_PER_REG)
// Amount of Threshold registers
#define PTHRESHOLD_REGS (HAS_THRESHOLD == 0 ? 0 : N_TARGETS)
// Amount of ID registers
#define ID_REGS N_TARGETS
// Total amount of registers
#define TOTAL_REGS                                                             \
  (CONFIG_REGS + EDGE_LEVEL_REGS + IE_REGS + PRIORITY_REGS + PTHRESHOLD_REGS + \
   ID_REGS)

// Set base register addresses ...
#define EL_BASE_ADDRESS CONFIG_REGS
#define PR_BASE_ADDRESS (EL_BASE_ADDRESS + EDGE_LEVEL_REGS)
#define IE_BASE_ADDRESS (PR_BASE_ADDRESS + PRIORITY_REGS)
#define TH_BASE_ADDRESS (IE_BASE_ADDRESS + IE_REGS)
#define ID_BASE_ADDRESS (TH_BASE_ADDRESS + PTHRESHOLD_REGS)

// Functions
static int base;

/**
 * @brief Initializes the PLIC peripheral.
 *
 * This function sets the base address, clears Edge/Level (EL) registers,
 * sets default priorities for all sources, clears Interrupt Enable (IE)
 * registers, and sets thresholds to zero.
 *
 * @param base_address The base memory address of the PLIC.
 */
void plic_init(int base_address);

/**
 * @brief Writes a 32-bit value to a PLIC register.
 *
 * @param address The offset from the PLIC base address.
 * @param data The 32-bit data to write.
 */
void plic_write(int address, int data);

/**
 * @brief Reads a 32-bit value from a PLIC register.
 *
 * @param address The offset from the PLIC base address.
 * @return int The 32-bit value read from the register.
 */
int plic_read(int address);

/**
 * @brief Enables a specific interrupt source for the current hart.
 *
 * @param source The ID of the interrupt source to enable.
 * @return int The hart ID (target) for which the interrupt was enabled.
 */
int plic_enable_interrupt(int source);

/**
 * @brief Disables a specific interrupt source for the current hart.
 *
 * @param source The ID of the interrupt source to disable.
 * @return int The hart ID (target) for which the interrupt was disabled.
 */
int plic_disable_interrupt(int source);

/**
 * @brief Claims an interrupt from the PLIC for the current hart.
 *
 * This should be called inside the ISR to identify the highest priority
 * pending interrupt.
 *
 * @return int The ID of the claimed interrupt source.
 */
int plic_claim_interrupt();

/**
 * @brief Signals the completion of an interrupt to the PLIC.
 *
 * This should be called after handling a claimed interrupt to allow
 * the PLIC to dispatch new interrupts from the same source.
 *
 * @param source_id The ID of the interrupt source that was handled.
 */
void plic_complete_interrupt(int source_id);

/**
 * @brief Helper function to calculate the default priority register value.
 *
 * Constructs a word where each priority field is set to 1.
 *
 * @return int The packed priority value for a register.
 */
int write_pr_regs();
