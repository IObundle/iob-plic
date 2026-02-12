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
// FILE NAME      : plic_dynamic_registers.v
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-07-18  rherveille  initial release
//         2017-09-13  rherveille  Added 'claim' and 'complete'
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
// ------------------------------------------------------------------
// PURPOSE  : Dynamic Register generation for PLIC
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE   DESCRIPTION              DEFAULT UNITS
//  ADDR_SIZE         [32,64] read/write address width 32
//  DATA_SIZE         [32,64] read/write data width    32
//  SOURCES           1+      No. of interupt sources  8
//  TARGETS           1+      No. of interrupt targets 1
//  PRIORITIES        1+      No. of priority levels   8
//  MAX_PENDING_COUNT 0+      Max. pending interrupts  4
//  HAS_THRESHOLD     [0,1]   Is 'threshold' impl.?    1
//  HAS_CONFIG_REG    [0,1]   Is 'config' implemented? 1
// ------------------------------------------------------------------
// REUSE ISSUES
//   Reset Strategy      : external asynchronous active low; rst_n
//   Clock Domains       : 1, clk, rising edge
//   Critical Timing     : na
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               :
// -FHDR-------------------------------------------------------------
`timescale 1ns / 1ps

module plic_dynamic_registers #(
   //Bus Interface Parameters
   parameter ADDR_SIZE = 32,
   parameter DATA_SIZE = 32,

   //PLIC Parameters
   parameter SOURCES           = 8,  //Number of interrupt sources
   parameter TARGETS           = 1,  //Number of interrupt targets
   parameter PRIORITIES        = 8,  //Number of Priority levels
   parameter MAX_PENDING_COUNT = 4,  //
   parameter HAS_THRESHOLD     = 1,  //Is 'threshold' implemented?
   parameter HAS_CONFIG_REG    = 1,  //Is 'config' implemented?

   //These should be 'localparam', but that's not supported by all tools yet
   parameter BE_SIZE       = (DATA_SIZE + 7) / 8,
   // To be Verilog compliant, $clog2 is removed. The values must be provided by the instantiating module.
   // e.g. for default SOURCES=8, SOURCES_BITS should be 4 ($clog2(8+1))
   // e.g. for default PRIORITIES=8, PRIORITY_BITS should be 3 ($clog2(8))
   parameter SOURCES_BITS  = 4,
   parameter PRIORITY_BITS = 3
) (
   input rst_n,  //Active low asynchronous reset
   clk,  //System clock

   input                          we,     //write enable
   re,  //read enable
   input      [BE_SIZE      -1:0] be,     //byte enable (writes only)
   input      [ADDR_SIZE    -1:0] waddr,  //write address
   raddr,  //read address
   input      [DATA_SIZE    -1:0] wdata,  //write data
   output reg [DATA_SIZE    -1:0] rdata,  //read data

   output [SOURCES      -1:0] el,  //Edge/Level sensitive for each source
   input  [SOURCES      -1:0] ip,  //Interrupt Pending for each source

   output     [TARGETS*SOURCES      -1:0] ie,  //Interrupt enable per source, for each target
   output reg [SOURCES*PRIORITY_BITS-1:0] p,   //Priority for each source
   output reg [TARGETS*PRIORITY_BITS-1:0] th,  //Priority Threshold for each target

   input      [TARGETS*SOURCES_BITS -1:0] id,       //Interrupt ID for each target
   output reg [        TARGETS      -1:0] claim,    //Interrupt Claim
   output reg [        TARGETS      -1:0] complete  //Interrupt Complete
);

   //////////////////////////////////////////////////////////////////
   //
   // Constants
   //
   localparam DATA_BYTES = BE_SIZE;  //number of bytes in DATA



   /** Address map
 * Configuration
 * GateWay control
 *   [SOURCES      -1:0] el
 *   [PRIORITY_BITS-1:0] priority  [SOURCES]
 *
 * PLIC-Core
 *   [SOURCES      -1:0] ie        [TARGETS]
 *   [PRIORITY_BITS-1:0] threshold [TARGETS]
 *   [SOURCES_BITS -1:0] ID        [TARGETS
 */

   /** Calculate Register amount/offset
   *  Each register is DATA_SIZE wide
   */
   localparam REG_TYPE_BITS = 3;
   localparam [REG_TYPE_BITS-1:0] CONFIG    = 3'd0,
                                 EL        = 3'd1,
                                 IE        = 3'd2,
                                 PRIORITY  = 3'd3,
                                 THRESHOLD = 3'd4,
                                 ID        = 3'd5;

   //Configuration Bits
   localparam MAX_SOURCES_BITS = 16;
   localparam MAX_TARGETS_BITS = 16;
   localparam MAX_PRIORITY_BITS = MAX_SOURCES_BITS;
   localparam HAS_THRESHOLD_BITS = 1;

   //How many CONFIG registers are there (only 1)
   localparam CONFIG_REGS    = HAS_CONFIG_REG == 0 ? 0 : (MAX_SOURCES_BITS + MAX_TARGETS_BITS + MAX_PRIORITY_BITS + HAS_THRESHOLD_BITS + DATA_SIZE -1) / DATA_SIZE;

   //How many Edge/Level registers are there?
   localparam EL_REGS = (SOURCES + DATA_SIZE - 1) / DATA_SIZE;

   //How many IE registers are there?
   localparam IE_REGS = EL_REGS * TARGETS;

   //How many nibbles are there in 'PRIORITY_BITS' ?
   //Each PRIORITY starts at a new nibble boundary
   localparam PRIORITY_NIBBLES = (PRIORITY_BITS + 3 - 1) / 4;

   //How many PRIORITY fields fit in 1 register?
   localparam PRIORITY_FIELDS_PER_REG = (PRIORITY_NIBBLES == 0) ? 0 : DATA_SIZE / (PRIORITY_NIBBLES * 4);

   //How many Priority registers are there?
   localparam PRIORITY_REGS = (PRIORITY_FIELDS_PER_REG == 0) ? 0 : (SOURCES + PRIORITY_FIELDS_PER_REG - 1) / PRIORITY_FIELDS_PER_REG;

   //How many Threshold registers are there?
   //  localparam THRESHOLD_REGS = HAS_THRESHOLD == 0 ? 0 : (TARGETS + PRIORITY_FIELDS_PER_REG -1) / PRIORITY_FIELDS_PER_REG;
   localparam THRESHOLD_REGS = HAS_THRESHOLD == 0 ? 0 : TARGETS;

   //How many ID register are there?
   localparam ID_REGS = TARGETS;

   //How many registers in total?
   localparam TOTAL_REGS = CONFIG_REGS + EL_REGS + IE_REGS + PRIORITY_REGS + THRESHOLD_REGS + ID_REGS;


   //////////////////////////////////////////////////////////////////
   //
   // Variables
   //

   //Read Variables
   integer read_register, read_register_idx;
   integer                                write_register;

   //Registers
   reg     [(TOTAL_REGS-1)*DATA_SIZE-1:0] registers;


   //////////////////////////////////////////////////////////////////
   //
   // Functions
   //
   function [DATA_SIZE-1:0] gen_wval;
      //Returns the new value for a register
      // if be[n] == '1' then gen_val[byte_n] = new_val[byte_n]
      // else                 gen_val[byte_n] = old_val[byte_n]
      input [DATA_SIZE-1:0] old_val, new_val;
      input [BE_SIZE-1:0] be;

      integer n;
      begin
         for (n = 0; n < BE_SIZE; n = n + 1)
         gen_wval[n*8+:8] = be[n] ? new_val[n*8+:8] : old_val[n*8+:8];
      end
   endfunction


   /** Register Access calculation
   *  Registers are created dynamically, access is determined by the
   *  parameter settings
   */
   function automatic [REG_TYPE_BITS-1:0] register_function;
      //return register-type for specified register
      input integer r;

      integer idx;
      begin
         idx = r;

         //1. Configuration Register
         if (idx < CONFIG_REGS) register_function = CONFIG;
         else begin
            idx = idx - CONFIG_REGS;

            //2. Gateway control registers
            //  Edge/Level
            if (idx < EL_REGS) register_function = EL;
            else begin
               idx = idx - EL_REGS;

               //3. PLIC Core fabric registers
               if (idx < PRIORITY_REGS) register_function = PRIORITY;
               else begin
                  idx = idx - PRIORITY_REGS;
                  if (idx < IE_REGS) register_function = IE;
                  else begin
                     idx = idx - IE_REGS;

                     //4. Target registers
                     if (idx < THRESHOLD_REGS) register_function = THRESHOLD;
                     else register_function = ID;
                  end
               end
            end
         end
      end
   endfunction


   function automatic integer register_idx;
      //return offset in register-type
      input integer r;

      integer idx;
      begin
         idx = r;

         //1. Configuration registers
         if (idx < CONFIG_REGS) register_idx = idx;
         else begin
            idx = idx - CONFIG_REGS;

            //2. first Gateway control registers
            //  Edge/Level
            //  Interrupt Pending/Acknowledge
            if (idx < EL_REGS) register_idx = idx;
            else begin
               idx = idx - EL_REGS;

               //3. PLIC Core fabric registers
               if (idx < PRIORITY_REGS) register_idx = idx;
               else begin
                  idx = idx - PRIORITY_REGS;
                  if (idx < IE_REGS) register_idx = idx;
                  else begin
                     idx = idx - IE_REGS;

                     //4. Target registers
                     if (idx < THRESHOLD_REGS) register_idx = idx;
                     else begin
                        idx          = idx - THRESHOLD_REGS;
                        register_idx = idx;
                     end
                  end
               end
            end
         end
      end
   endfunction


   function automatic integer address2register;
      //Translate 'address' into register number
      input [ADDR_SIZE-1:0] address;
      begin
         address2register = address / DATA_BYTES;
      end
   endfunction


   function automatic [TARGETS-1:0] gen_claim;
      //generate internal 'claim' signal
      input re;
      input [ADDR_SIZE-1:0] address;

      integer r, idx;
      begin
         r   = address2register(address);
         idx = register_idx(r);

         if (register_function(r) == ID && re) gen_claim = (1 << idx);
         else gen_claim = {TARGETS{1'b0}};
      end
   endfunction


   function automatic [SOURCES-1:0] gen_complete;
      //generate internal 'complete' signal
      input we;
      input [ADDR_SIZE-1:0] address;

      integer r, idx;
      begin
         r   = address2register(address);
         idx = register_idx(r);

         if (register_function(r) == ID && we) gen_complete = (1 << idx);
         else gen_complete = {TARGETS{1'b0}};
      end
   endfunction


   function automatic [DATA_SIZE-1:0] encode_config;
      //encode 'rdata' when reading from CONFIG
      input integer r;  //which register

      reg [MAX_SOURCES_BITS -1:0] sources_bits;
      reg [MAX_TARGETS_BITS -1:0] targets_bits;
      reg [MAX_PRIORITY_BITS-1:0] priority_bits;
      reg                         has_th_bit;
      begin
         sources_bits  = SOURCES;
         targets_bits  = TARGETS;
         priority_bits = PRIORITIES;
         has_th_bit    = HAS_THRESHOLD ? 1'b1 : 1'b0;

         if (CONFIG_REGS == 1)
            encode_config = {15'h0, has_th_bit, priority_bits, targets_bits, sources_bits};
         else if (r == 0) encode_config = {targets_bits, sources_bits};
         else encode_config = {15'h0, has_th_bit, priority_bits};
      end
   endfunction


   function automatic [DATA_SIZE-1:0] encode_p;
      //encode 'rdata' when reading from PRIORITY
      input integer r;  //which register
      integer n;
      begin
         //clear all bits
         encode_p = {DATA_SIZE{1'b0}};

         //move PRIORITY fields into bit-positions
         if ((r + 1) * PRIORITY_FIELDS_PER_REG <= SOURCES)
            for (n = 0; n < PRIORITY_FIELDS_PER_REG; n = n + 1)
            encode_p = encode_p | (p[(r*PRIORITY_FIELDS_PER_REG+n)*PRIORITY_BITS +: PRIORITY_BITS] << (n * PRIORITY_NIBBLES * 4));
         else
            for (n = 0; n < SOURCES % PRIORITY_FIELDS_PER_REG; n = n + 1)
            encode_p = encode_p | (p[(r*PRIORITY_FIELDS_PER_REG+n)*PRIORITY_BITS +: PRIORITY_BITS] << (n * PRIORITY_NIBBLES * 4));
      end
   endfunction


   function automatic [PRIORITY_BITS-1:0] decode_p;
      //extract/decode 'priority' fields from PRIORITY-register
      input integer r;  //which register
      input integer s;  //which field (source)

      reg     [DATA_SIZE-1:0] tmp;
      integer                 field;
      begin
         field    = s % PRIORITY_FIELDS_PER_REG;
         tmp      = registers[r*DATA_SIZE+:DATA_SIZE];
         tmp      = tmp >> (field * PRIORITY_NIBBLES * 4);
         decode_p = tmp[PRIORITY_BITS-1:0];
      end
   endfunction


   function automatic [DATA_SIZE-1:0] encode_th;
      //encode 'rdata' when reading from THRESHOLD
      input integer r;  //which register
      integer n;
      begin
         //clear all bits
         encode_th = {DATA_SIZE{1'b0}};

         //move THRESHOLD fields into bit-positions
         if ((r + 1) * PRIORITY_FIELDS_PER_REG <= TARGETS)
            for (n = 0; n < PRIORITY_FIELDS_PER_REG; n = n + 1)
            encode_th = encode_th | (p[(r*PRIORITY_FIELDS_PER_REG+n)*PRIORITY_BITS +: PRIORITY_BITS] << (n * PRIORITY_NIBBLES * 4));
         else
            for (n = 0; n < TARGETS % PRIORITY_FIELDS_PER_REG; n = n + 1)
            encode_th = encode_th | (p[(r*PRIORITY_FIELDS_PER_REG+n)*PRIORITY_BITS +: PRIORITY_BITS] << (n * PRIORITY_NIBBLES * 4));
      end
   endfunction


   /** Display Register layout/map
   */
   //synopsys translate_off
   function [23*8-1:0] register_function_name;
      //returns the 'string' name associated with a register type
      input [REG_TYPE_BITS-1:0] function_number;

      begin
         case (function_number)
            CONFIG:    register_function_name = "Configuration          ";
            EL:        register_function_name = "Edge/Level             ";
            IE:        register_function_name = "Interrupt Enable       ";
            PRIORITY:  register_function_name = "Interrupt Priority     ";
            THRESHOLD: register_function_name = "Priority Threshold     ";
            ID:        register_function_name = "ID                     ";
            default:   register_function_name = "???????????????????????";
         endcase
      end
   endfunction


   //Display IP configuration; register map
   task display_configuration;
      begin
         $display(" RISC-V Platform Level Interrupt Controller                 ");

         $display("- Configuration Report -------------------------------------");
         $display(" Sources | Targets | Priority-lvl | Threshold? | Event-Cnt  ");
         $write("  %4d   |", SOURCES);
         $write("  %3d    |", TARGETS);
         $write("  %5d       |", PRIORITIES);
         $write("  %5s     |", HAS_THRESHOLD ? "YES" : "NO");
         $display("  %3d    ", MAX_PENDING_COUNT);

         $display("- Register Map ---------------------------------------------");
         display_register_map();

         $display("- End Configuration Report ---------------------------------");
      end
   endtask

   task display_register_map;
      integer address, r;
      begin
         $display(" Address  Function               Mapping");
         for (r = 0; r < TOTAL_REGS; r = r + 1) begin
            //display address + function
            address = r * (DATA_SIZE / 8);
            $write(" 0x%08x %s ", address, register_function_name(register_function(r)));

            //display register mapping
            case (register_function(
                r
            ))
               CONFIG:    display_config_map(register_idx(r));
               EL:        display_el_map(register_idx(r));
               PRIORITY:  display_priority_map(register_idx(r));
               IE:        display_ie_map(register_idx(r));
               THRESHOLD: display_threshold_map(register_idx(r));
               ID:        display_id_map(register_idx(r));
               default:   $display("");
            endcase
         end
      end
   endtask

   task display_config_map;
      input integer r;

      begin
         if (CONFIG_REGS == 1) $display("15'h0,TH,PRIORITES,TARGETS,SOURCES");
         else if (r == 0) $display("TARGETS,SOURCES");
         else $display("15'h0,TH,PRIORITIES");
      end
   endtask

   task display_el_map;
      input integer r;

      begin
         if ((r + 1) * DATA_SIZE <= SOURCES)
            $display("EL[%0d:%0d]", (r + 1) * DATA_SIZE - 1, r * DATA_SIZE);
         else
            $display(
                "%0d'h0, EL[%0d:%0d]", (r + 1) * DATA_SIZE - SOURCES, SOURCES - 1, r * DATA_SIZE
            );
      end
   endtask

   task display_ie_map;
      input integer ri;

      integer target, r;

      begin
         target = ri / EL_REGS;
         r      = ri % EL_REGS;

         if ((r + 1) * DATA_SIZE <= SOURCES)
            $display("IE[%0d][%0d:%0d]", target, (r + 1) * DATA_SIZE - 1, r * DATA_SIZE);
         else
            $display(
                "%0d'h0, IE[%0d][%0d:%0d]",
                (r + 1) * DATA_SIZE - SOURCES,
                target,
                SOURCES - 1,
                r * DATA_SIZE
            );
      end
   endtask

   task display_priority_map;
      input integer r;
      integer s;
      begin
         if ((r + 1) * PRIORITY_FIELDS_PER_REG <= SOURCES) begin
            for (
                s = (r + 1) * PRIORITY_FIELDS_PER_REG - 1;
                s >= r * PRIORITY_FIELDS_PER_REG;
                s = s - 1
            ) begin
               if (PRIORITY_BITS % 4 != 0) $write("%0d'b0,", 4 - (PRIORITY_BITS % 4));
               $write("P[%0d][%0d:%0d]", s, PRIORITY_BITS - 1, 0);
               if (s != r * PRIORITY_FIELDS_PER_REG) $write(",");
            end
         end else begin
            $write("%0d'h0,",
                   DATA_SIZE - (SOURCES - r * PRIORITY_FIELDS_PER_REG) * PRIORITY_NIBBLES * 4);

            for (s = SOURCES - 1; s >= r * PRIORITY_FIELDS_PER_REG; s = s - 1) begin
               if (PRIORITY_BITS % 4 != 0) $write("%0d'b0,", 4 - (PRIORITY_BITS % 4));
               $write("P[%0d][%0d:%0d]", s, PRIORITY_BITS - 1, 0);
               if (s != r * PRIORITY_FIELDS_PER_REG) $write(",");
            end
         end

         $display("");
      end
   endtask

   /*
  task display_threshold_map;
    input integer r;
    integer t;
    begin
    if ((r+1)*PRIORITY_FIELDS_PER_REG <= TARGETS)
    begin
        for (t=(r+1)*PRIORITY_FIELDS_PER_REG -1; t >= r*PRIORITY_FIELDS_PER_REG; t = t - 1)
        begin
            if (PRIORITY_BITS % 4) $write("%0d'b0,", 4- (PRIORITY_BITS % 4));
            $write ("Th[%0d][%0d:%0d]", t, PRIORITY_BITS -1, 0);
            if (t != r*PRIORITY_FIELDS_PER_REG) $write(",");
        end
    end
    else
    begin
        $write ("%0d'h0,", DATA_SIZE - (TARGETS-r*PRIORITY_FIELDS_PER_REG) * PRIORITY_NIBBLES*4);

        for (t=TARGETS-1; t >= r*PRIORITY_FIELDS_PER_REG; t = t - 1)
        begin
            if (PRIORITY_BITS % 4) $write("%0d'b0,", 4- (PRIORITY_BITS % 4));
            $write ("Th[%0d][%0d:%0d]", t, PRIORITY_BITS -1, 0);
            if (t != r*PRIORITY_FIELDS_PER_REG) $write(",");
        end
    end

    $display("");
    end
  endtask
*/

   task display_threshold_map;
      input integer r;

      begin
         $display("%0d'h0, Th[%0d][%0d:%0d]", DATA_SIZE - PRIORITY_BITS, r, PRIORITY_BITS - 1, 0);
      end
   endtask


   task display_id_map;
      input integer r;

      begin
         $display("%0d'h0, ID[%0d][%0d:%0d]", DATA_SIZE - SOURCES_BITS, r, SOURCES_BITS - 1, 0);
      end
   endtask

   //synopsys translate_on


   //////////////////////////////////////////////////////////////////
   //
   // Module Body
   //
   //synopsys translate_off
   initial display_configuration();
   //synopsys translate_on


   /** Write Registers
   *
   * This core has a dynamic array of registers, depending on the
   *  parameter settings
   * Writing to the ID register generates a strobe
   */
   assign write_register = address2register(waddr);

   always @(posedge clk, negedge rst_n) begin
      if (!rst_n) registers <= 0;
      else if (we)
         case (register_function(
             write_register
         ))
            ID: ;  //A write to ID generates a strobe signal
            default:
            registers[write_register*DATA_SIZE+:DATA_SIZE] <= gen_wval(
                registers[write_register*DATA_SIZE+:DATA_SIZE], wdata, be
            );
         endcase
   end


   /** Claim / Complete
   *  Special cases for Claim / Complete
   *  A read generates a claim strobe
   *  A write doesn't access the register, but generates a complete strobe instead
   */
   always @(posedge clk, negedge rst_n)
      if (!rst_n) claim <= 0;
      else claim <= gen_claim(re, raddr);

   always @(posedge clk, negedge rst_n)
      if (!rst_n) complete <= 0;
      else complete <= gen_complete(we, waddr);


   /** Decode registers
   */
   generate
      genvar r, t, s;

      for (r = 0; r < TOTAL_REGS; r = r + 1) begin : g_decode_registers
         case (register_function(
             r
         ))
            //Decode EL register(s)
            // There are SOURCES EL-bits, spread out over
            //  DATA_SIZE wide registers
            EL: begin : g_el_regs
               if ((register_idx(r) + 1) * DATA_SIZE <= SOURCES)
                  assign el[register_idx(
                      r
                  )*DATA_SIZE+:DATA_SIZE] = registers[r*DATA_SIZE+:DATA_SIZE];
               else
                  assign el[SOURCES-1:register_idx(
                      r
                  )*DATA_SIZE] = registers[r*DATA_SIZE+:DATA_SIZE];
            end

            //Decode PRIORITY register(s)
            // There are SOURCES priority-fields, each PRIORITY_BITS
            //  wide, spread out over DATA_SIZE wide registers,
            //  with each field starting at a nibble boundary
            // Need to use always @* (was always_comb), because we're not assigning a fixed value
            PRIORITY: begin : g_priority_regs
               if ((register_idx(r) + 1) * PRIORITY_FIELDS_PER_REG <= SOURCES)
                  for (
                      s = register_idx(r) * PRIORITY_FIELDS_PER_REG;
                      s < (register_idx(r) + 1) * PRIORITY_FIELDS_PER_REG;
                      s = s + 1
                  ) begin : decode_p0
                     always @(registers) p[s*PRIORITY_BITS+:PRIORITY_BITS] = decode_p(r, s);
                  end
               else
                  for (
                      s = register_idx(r) * PRIORITY_FIELDS_PER_REG; s < SOURCES; s = s + 1
                  ) begin : decode_p1
                     always @(registers) p[s*PRIORITY_BITS+:PRIORITY_BITS] = decode_p(r, s);
                  end
            end

            //Decode IE register(s)
            // For each TARGET there's SOURCES IE-fields
            // Layout is the same as for the EL-registers, with each
            //  TARGET starting at a new register
            IE: begin : g_ie_regs
               if (((register_idx(r) % EL_REGS) + 1) * DATA_SIZE <= SOURCES)
                  assign ie[(register_idx(
                      r
                  )/EL_REGS)*SOURCES+(register_idx(
                      r
                  )%EL_REGS)*DATA_SIZE+:DATA_SIZE] = registers[r*DATA_SIZE+:DATA_SIZE];
               else
                  assign ie[(register_idx(
                      r
                  )/EL_REGS)*SOURCES+SOURCES-1:(register_idx(
                      r
                  )/EL_REGS)*SOURCES+(register_idx(
                      r
                  )%EL_REGS)*DATA_SIZE] = registers[r*DATA_SIZE+:DATA_SIZE];
            end

            /*
          //Decode THRESHOLD register(s)
          // There are TARGETS threshold-fields, each PRIORITY_BITS
          //  wide, spread out over DATA_SIZE wide registers,
          //  with each field starting at a nibble boundary
          THRESHOLD: if (HAS_THRESHOLD)
                     begin
                         if ( (register_idx(r)+1) * PRIORITY_FIELDS_PER_REG <= TARGETS )
                           for (t =  register_idx(r)    * PRIORITY_FIELDS_PER_REG;
                                t < (register_idx(r)+1) * PRIORITY_FIELDS_PER_REG;
                                t = t + 1)
                           begin : decode_th0
                               always @*
                               begin
                                   reg [DATA_SIZE-1:0] tmp;  //local variable
                                   tmp   = registers[r*DATA_SIZE+:DATA_SIZE];
                                   tmp   = tmp >> (t * PRIORITY_NIBBLES);
                                   th[t*PRIORITY_BITS +: PRIORITY_BITS] = tmp[PRIORITY_BITS-1:0];
                               end
                           end
                         else
                           for (t = register_idx(r) * PRIORITY_FIELDS_PER_REG;
                                t < TARGETS;
                                t = t + 1)
                           begin : decode_th1
                               always @*
                               begin
                                   reg [DATA_SIZE-1:0] tmp;  //local variable
                                   tmp   = registers[r*DATA_SIZE+:DATA_SIZE];
                                   tmp   = tmp >> (t * PRIORITY_NIBBLES);
                                   th[t*PRIORITY_BITS +: PRIORITY_BITS] = tmp[PRIORITY_BITS-1:0];
                               end
                           end
                     end
*/

            THRESHOLD:
            if (HAS_THRESHOLD) begin : g_threshold_regs
               assign th[register_idx(
                   r
               )*PRIORITY_BITS+:PRIORITY_BITS] =
                   registers[r*DATA_SIZE+:PRIORITY_BITS];
            end
         endcase
      end
   endgenerate


   /** Read Registers
   */
   assign read_register     = address2register(raddr);
   assign read_register_idx = register_idx(read_register);

   always @(posedge clk, negedge rst_n)
      if (!rst_n) rdata <= {DATA_SIZE{1'b0}};
      else if (re)
         case (register_function(
             read_register
         ))
            CONFIG: if (HAS_CONFIG_REG) rdata <= encode_config(read_register_idx);
            EL: rdata <= el >> (read_register_idx * DATA_SIZE);
            PRIORITY: rdata <= encode_p(read_register_idx);
            IE:
            rdata <= ie[(read_register_idx/EL_REGS)*SOURCES +: SOURCES] >> ((read_register_idx % EL_REGS) * DATA_SIZE);
            //      THRESHOLD: if (HAS_THRESHOLD) rdata <= encode_th(read_register_idx);
            THRESHOLD:
            if (HAS_THRESHOLD) rdata <= th[read_register_idx*PRIORITY_BITS+:PRIORITY_BITS];
            ID: rdata <= id[read_register_idx*SOURCES_BITS+:SOURCES_BITS];
            default: ;
         endcase

endmodule : plic_dynamic_registers

