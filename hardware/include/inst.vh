//instantiate core in system

   //
   // PLIC
   //

   iob_plic #(
      .SOURCES(32), //Number of interrupt sources
      .TARGETS(`N_CORES)   //Number of interrupt targets
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

      .src     ({1'b0, uartInterrupt, {30{1'b0}}}),
      .irq     (externalInterrupt)
      );
