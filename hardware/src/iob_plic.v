`timescale 1ns / 1ps

module iob_plic #(
  //IOb-bus Parameters
  parameter ADDR_W   = 16,
  parameter DATA_W   = 32,

  //PLIC Parameters
  parameter SOURCES           = 64,//35,  //Number of interrupt sources
  parameter TARGETS           = 4,   //Number of interrupt targets
  parameter PRIORITIES        = 8,   //Number of Priority levels
  parameter MAX_PENDING_COUNT = 8,   //Max. number of 'pending' events
  parameter HAS_THRESHOLD     = 1,   //Is 'threshold' implemented?
  parameter HAS_CONFIG_REG    = 1    //Is the 'configuration' register implemented?
)
(
  input                   clk,
  input                   rst,
  
  input                   valid,
  input [ADDR_W     -1:0] address,
  input [DATA_W     -1:0] wdata,
  input [DATA_W/8   -1:0] wstrb,
  output reg [DATA_W-1:0] rdata,
  output reg              ready,

  input  [SOURCES   -1:0] src,       //Interrupt sources
  output [TARGETS   -1:0] irq        //Interrupt Requests
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
  wire                     iob_we,
  wire                     iob_re;

  //Decoded registers
  wire [SOURCES      -1:0] el,
  wire [SOURCES      -1:0] ip;
  wire [PRIORITY_BITS-1:0] p  [SOURCES];
  wire [SOURCES      -1:0] ie [TARGETS];
  wire [PRIORITY_BITS-1:0] th [TARGETS];
  wire [SOURCES_BITS -1:0] id [TARGETS];

  wire [TARGETS      -1:0] claim,
  wire [TARGETS      -1:0] complete;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //


  /** IOb-bus accesses */
  //The core supports zero-wait state accesses on all transfers.
  assign ready  = 1'b1;  //always ready
  //assign err = 1'b0;  //Never an error; Not needed??


  /** APB Read/Write */
  assign iob_re = valid & ~wstrb;
  assign iob_we = valid &  wstrb;


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
    .rst_n    ( rst      ), //Active low asynchronous reset
    .clk      ( clk      ), //System clock

    .we       ( iob_we   ), //write cycle
    .re       ( iob_re   ), //read cycle
    .be       ( wstrb    ), //STRB=byte-enables
    .waddr    ( address  ), //write address
    .raddr    ( address  ), //read address
    .wdata    ( wdata    ), //write data
    .rdata    ( rdata    ), //read data

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
    .rst_n     ( rst  ),
    .clk       ( clk     ),

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