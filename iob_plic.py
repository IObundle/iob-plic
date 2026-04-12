# SPDX-FileCopyrightText: 2025 IObundle
#
# SPDX-License-Identifier: MIT


def setup(py_params_dict):
    CSR_IF = py_params_dict.get("csr_if", "iob")

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
            # PLIC False-Parameters. Don't change them. They are currently hardcoded.
            {
                "name": "N_SOURCES",
                "descr": "Number of interrupt sources",
                "type": "D",
                "val": 31,
                "min": "NA",
                "max": 63,
            },
            {
                "name": "N_TARGETS",
                "descr": "Number of interrupt targets",
                "type": "D",
                "val": 2,
                "min": "NA",
                "max": 8,
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
                        "width": 1,
                    },
                    {
                        "name": "seip_o",
                        "descr": "Supervisor external interrupt.",
                        "width": 1,
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
    }
    # Document all supported CSR interfaces
    for supported_if in ["iob", "axil", "wb"]:
        # CSR_IF has already been documented previously. Only document other supported interfaces.
        if CSR_IF != supported_if:
            attributes_dict["ports"].insert(
                2,
                {
                    "name": f"csrs_cbus_{supported_if}_s",
                    "doc_only": True,
                    "descr": f"Control and status interface, when selecting the {IF_DISPLAY_NAME[supported_if]} CSR interface.",
                    "signals": {
                        "type": supported_if,
                        "ADDR_W": 5,
                        "DATA_W": 32,
                        "STRB_W": 4,
                    },
                },
            )

    attributes_dict |= {
        #
        # Wires
        #
        "wires": [
            {
                "name": "internal_axil_cbus",
                "descr": "AXI-Lite CSRs bus",
                "signals": {
                    "type": "axil",
                    "prefix": "internal_",
                    "ADDR_W": "ADDR_W",
                },
            },
        ],
        #
        # Subblocks
        #
        "subblocks": [
            {
                "core_name": "iob_universal_converter",
                "instance_name": "universal_converter",
                "instance_description": "Convert CSRs interface into internal AXI-Lite bus",
                "subordinate_if": CSR_IF,
                "manager_if": "axil",
                "parameters": {
                    "ADDR_W": "ADDR_W",
                    "DATA_W": "DATA_W",
                },
                "connect": {
                    "clk_en_rst_s": "clk_en_rst_s",
                    "s_s": "csrs_cbus_s",
                    "m_m": "internal_axil_cbus",
                },
            },
            {  # Currently only used for docs and Linux driver auto-generation. Does not affect hardware.
                "core_name": "iob_csrs",
                "instantiate": False,
                "instance_name": "csrs",
                "instance_description": "Control/Status Registers",
                "autoaddr": False,
                "csrs": [
                    # Notes on this Mapping:
                    #  1. n_bits:
                    #      * priority and threshold are 2 bits (as configured in the SpinalHDL script).
                    #      * claim_complete is 5 bits (enough to hold IDs 0-31).
                    #      * pending and enable are 32 bits (packed words).
                    #  2. Base Addresses: These match the PlicMapping.sifive defaults used during generation.
                    #  3. Target Strides: Target 0 is at offset 0, Target 1 is at offset 0x1000 for context registers and 0x80 for enable registers.
                    #
                    # --- Interrupt Priorities (1 register per source) ---
                    {
                        "name": "priority_csr",  # 'priority' is a reserved keyword in verilog
                        "addr": 0x000000,
                        "mode": "RW",
                        "n_bits": 32,  # Only 2 bits used for priority, but set 32 to generate log2n_items array correctly.
                        "rst_val": 0,
                        "log2n_items": 5,  # 31 sources + 1 reserved
                        "descr": "Interrupt source priority. ID 0 is reserved. Source 1 starts at 0x4, Source 2 at 0x8, etc.",
                    },
                    # --- Pending Bits (Packed into 32-bit registers) ---
                    {
                        "name": "pending",
                        "addr": 0x001000,
                        "mode": "R",
                        "n_bits": 32,
                        "rst_val": 0,
                        "log2n_items": 0,
                        "descr": "Interrupt pending bits. Bit [i] indicates if Source ID i is pending.",
                    },
                    # --- Target 0 (Machine Mode) Enables ---
                    {
                        "name": "target0_enable",
                        "addr": 0x002000,
                        "mode": "RW",
                        "n_bits": 32,
                        "rst_val": 0,
                        "log2n_items": 0,
                        "descr": "Interrupt enable bits for Target 0 (Context 0 - Machine Mode).",
                    },
                    # --- Target 1 (Supervisor Mode) Enables ---
                    {
                        "name": "target1_enable",
                        "addr": 0x002080,
                        "mode": "RW",
                        "n_bits": 32,
                        "rst_val": 0,
                        "log2n_items": 0,
                        "descr": "Interrupt enable bits for Target 1 (Context 1 - Supervisor Mode).",
                    },
                    # --- Target 0 (Machine Mode) Context Control ---
                    {
                        "name": "target0_threshold",
                        "addr": 0x200000,
                        "mode": "RW",
                        "n_bits": 2,
                        "rst_val": 0,
                        "log2n_items": 0,
                        "descr": "Priority threshold for Target 0. Interrupts <= threshold are masked.",
                    },
                    {
                        "name": "target0_claim_complete",
                        "addr": 0x200004,
                        "mode": "RW",
                        "n_bits": 5,  # log2(31 sources)
                        "rst_val": 0,
                        "log2n_items": 0,
                        "descr": "Claim register when read, Complete register when written for Target 0.",
                    },
                    # --- Target 1 (Supervisor Mode) Context Control ---
                    {
                        "name": "target1_threshold",
                        "addr": 0x201000,
                        "mode": "RW",
                        "n_bits": 2,
                        "rst_val": 0,
                        "log2n_items": 0,
                        "descr": "Priority threshold for Target 1. Interrupts <= threshold are masked.",
                    },
                    {
                        "name": "target1_claim_complete",
                        "addr": 0x201004,
                        "mode": "RW",
                        "n_bits": 5,  # log2(31 sources)
                        "rst_val": 0,
                        "log2n_items": 0,
                        "descr": "Claim register when read, Complete register when written for Target 1.",
                    },
                ],
                "csr_if": CSR_IF,
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
        //riscv,max-priority = <4>; // Maximum interrupt priority level supported (0-4 scale)
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
   PlicVerilog plice_core_inst (
      .io_sources(src_i[N_SOURCES:1]),  // bit 0 reserved
      .io_targets({seip_o, meip_o}),  // Matches mapping in device tree: `interrupts-extended = <&cpu0_intc 11 &cpu0_intc 9>;`
      .io_axilite_aw_valid(internal_axil_awvalid),
      .io_axilite_aw_ready(internal_axil_awready),
      .io_axilite_aw_payload_addr(internal_axil_awaddr),
      .io_axilite_aw_payload_prot(internal_axil_awprot),
      .io_axilite_w_valid(internal_axil_wvalid),
      .io_axilite_w_ready(internal_axil_wready),
      .io_axilite_w_payload_data(internal_axil_wdata),
      .io_axilite_w_payload_strb(internal_axil_wstrb),
      .io_axilite_b_valid(internal_axil_bvalid),
      .io_axilite_b_ready(internal_axil_bready),
      .io_axilite_b_payload_resp(internal_axil_bresp),
      .io_axilite_ar_valid(internal_axil_arvalid),
      .io_axilite_ar_ready(internal_axil_arready),
      .io_axilite_ar_payload_addr(internal_axil_araddr),
      .io_axilite_ar_payload_prot(internal_axil_arprot),
      .io_axilite_r_valid(internal_axil_rvalid),
      .io_axilite_r_ready(internal_axil_rready),
      .io_axilite_r_payload_data(internal_axil_rdata),
      .io_axilite_r_payload_resp(internal_axil_rresp),
      .clk(clk_i),
      .resetn(~arst_i)
   );
""",
            },
        ],
    }

    return attributes_dict
