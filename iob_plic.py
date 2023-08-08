#!/usr/bin/env python3

import os

from iob_module import iob_module

# Submodules
from iob_utils import iob_utils
from iob_reg_re import iob_reg_re


class iob_plic(iob_module):
    name = "iob_plic"
    version = "V0.10"
    flows = "sim emb"
    setup_dir = os.path.dirname(__file__)

    @classmethod
    def _create_submodules_list(cls):
        """Create submodules list with dependencies of this module"""
        super()._create_submodules_list(
            [
                {"interface": "iob_s_port"},
                {"interface": "iob_s_portmap"},
                {"interface": "iob_wire"},
                {"interface": "clk_en_rst_s_s_portmap"},
                {"interface": "clk_en_rst_s_port"},
                iob_utils,
                iob_reg_re,
            ]
        )

    @classmethod
    def _setup_confs(cls):
        super()._setup_confs(
            [
                # Macros
                # Parameters
                # IOb-bus Parameters
                {
                    "name": "DATA_W",
                    "type": "P",
                    "val": "32",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Data bus width",
                },
                {
                    "name": "ADDR_W",
                    "type": "P",
                    "val": "16",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Address bus width",
                },
                # PLIC Parameters
                {
                    "name": "N_SOURCES",
                    "type": "P",
                    "val": "64",
                    "min": "NA",
                    "max": "64",
                    "descr": "Number of interrupt sources",
                },
                {
                    "name": "N_TARGETS",
                    "type": "P",
                    "val": "4",
                    "min": "NA",
                    "max": "8",
                    "descr": "Number of interrupt targets",
                },
                {
                    "name": "PRIORITIES",
                    "type": "P",
                    "val": "8",
                    "min": "NA",
                    "max": "8",
                    "descr": "Number of Priority levels",
                },
                {
                    "name": "MAX_PENDING_COUNT",
                    "type": "P",
                    "val": "8",
                    "min": "NA",
                    "max": "8",
                    "descr": "Max. number of 'pending' events",
                },
                {
                    "name": "HAS_THRESHOLD",
                    "type": "P",
                    "val": "1",
                    "min": "NA",
                    "max": "1",
                    "descr": "Is 'threshold' implemented?",
                },
                {
                    "name": "HAS_CONFIG_REG",
                    "type": "P",
                    "val": "1",
                    "min": "NA",
                    "max": "1",
                    "descr": "Is the 'configuration' register implemented?",
                },
            ]
        )

    @classmethod
    def _setup_ios(cls):
        cls.ios += [
            {"name": "iob_s_port", "descr": "CPU native interface", "ports": []},
            {
                "name": "general",
                "descr": "GENERAL INTERFACE SIGNALS",
                "ports": [
                    {
                        "name": "clk_i",
                        "type": "I",
                        "n_bits": "1",
                        "descr": "System clock input",
                    },
                    {
                        "name": "arst_i",
                        "type": "I",
                        "n_bits": "1",
                        "descr": "System reset, asynchronous and active high",
                    },
                    {
                        "name": "cke_i",
                        "type": "I",
                        "n_bits": "1",
                        "descr": "System clock enable",
                    },
                ],
            },
            {
                "name": "plic_io",
                "descr": "PLIC specific IO.",
                "ports": [
                    # {'name':'interrupt', 'type':'O', 'n_bits':'1', 'descr':'be done'},
                    {
                        "name": "src",
                        "type": "I",
                        "n_bits": "N_SOURCES",
                        "descr": "Interrupt sources",
                    },
                    {
                        "name": "irq",
                        "type": "O",
                        "n_bits": "N_TARGETS",
                        "descr": "Interrupt Requests",
                    },
                ],
            },
        ]

    @classmethod
    def _setup_regs(cls):
        cls.regs += [
            {
                "name": "dummy",
                "descr": "Dummy registers to run register setup functions",
                "regs": [
                    {
                        "name": "DUMMY",
                        "type": "R",
                        "n_bits": 1,
                        "rst_val": 0,
                        "addr": 0x8000,
                        "log2n_items": 0,
                        "autologic": False,
                        "descr": "Dummy Register",
                    },
                ],
            }
        ]

    @classmethod
    def _setup_block_groups(cls):
        cls.block_groups += []
