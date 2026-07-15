/*
 * SPDX-FileCopyrightText: 2026 IObundle
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

/* PC Emulation of PLIC peripheral */

#include <stdint.h>
#include <time.h>

#include "iob_plic_csrs.h"

static int base;
void iob_plic_csrs_init_baseaddr(uint32_t addr) {
  base = addr;
  return;
}

// Core Setters and Getters
void iob_plic_csrs_set_priority_csr(uint32_t value, int addr) {
  // Not implemented for PC emulation
  (void)value;
  (void)addr;
  return;
}

uint32_t iob_plic_csrs_get_priority_csr(int addr) {
  // Not implemented for PC emulation
  (void)addr;
  return 1;
}

uint32_t iob_plic_csrs_get_pending() {
  // Not implemented for PC emulation
  return 1;
}

void iob_plic_csrs_set_target0_enable(uint32_t value) {
  // Not implemented for PC emulation
  (void)value;
  return;
}

uint32_t iob_plic_csrs_get_target0_enable() {
  // Not implemented for PC emulation
  return 1;
}

void iob_plic_csrs_set_target1_enable(uint32_t value) {
  // Not implemented for PC emulation
  (void)value;
  return;
}

uint32_t iob_plic_csrs_get_target1_enable() {
  // Not implemented for PC emulation
  return 1;
}

void iob_plic_csrs_set_target0_threshold(uint8_t value) {
  // Not implemented for PC emulation
  (void)value;
  return;
}

uint8_t iob_plic_csrs_get_target0_threshold() {
  // Not implemented for PC emulation
  return 1;
}

void iob_plic_csrs_set_target0_claim_complete(uint8_t value) {
  // Not implemented for PC emulation
  (void)value;
  return;
}

uint8_t iob_plic_csrs_get_target0_claim_complete() {
  // Not implemented for PC emulation
  return 1;
}

void iob_plic_csrs_set_target1_threshold(uint8_t value) {
  // Not implemented for PC emulation
  (void)value;
  return;
}

uint8_t iob_plic_csrs_get_target1_threshold() {
  // Not implemented for PC emulation
  return 1;
}

void iob_plic_csrs_set_target1_claim_complete(uint8_t value) {
  // Not implemented for PC emulation
  (void)value;
  return;
}

uint8_t iob_plic_csrs_get_target1_claim_complete() {
  // Not implemented for PC emulation
  return 1;
}

uint32_t iob_plic_csrs_get_version() {
  // Not implemented for PC emulation
  return 1;
}
