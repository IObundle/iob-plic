#include "iob_plic.h"

void plic_init(uint32_t base_address) {
  plic_base_addr = base_address;

  // 1. Disable all interrupts for both targets (Machine and Supervisor)
  // There are PLIC_N_SOURCES interrupt sources. Enabling bits are packed in
  // 32-bit registers.
  for (int t = 0; t < PLIC_N_TARGETS; t++) {
    for (int i = 0; i <= (PLIC_N_SOURCES / 32); i++) {
      plic_write(PLIC_ENABLE_BASE + (t * PLIC_ENABLE_STRIDE) + (i * 4), 0);
    }
    // 2. Set thresholds to 0 (allow all priorities > 0)
    plic_set_threshold(t, 0);
  }

  // 3. Set priority of all sources to 1 (0 is disabled)
  // Source ID 0 is reserved/unused, priorities start from Source ID 1.
  for (int i = 1; i <= PLIC_N_SOURCES; i++) {
    plic_set_priority(i, 1);
  }
}

void plic_write(uint32_t address, uint32_t data) {
  (*(volatile uint32_t *)(plic_base_addr + address)) = data;
}

uint32_t plic_read(uint32_t address) {
  return (*(volatile uint32_t *)(plic_base_addr + address));
}

void plic_set_priority(int source, int priority) {
  // Each source priority is a 32-bit register at PLIC_PRIORITY_BASE + 4*ID
  plic_write(PLIC_PRIORITY_BASE + (source * 4), (uint32_t)priority);
}

void plic_set_threshold(int target, int threshold) {
  // Threshold register for each target context
  plic_write(PLIC_THRESHOLD_BASE + (target * PLIC_CONTEXT_STRIDE),
             (uint32_t)threshold);
}

void plic_enable_interrupt(int target, int source) {
  // Calculate register address and bit offset
  uint32_t addr =
      PLIC_ENABLE_BASE + (target * PLIC_ENABLE_STRIDE) + ((source / 32) * 4);
  uint32_t current = plic_read(addr);
  plic_write(addr, current | (1 << (source % 32)));
}

void plic_disable_interrupt(int target, int source) {
  uint32_t addr =
      PLIC_ENABLE_BASE + (target * PLIC_ENABLE_STRIDE) + ((source / 32) * 4);
  uint32_t current = plic_read(addr);
  plic_write(addr, current & ~(1 << (source % 32)));
}

uint32_t plic_claim_interrupt(int target) {
  // Reading the claim register returns the ID of the highest priority pending
  // interrupt
  return plic_read(PLIC_CLAIM_BASE + (target * PLIC_CONTEXT_STRIDE));
}

void plic_complete_interrupt(int target, int source_id) {
  // Writing the ID back to the same register signals completion
  plic_write(PLIC_CLAIM_BASE + (target * PLIC_CONTEXT_STRIDE),
             (uint32_t)source_id);
}
