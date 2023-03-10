//instantiate core in system

   //
   // PLIC
   //

   iob_plic #(
      .SOURCES(`N_SOURCES), //Number of interrupt sources
      .TARGETS(`N_TARGETS)   //Number of interrupt targets
    ) plic
    (
      .clk     (clk),
      .rst     (cpu_reset),

      .valid   (slaves_req[`valid(`PLIC)]),
      .address (slaves_req[`address(`PLIC, 16)]),
      .wdata   (slaves_req[`wdata(`PLIC)]),
      .wstrb   (slaves_req[`wstrb(`PLIC)]),
      .rdata   (slaves_resp[`rdata(`PLIC)]),
      .ready   (slaves_resp[`ready(`PLIC)]),

      .src     (IOb_Interrupts),
      .irq     (External_Interrupts)
      );
