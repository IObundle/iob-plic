#pragma once

#include <stdint.h>

#define PLIC_N_SOURCES 31
#define PLIC_N_TARGETS 2

// SiFive PLIC Offsets
#define PLIC_PRIORITY_BASE      0x000000
#define PLIC_PENDING_BASE       0x001000
#define PLIC_ENABLE_BASE        0x002000
#define PLIC_THRESHOLD_BASE     0x200000
#define PLIC_CLAIM_BASE         0x200004

// Stride/Spacing:
// - targetEnableShift=7 (1 << 7 = 128 bytes)
// - targetThresholdShift=12 (1 << 12 = 4096 bytes)
#define PLIC_ENABLE_STRIDE      0x80    
#define PLIC_CONTEXT_STRIDE     0x1000  

static uint32_t plic_base_addr;

/**
 * @brief Initializes the PLIC peripheral for all targets.
 * 
 * @param base_address The base memory address of the PLIC.
 */
void plic_init(uint32_t base_address);

/**
 * @brief Writes a 32-bit value to a PLIC register.
 * 
 * @param address Offset from the PLIC base address.
 * @param data 32-bit data to write.
 */
void plic_write(uint32_t address, uint32_t data);

/**
 * @brief Reads a 32-bit value from a PLIC register.
 * 
 * @param address Offset from the PLIC base address.
 * @return uint32_t 32-bit value read from the register.
 */
uint32_t plic_read(uint32_t address);

/**
 * @brief Sets the priority for a specific interrupt source.
 * 
 * @param source Interrupt source ID (1 to 31).
 * @param priority Priority level (0=disabled, >0=active).
 */
void plic_set_priority(int source, int priority);

/**
 * @brief Sets the interrupt priority threshold for a specific target.
 * 
 * @param target Target index (0 for Machine, 1 for Supervisor).
 * @param threshold Only interrupts with priority > threshold will be triggered.
 */
void plic_set_threshold(int target, int threshold);

/**
 * @brief Enables a specific interrupt source for a target.
 * 
 * @param target Target index (0 for Machine, 1 for Supervisor).
 * @param source Interrupt source ID (1 to 31).
 */
void plic_enable_interrupt(int target, int source);

/**
 * @brief Disables a specific interrupt source for a target.
 * 
 * @param target Target index (0 for Machine, 1 for Supervisor).
 * @param source Interrupt source ID (1 to 31).
 */
void plic_disable_interrupt(int target, int source);

/**
 * @brief Claims an interrupt for the specified target.
 * 
 * @param target Target index (0 for Machine, 1 for Supervisor).
 * @return uint32_t The ID of the highest priority pending interrupt.
 */
uint32_t plic_claim_interrupt(int target);

/**
 * @brief Signals completion of an interrupt handling to the PLIC.
 * 
 * @param target Target index (0 for Machine, 1 for Supervisor).
 * @param source_id The ID of the interrupt source that was handled.
 */
void plic_complete_interrupt(int target, int source_id);
