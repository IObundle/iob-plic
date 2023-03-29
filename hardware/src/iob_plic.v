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

  localparam SOURCES_BITS  = $clog2(SOURCES+1);  //0=reserved
  localparam PRIORITY_BITS = $clog2(PRIORITIES);


/** Address map
 * Configuration (if implemented)
 * GateWay control
 *   [SOURCES      -1:0] el
 *   [PRIORITY_BITS-1:0] priority  [SOURCES]
 *
 * PLIC-Core
 *   [SOURCES      -1:0] ie        [TARGETS]
 *   [PRIORITY_BITS-1:0] threshold [TARGETS] (if implemented)
 *
 * Target
 *   [SOURCES_BITS -1:0] id        [TARGETS]
 */

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //IOb-bus write action
  wire iob_write;
  wire iob_we;
  wire iob_re;

  //Decoded registers
  wire [SOURCES      -1:0] el;
  wire [SOURCES      -1:0] ip;
  wire [PRIORITY_BITS-1:0] p  [SOURCES];
  wire [SOURCES      -1:0] ie [TARGETS];
  wire [PRIORITY_BITS-1:0] th [TARGETS];
  wire [SOURCES_BITS -1:0] id [TARGETS];

  wire [TARGETS      -1:0] claim;
  wire [TARGETS      -1:0] complete;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //


  /** IOb-bus accesses */
  reg iob_rvalid_reg;
  assign iob_rvalid_o = iob_rvalid_reg;
  //The core supports zero-wait state accesses on all transfers.
  always @(posedge clk_i, posedge arst_i) begin
      if (arst_i) begin
        iob_rvalid_reg <= 1'b0;
      end else if (~iob_write) begin
        iob_rvalid_reg <= iob_avalid_i;
      end
   end  //always ready after a valid
  //assign err = 1'b0;  //Never an error; Not needed??


  /** APB Read/Write */
  assign iob_write = |iob_wstrb_i;
  assign iob_re = iob_avalid_i & ~iob_write;
  assign iob_we = iob_avalid_i & iob_write;


  /** Hookup Dynamic Register block
   */
  plic_dynamic_registers #(
    //Bus Interface Parameters
    .ADDR_SIZE  ( ADDR_W ),
    .DATA_SIZE  ( DATA_W ),

    //PLIC Parameters
    .SOURCES           ( SOURCES           ),
    .TARGETS           ( TARGETS           ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT ),
    .HAS_THRESHOLD     ( HAS_THRESHOLD     ),
    .HAS_CONFIG_REG    ( HAS_CONFIG_REG    )
  )
  dyn_register_inst (
    .arst_i_n ( ~arst_i ), //Active low asynchronous reset
    .clk_i    ( clk_i   ), //System clock

    .we       ( iob_we      ), //write cycle
    .re       ( iob_re      ), //read cycle
    .be       ( iob_wstrb_i ), //STRB=byte-enables
    .waddr    ( iob_addr_i  ), //write address
    .raddr    ( iob_addr_i  ), //read address
    .wdata    ( iob_wdata_i ), //write data
    .rdata    ( iob_rdata_o ), //read data

    .el       ( el       ), //Edge/Level
    .ip       ( ip       ), //Interrupt Pending
    .ie       ( ie       ), //Interrupt Enable
    .p        ( p        ), //Priority
    .th       ( th       ), //Priority Threshold
    .id       ( id       ), //Interrupt ID
    .claim    ( claim    ), //Interrupt Claim
    .complete ( complete )  //Interrupt Complete
 );


  /** Hookup PLIC Core
   */
  plic_core #(
    .SOURCES           ( SOURCES           ),
    .TARGETS           ( TARGETS           ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT )
  )
  plic_core_inst (
    .arst_i_n     ( ~arst_i    ),
    .clk_i       ( clk_i     ),

    .src       ( src      ),
    .el        ( el       ),
    .ip        ( ip       ),
    .ie        ( ie       ),
    .ipriority ( p        ),
    .threshold ( th       ),

    .ireq      ( irq      ),
    .id        ( id       ),
    .claim     ( claim    ),
    .complete  ( complete )
  );

endmodule