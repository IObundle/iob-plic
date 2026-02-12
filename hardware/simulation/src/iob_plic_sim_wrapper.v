`timescale 1ns / 1ps

module iob_plic_sim_wrapper #(
   parameter ADDR_W    = 16,
   parameter DATA_W    = 32,
   parameter N_SOURCES = 8,
   parameter N_TARGETS = 2
) (
   `include "iob_plic_iob_clk_s_port.vs"

   `include "iob_plic_iob_s_port.vs"

   input  [N_SOURCES-1:0] srip_i,
   output [N_TARGETS-1:0] meip_o
);

`ifdef VCD
   initial begin
      $dumpfile("iob_plic.vcd");
      $dumpvars();
   end
`endif

   iob_plic #(
      //IOb-bus Parameters
      .ADDR_W(ADDR_W),
      .DATA_W(DATA_W),

      //PLIC Parameters
      .N_SOURCES        (N_SOURCES),
      .N_TARGETS        (N_TARGETS),
      .PRIORITIES       (8),
      .MAX_PENDING_COUNT(8),
      .HAS_THRESHOLD    (1),
      .HAS_CONFIG_REG   (1)
   ) plic_ut (
       `include "iob_plic_iob_clk_s_s_portmap.vs"

       .src_i(srip_i),
       .irq_o(meip_o),

       `include "iob_plic_iob_s_s_portmap.vs"
   );

endmodule
