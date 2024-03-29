#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include "periphs.h"
#include "iob-uart.h"
#include "iob_plic.h"
#include "printf.h"

#include "riscv-csr.h"
#include "riscv-interrupts.h"

// Machine mode interrupt service routine
static void irq_entry(void) __attribute__ ((interrupt ("machine")));

// Global to hold current timestamp
static volatile uint64_t timestamp = 0;

int main() {
    //init uart
    uart_init(UART_BASE,FREQ/BAUD);
    plic_init(PLIC_BASE);

    printf("\n\n\nHello world!\n\n\n");

    // Global interrupt disable
    csr_clr_bits_mstatus(MSTATUS_MIE_BIT_MASK);
    csr_write_mie(0);
    csr_clr_bits_mcause(MCAUSE_INTERRUPT_ALL_SET_MASK);
    csr_write_mcause(0);

    // Setup the IRQ handler entry point
    csr_write_mtvec((uint_xlen_t) irq_entry);

    // Enable MIE.MEI
    csr_set_bits_mie(MIE_MEI_BIT_MASK);

    // Global interrupt enable
    csr_set_bits_mstatus(MSTATUS_MIE_BIT_MASK);
    
    // Enable PLIC interrupt for UART
    printf("Enabling external interrupt source 0 with ID = 1.\n");
    int target;
    target = plic_enable_interrupt(0);

    printf("Exit...\n");
    uart_finish();
    return 0;

}

#pragma GCC push_options
// Force the alignment for mtvec.BASE. A 'C' extension program could be aligned to to bytes.
#pragma GCC optimize ("align-functions=4")
static void irq_entry(void)  {
    printf("Entered IRQ.\n");
    uint_xlen_t this_cause = csr_read_mcause();
    if (this_cause &  MCAUSE_INTERRUPT_BIT_MASK) {
        this_cause &= 0xFF;
        // Known exceptions
        switch (this_cause) {
        case RISCV_INT_POS_MEI :
            printf("External interrupt.\n");
            int source_id = 0;
            source_id = plic_claim_interrupt();
            printf("External ID received was: %d.\n", source_id);
            plic_complete_interrupt(source_id);
            plic_disable_interrupt(source_id);
            break;
        }
    }
}
#pragma GCC pop_options
