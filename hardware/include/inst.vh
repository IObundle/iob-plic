//instantiate core in system

   //
   // PLIC
   //

   iob_plic #(
      .TARGETS(`N_CORES)   //Number of interrupt targets
    ) plic
    (
      .clk     (clk),
      .rst     (reset),

      .valid   (slaves_req[`valid(`PLIC)]),
      .address (slaves_req[`address(`PLIC, `iob_plic_ADDR_W)]),
      .wdata   (slaves_req[`wdata(`PLIC)]),
      .wstrb   (slaves_req[`wstrb(`PLIC)]),
      .rdata   (slaves_resp[`rdata(`PLIC)]),
      .ready   (slaves_resp[`ready(`PLIC)]),

      .src     ({{SOURCES-1}1'b0}),
      .irq     (externalInterrupt)
      );
