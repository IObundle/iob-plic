`timescale 1ns / 1ps

`include "iob_lib.vh"
`include "iob_plic_conf.vh"

module iob_plic #(
   `include "iob_plic_params.vh"
) (
   `include "iob_plic_io.vh"
);

   //////////////////////////////////////////////////////////////////
   //
   // Constants
   //

   localparam SOURCES_BITS = $clog2(N_SOURCES + 1);  //0=reserved
   localparam PRIORITY_BITS = $clog2(PRIORITIES);


   /** Address map
 * Configuration (if implemented)
 * GateWay control
 *   [N_SOURCES      -1:0] el
 *   [PRIORITY_BITS-1:0] priority  [N_SOURCES]
 *
 * PLIC-Core
 *   [N_SOURCES      -1:0] ie        [N_TARGETS]
 *   [PRIORITY_BITS-1:0] threshold [N_TARGETS] (if implemented)
 *
 * Target
 *   [N_SOURCES_BITS -1:0] id        [N_TARGETS]
 */

   //////////////////////////////////////////////////////////////////
   //
   // Variables
   //

   //IOb-bus write action
   wire                       iob_write;
   wire                       iob_we;
   wire                       iob_re;

   //Decoded registers
   wire [N_SOURCES      -1:0] el;
   wire [N_SOURCES      -1:0] ip;
   wire [  PRIORITY_BITS-1:0] p         [N_SOURCES];
   wire [N_SOURCES      -1:0] ie        [N_TARGETS];
   wire [  PRIORITY_BITS-1:0] th        [N_TARGETS];
   wire [  SOURCES_BITS -1:0] id        [N_TARGETS];

   wire [N_TARGETS      -1:0] claim;
   wire [N_TARGETS      -1:0] complete;


   //////////////////////////////////////////////////////////////////
   //
   // Module Body
   //

   /** APB Read/Write */
   assign iob_write = |iob_wstrb_i;
   assign iob_re    = iob_avalid_i & ~iob_write;
   assign iob_we    = iob_avalid_i & iob_write;


   // Module intanciation
   // // Interface Registers
   // // // Read data valid
   iob_reg_re #(
      .DATA_W (1),
      .RST_VAL(0)
   ) iob_reg_rvalid (
      .clk_i (clk_i),
      .arst_i(arst_i),
      .cke_i (cke_i),
      .rst_i (1'b0),
      .en_i  (~iob_write),
      .data_i(iob_avalid_i),
      .data_o(iob_rvalid_o)
   );
   // // // Ready signal, is always 1 since the read and write to the CLINT only take one clock cycle.
   iob_reg_re #(
      .DATA_W (1),
      .RST_VAL(0)
   ) iob_reg_ready (
      .clk_i (clk_i),
      .arst_i(arst_i),
      .cke_i (cke_i),
      .rst_i (1'b0),
      .en_i  (1'b1),
      .data_i(1'b1),
      .data_o(iob_ready_o)
   );

   /** Hookup Dynamic Register block
   */
   plic_dynamic_registers #(
      //Bus Interface Parameters
      .ADDR_SIZE(ADDR_W),
      .DATA_SIZE(DATA_W),

      //PLIC Parameters
      .SOURCES          (N_SOURCES),
      .TARGETS          (N_TARGETS),
      .PRIORITIES       (PRIORITIES),
      .MAX_PENDING_COUNT(MAX_PENDING_COUNT),
      .HAS_THRESHOLD    (HAS_THRESHOLD),
      .HAS_CONFIG_REG   (HAS_CONFIG_REG)
   ) dyn_register_inst (
      .rst_n(~arst_i),  //Active low asynchronous reset
      .clk  (clk_i),    //System clock

      .we   (iob_we),       //write cycle
      .re   (iob_re),       //read cycle
      .be   (iob_wstrb_i),  //STRB=byte-enables
      .waddr(iob_addr_i),   //write address
      .raddr(iob_addr_i),   //read address
      .wdata(iob_wdata_i),  //write data
      .rdata(iob_rdata_o),  //read data

      .el      (el),       //Edge/Level
      .ip      (ip),       //Interrupt Pending
      .ie      (ie),       //Interrupt Enable
      .p       (p),        //Priority
      .th      (th),       //Priority Threshold
      .id      (id),       //Interrupt ID
      .claim   (claim),    //Interrupt Claim
      .complete(complete)  //Interrupt Complete
   );


   /** Hookup PLIC Core
   */
   plic_core #(
      .SOURCES          (N_SOURCES),
      .TARGETS          (N_TARGETS),
      .PRIORITIES       (PRIORITIES),
      .MAX_PENDING_COUNT(MAX_PENDING_COUNT)
   ) plic_core_inst (
      .rst_n(~arst_i),
      .clk  (clk_i),

      .src      (src),
      .el       (el),
      .ip       (ip),
      .ie       (ie),
      .ipriority(p),
      .threshold(th),

      .ireq    (irq),
      .id      (id),
      .claim   (claim),
      .complete(complete)
   );

endmodule
