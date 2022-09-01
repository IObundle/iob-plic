//instantiate core in system

   //
   // CLINT
   //

   iob_plic plic
     (
      .clk     (clk),
      .rst     (reset),

      .plic_req  (slaves_req),
      .plic_resp (slaves_resp),

      .meip               (externalInterrupt),
      .externalInterrupts (8'h00)
      );
