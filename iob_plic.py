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
        "version": "0.1",
        #
        # Confs
        #
        "confs": [
            # IOb-bus Parameters
            {
                "name": "DATA_W",
                "descr": "Data bus width",
                "type": "P",
                "val": "32",
                "min": "NA",
                "max": "NA",
            },
            {
                "name": "ADDR_W",
                "descr": "Address bus width",
                "type": "P",
                "val": "16",
                "min": "NA",
                "max": "NA",
            },
            # PLIC Parameters
            {
                "name": "N_SOURCES",
                "descr": "Number of interrupt sources",
                "type": "P",
                "val": "64",
                "min": "NA",
                "max": "64",
            },
            {
                "name": "N_TARGETS",
                "descr": "Number of interrupt targets",
                "type": "P",
                "val": "4",
                "min": "NA",
                "max": "8",
            },
            {
                "name": "PRIORITIES",
                "descr": "Number of Priority levels",
                "type": "P",
                "val": "8",
                "min": "NA",
                "max": "8",
            },
            {
                "name": "MAX_PENDING_COUNT",
                "descr": "Max. number of 'pending' events",
                "type": "P",
                "val": "8",
                "min": "NA",
                "max": "8",
            },
            {
                "name": "HAS_THRESHOLD",
                "descr": "Is 'threshold' implemented?",
                "type": "P",
                "val": "1",
                "min": "NA",
                "max": "1",
            },
            {
                "name": "HAS_CONFIG_REG",
                "descr": "Is the 'configuration' register implemented?",
                "type": "P",
                "val": "1",
                "min": "NA",
                "max": "1",
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
                "name": "plic_io",
                "descr": "",
                "signals": [
                    # {'name':'interrupt_o', 'width':'1', 'descr':'be done'},
                    {
                        "name": "src_i",
                        "descr": "Interrupt sources",
                        "width": "N_SOURCES",
                    },
                    {
                        "name": "irq_o",
                        "descr": "Interrupt Requests",
                        "width": "N_TARGETS",
                    },
                ],
            },
            {
                "name": "csrs_cbus_s",
                "descr": f"Control and status interface, when selecting the {IF_DISPLAY_NAME[CSR_IF]} CSR interface.",
                "signals": {
                    "type": CSR_IF,
                    "ADDR_W": 5,
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
                    {"name": "el", "width": "N_SOURCES"},
                    {"name": "ip", "width": "N_SOURCES"},
                    {"name": "p", "width": "PRIORITY_BITS*N_SOURCES"},
                    {"name": "ie", "width": "N_TARGETS*N_SOURCES"},
                    {"name": "th", "width": "PRIORITY_BITS*N_TARGETS"},
                    {"name": "id", "width": "SOURCES_BITS*N_TARGETS"},
                    #
                    {"name": "claim", "width": "N_TARGETS"},
                    {"name": "complete", "width": "N_TARGETS"},
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
                        "n_bits": 1,
                        "rst_val": 0,
                        "log2n_items": 0,
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

   /** APB Read/Write */
   assign iob_write = |iob_wstrb_i;
   assign iob_re    = iob_avalid_i & ~iob_write;
   assign iob_we    = iob_avalid_i & iob_write;


   // Module intanciation

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
    iob_rvalid_o_nxt = iob_avalid_i;

    // Ready signal, is always 1 since the read and write to the PLIC only take one clock cycle.
    iob_ready_o = 1'b1;

"""
    }

    return attributes_dict
