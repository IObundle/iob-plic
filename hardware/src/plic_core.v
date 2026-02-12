/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   RISC-V Platform-Level Interrupt Controller                    //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2017 ROA Logic BV                     //
//             www.roalogic.com                                    //
//                                                                 //
//   This source file may be used and distributed without          //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     //
//   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  //
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  //
//   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  //
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      //
//   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     //
//   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  //
//   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          //
//   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////

// +FHDR -  Semiconductor Reuse Standard File Header Section  -------
// FILE NAME      : plic_core.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-07-01  rherveille  initial release
//         2017-09-12  rherveille  Added 'claim' and 'complete'
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
// ------------------------------------------------------------------
// PURPOSE  : PLIC Core Top Level
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  SOURCES           1+     No. of interupt sources  8
//  TARGETS           1+     No. of interrupt targets 1
//  PRIORITIES        1+     No. of priority levels   8
//  MAX_PENDING_COUNT 0+     Max. pending interrupts  0
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; rst_n
//   Clock Domains       : 1, clk, rising edge
//   Critical Timing     : cell-array for each target
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : plic_gateway, plic_cell, plic_target
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------
`timescale 1ns / 1ps

module plic_core #(
   parameter SOURCES           = 8,  //Number of interrupt sources
   parameter TARGETS           = 1,  //Number of interrupt targets
   parameter PRIORITIES        = 8,  //Number of Priority levels
   parameter MAX_PENDING_COUNT = 0,

   //These should be localparams, but that's not supported by all tools yet
   parameter SOURCES_BITS  = $clog2(SOURCES + 1),  //0=reserved
   parameter PRIORITY_BITS = $clog2(PRIORITIES)
) (
   input rst_n,  //Active low asynchronous reset
   clk,  //System clock

   input  [SOURCES      -1:0] src,  //Interrupt request from devices/sources
   el,  //Edge/Level sensitive for each source
   output [SOURCES      -1:0] ip,   //Interrupt Pending for each source

   input [TARGETS*SOURCES      -1:0] ie,  //Interrupt enable per source, for each target
   input  [SOURCES*PRIORITY_BITS-1:0] ipriority,  //Priority for each source (priority is a reserved keyword)
   input [TARGETS*PRIORITY_BITS-1:0] threshold,  //Priority Threshold for each target

   output [        TARGETS      -1:0] ireq,     //Interrupt request for each target
   output [TARGETS*SOURCES_BITS -1:0] id,       //Interrupt ID (1..SOURCES), for each target
   input  [        TARGETS      -1:0] claim,    //Interrupt claim
   input  [        TARGETS      -1:0] complete  //Interrupt handling complete
);
   //////////////////////////////////////////////////////////////////
   //
   // Variables
   //
   genvar s, t;

   wire [TARGETS*SOURCES*SOURCES_BITS -1:0] id_array;
   wire [TARGETS*SOURCES*PRIORITY_BITS-1:0] pr_array;

   reg  [        TARGETS*SOURCES_BITS -1:0] id_claimed;
   wire [        SOURCES*TARGETS      -1:0] claim_array;
   wire [        SOURCES*TARGETS      -1:0] complete_array;


   //////////////////////////////////////////////////////////////////
   //
   // Module Body
   //


   /** Generate claim/complete per source, for each target
   */
   generate
      for (s = 0; s < SOURCES; s++) begin : gen_claims_source_array
         for (t = 0; t < TARGETS; t++) begin : gen_claim_complete
            assign claim_array[s*TARGETS+t]    = (id[t*SOURCES_BITS+:SOURCES_BITS] == s + 1) ? claim[t] : 1'b0;
            assign complete_array[s*TARGETS+t] = (id_claimed[t*SOURCES_BITS+:SOURCES_BITS] == s + 1) ? complete[t] : 1'b0;
         end
      end
   endgenerate


   /** Store claimed ID
   */
   generate
      for (t = 0; t < TARGETS; t++) begin : gen_id_claimed
         always @(posedge clk, negedge rst_n)
            if (!rst_n) id_claimed[t*SOURCES_BITS+:SOURCES_BITS] <= 'h0;
            else if (claim[t])
               id_claimed[t*SOURCES_BITS+:SOURCES_BITS] <= id[t*SOURCES_BITS+:SOURCES_BITS];
      end
   endgenerate


   /** Build Gateways
   *
   *  For each Interrupt Source there's a gateway
   */
   generate
      for (s = 0; s < SOURCES; s++) begin : gen_gateway
         plic_gateway #(MAX_PENDING_COUNT) gateway_inst (
             .rst_n   (rst_n),
             .clk     (clk),
             .src     (src[s]),
             .edge_lvl(el[s]),
             .ip      (ip[s]),
             .claim   (|claim_array[s*TARGETS+:TARGETS]),
             .complete(|complete_array[s*TARGETS+:TARGETS])
         );
      end : gen_gateway
   endgenerate


   /** Build cell-array
   *
   *  Generate array of ID/Priority cells
   *  One cell for each source-target combination
   */
   generate
      for (t = 0; t < TARGETS; t++) begin : gen_cell_target_array
         for (s = 0; s < SOURCES; s++) begin : gen_cell_source_array
            plic_cell #(
               .ID        (s + 1),
               .SOURCES   (SOURCES),
               .PRIORITIES(PRIORITIES)
            ) cell_inst (
                .rst_ni(rst_n),
                .clk_i(clk),
                .ip_i(ip[s]),
                .ie_i(ie[t*SOURCES+s]),  //bitslice from packed array 'ie'
                .priority_i(ipriority[s*PRIORITY_BITS+:PRIORITY_BITS]),
                .id_o(id_array[t*SOURCES*SOURCES_BITS+s*SOURCES_BITS+:SOURCES_BITS]),
                .priority_o(pr_array[t*SOURCES*PRIORITY_BITS+s*PRIORITY_BITS+:PRIORITY_BITS])
            );
         end : gen_cell_source_array
      end : gen_cell_target_array
   endgenerate


   /** Build output array
   *
   * Generate output array for each target
   */
   generate
      for (t = 0; t < TARGETS; t++) begin : gen_target
         plic_target #(
            .SOURCES   (SOURCES),
            .PRIORITIES(PRIORITIES)
         ) target_inst (
             .rst_ni     (rst_n),
             .clk_i      (clk),
             .id_i       (id_array[t*SOURCES*SOURCES_BITS+:SOURCES*SOURCES_BITS]),
             .priority_i (pr_array[t*SOURCES*PRIORITY_BITS+:SOURCES*PRIORITY_BITS]),
             .threshold_i(threshold[t*PRIORITY_BITS+:PRIORITY_BITS]),
             .id_o       (id[t*SOURCES_BITS+:SOURCES_BITS]),
             .ireq_o     (ireq[t])
         );
      end : gen_target
   endgenerate

endmodule : plic_core
