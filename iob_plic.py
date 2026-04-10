# SPDX-FileCopyrightText: 2025 IObundle
#
# SPDX-License-Identifier: MIT


def setup(py_params_dict):
    CSR_IF = py_params_dict["csr_if"] if "csr_if" in py_params_dict else "iob"

    IF_DISPLAY_NAME = {
        "iob": "IOb",
        "axil": "AXI-Lite",
        "wb": "Wishbone",
    }

    attributes_dict = {
        "generate_hw": True,
        "description": "IObundle's Platform-Level Interrupt Controller (PLIC).",
        "version": "0.1.0",
        #
        # Confs
        #
        "confs": [
            # IOb-bus Parameters
            {
                "name": "DATA_W",
                "descr": "Data bus width",
                "type": "P",
                "val": 32,
                "min": "NA",
                "max": "NA",
            },
            {
                "name": "ADDR_W",
                "descr": "Address bus width",
                "type": "P",
                "val": 22,
                "min": "NA",
                "max": "NA",
            },
            # PLIC Parameters
            {
                "name": "N_SOURCES",
                "descr": "Number of interrupt sources",
                "type": "P",
                "val": 63,
                "min": "NA",
                "max": 64,
            },
            {
                "name": "N_TARGETS",
                "descr": "Number of interrupt targets",
                "type": "P",
                "val": 4,
                "min": "NA",
                "max": 8,
            },
            {
                "name": "PRIORITIES",
                "descr": "Number of Priority levels",
                "type": "P",
                "val": 8,
                "min": "NA",
                "max": 8,
            },
            {
                "name": "MAX_PENDING_COUNT",
                "descr": "Max. number of 'pending' events",
                "type": "P",
                "val": 8,
                "min": "NA",
                "max": 8,
            },
            {
                "name": "HAS_THRESHOLD",
                "descr": "Is 'threshold' implemented?",
                "type": "P",
                "val": 1,
                "min": "NA",
                "max": 1,
            },
            {
                "name": "HAS_CONFIG_REG",
                "descr": "Is the 'configuration' register implemented?",
                "type": "P",
                "val": 1,
                "min": "NA",
                "max": 1,
            },
        ],
        #
        # Ports
        #
        "ports": [
            {
                "name": "clk_en_rst_s",
                "descr": "Clock, clock enable and reset",
                "signals": {
                    "type": "iob_clk",
                },
            },
            {
                "name": "interrupt_i",
                "descr": "Interrupt sources",
                "signals": [
                    {
                        "name": "src_i",
                        "descr": "Interrupt sources + bit 0 reserved",
                        "width": "N_SOURCES + 1",
                    },
                ],
            },
            {
                "name": "interrupt_o",
                "descr": "RISC-V interrupt interface",
                "signals": [
                    {
                        "name": "meip_o",
                        "descr": "Machine external interrupt.",
                        "width": "N_TARGETS",
                    },
                    {
                        "name": "seip_o",
                        "descr": "Supervisor external interrupt.",
                        "width": "1",
                    },
                ],
            },
            {
                "name": "csrs_cbus_s",
                "descr": f"Control and status interface, when selecting the {IF_DISPLAY_NAME[CSR_IF]} CSR interface.",
                "signals": {
                    "type": CSR_IF,
                    "ADDR_W": 22,
                    "DATA_W": 32,
                    "STRB_W": 4,
                },
            },
        ],
        #
        # Wires
        #
        "wires": [
            {
                "name": "internal_wires",
                "descr": "",
                "signals": [
                    # IOb-bus write action
                    {"name": "iob_write", "width": 1},
                    {"name": "iob_we", "width": 1},
                    {"name": "iob_re", "width": 1},
                    # Decoded registers
                    {"name": "el", "width": "N_SOURCES+1"},
                    {"name": "p", "width": "(N_SOURCES+1)*PRIORITY_BITS"},
                    {"name": "ie", "width": "N_TARGETS*(N_SOURCES+1)"},
                    {"name": "th", "width": "N_TARGETS*PRIORITY_BITS"},
                    {"name": "id", "width": "N_TARGETS*SOURCES_BITS"},
                    #
                    {"name": "claim", "width": "N_TARGETS"},
                    {"name": "complete", "width": "N_TARGETS"},
                    #
                    {"name": "ip_core", "width": "N_SOURCES"},
                    {"name": "ie_core", "width": "N_TARGETS*N_SOURCES"},
                ],
            },
        ],
        #
        # Subblocks
        #
        "subblocks": [
            {  # Currently used for docs only
                "core_name": "iob_csrs",
                "instantiate": False,
                "instance_name": "csrs",
                "instance_description": "Control/Status Registers",
                "csrs": [
                    {
                        "name": "dummy_reg",
                        "descr": "Dummy register for demo",
                        "type": "NOAUTO",
                        "mode": "R",
                        "n_bits": 32,
                        "rst_val": 0,
                        "log2n_items": 20,
                        # "addr": 0x8000,
                    },
                ],
                "csr_if": "iob",
                "connect": {
                    "clk_en_rst_s": "clk_en_rst_s",
                    # 'control_if_m' port connected automatically
                },
            },
        ],
        "sw_modules": [
            # Software modules
            {
                "core_name": "iob_linux_device_drivers",
                "compatible_str": "riscv,plic0",
                # Extra device tree properties specific to this peripheral
                "dts_extra_properties": r"""
        #address-cells = <0>; // No sub-nodes expected under PLIC (leaf interrupt controller)
        #interrupt-cells = <1>; // PLIC interrupt specifiers use 1 cell: the interrupt ID number
        interrupt-controller; // Declares this node as an interrupt controller
        // PLIC context connections to CPU interrupt controller:
        // Context 0 on CPU0 IRQ 11, Context 1 on CPU0 IRQ 9 (for M-mode/S-mode)
        interrupts-extended = < &CPU0_intc 11
                                &CPU0_intc 9 >;
        reg-names = "control"; // Names the register region ("control" for PLIC CSRs)
        riscv,max-priority = <7>; // Maximum interrupt priority level supported (0-7 scale)
        riscv,ndev = <31>; // Number of external interrupt sources/lines supported by this PLIC (1-31
""",
            },
        ],
        #
        # Snippets
        #
        "snippets": [
            {
                "verilog_code": """
   // Local parameters
   localparam SOURCES_BITS = $clog2(N_SOURCES + 1);  //0=reserved
   localparam PRIORITY_BITS = $clog2(PRIORITIES);

   genvar t_idx;
   generate
      for (t_idx = 0; t_idx < N_TARGETS; t_idx = t_idx + 1) begin : g_ie_shift
         assign ie_core[t_idx*N_SOURCES +: N_SOURCES] = ie[t_idx*(N_SOURCES+1) + 1 +: N_SOURCES];
      end
   endgenerate

   /** APB Read/Write */
   assign iob_write = |iob_wstrb_i;
   assign iob_re    = iob_valid_i & ~iob_write;
   assign iob_we    = iob_valid_i & iob_write;


   // Module intanciation

   /** Hookup Dynamic Register block
   */
   plic_dynamic_registers #(
      //Bus Interface Parameters
      .ADDR_SIZE(ADDR_W),
      .DATA_SIZE(DATA_W),

      //PLIC Parameters
      .SOURCES          (N_SOURCES + 1),
      .TARGETS          (N_TARGETS),
      .PRIORITIES       (PRIORITIES),
      .MAX_PENDING_COUNT(MAX_PENDING_COUNT),
      .HAS_THRESHOLD    (HAS_THRESHOLD),
      .HAS_CONFIG_REG   (HAS_CONFIG_REG),
      .SOURCES_BITS     (SOURCES_BITS),
      .PRIORITY_BITS    (PRIORITY_BITS)
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

      .el      (el),               //Edge/Level
      .ip      ({ip_core, 1'b0}),  //Interrupt Pending (Source 0 is never pending)
      .ie      (ie),               //Interrupt Enable
      .p       (p),                //Priority
      .th      (th),               //Priority Threshold
      .id      (id),               //Interrupt ID
      .claim   (claim),            //Interrupt Claim
      .complete(complete)          //Interrupt Complete
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

      .src      (src_i[N_SOURCES:1]),
      .el       (el[N_SOURCES:1]),
      .ip       (ip_core),
      .ie       (ie_core),
      .ipriority(p[(N_SOURCES+1)*PRIORITY_BITS-1:PRIORITY_BITS]),
      .threshold(th),

      .ireq    (meip_o),
      .id      (id),
      .claim   (claim),
      .complete(complete)
   );

   assign seip_o = 1'b0; // Supervisor Interrupt unused

""",
            },
        ],
    }
    #
    # Combs
    #
    attributes_dict["comb"] = {
        "code": """
    // Interface Registers

    iob_rvalid_o_en = ~iob_write;
    iob_rvalid_o_nxt = iob_valid_i;

    // Ready signal, is always 1 since the read and write to the PLIC only take one clock cycle.
    iob_ready_o = 1'b1;

"""
    }

    return attributes_dict
