`timescale 1ns / 1ps

module iob_plic_sim_wrapper #(
   parameter ADDR_W    = 16,
   parameter DATA_W    = 32,
   parameter N_SOURCES = 8,
   parameter N_TARGETS = 2
) (
   input clk_i,
   input arst_i,

   input  [         0:0] iob_avalid,
   input  [  ADDR_W-1:0] iob_addr,
   input  [  DATA_W-1:0] iob_wdata,
   input  [DATA_W/8-1:0] iob_wstrb,
   output [         0:0] iob_rvalid,
   output [  DATA_W-1:0] iob_rdata,
   output [         0:0] iob_ready,

   input  [N_SOURCES-1:0] srip,
   output [N_TARGETS-1:0] meip
);

`ifdef VCD
   initial begin
      $dumpfile("iob_plic.vcd");
      $dumpvars();
   end
`endif

   wire cke_i = 1'b1;

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
      `include "iob_s_portmap.vs"

      .src(srip),
      .irq(meip),

      `include "clk_en_rst_s_s_portmap.vs"
   );

endmodule
