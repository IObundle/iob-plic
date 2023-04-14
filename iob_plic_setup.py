#!/usr/bin/env python3

import os, sys
sys.path.insert(0, os.getcwd()+'/submodules/LIB/scripts')
import setup

name='iob_plic'
version='V0.10'
flows='sim emb'
if setup.is_top_module(sys.modules[__name__]):
    setup_dir=os.path.dirname(__file__)
    build_dir=f"../{name}_{version}"
submodules = {
    'hw_setup': {
        'headers' : [ 'iob_s_port', 'iob_s_portmap', 'iob_wire' ],
        'modules': [  ]
    },
}

confs = \
[
    # Macros

    # Parameters
    # IOb-bus Parameters
    {'name':'DATA_W',  'type':'P', 'val':'32', 'min':'NA', 'max':'NA', 'descr':"Data bus width"},
    {'name':'ADDR_W',  'type':'P', 'val':'16', 'min':'NA', 'max':'NA', 'descr':"Address bus width"},
    # PLIC Parameters
    {'name':'N_SOURCES', 'type':'P', 'val':'64',  'min':'NA', 'max':'64',  'descr':"Number of interrupt sources"},
    {'name':'N_TARGETS', 'type':'P', 'val':'4',  'min':'NA', 'max':'8',  'descr':"Number of interrupt targets"},
    {'name':'PRIORITIES', 'type':'P', 'val':'8',  'min':'NA', 'max':'8',  'descr':"Number of Priority levels"},
    {'name':'MAX_PENDING_COUNT', 'type':'P', 'val':'8',  'min':'NA', 'max':'8',  'descr':"Max. number of 'pending' events"},
    {'name':'HAS_THRESHOLD', 'type':'P', 'val':'1',  'min':'NA', 'max':'1',  'descr':"Is 'threshold' implemented?"},
    {'name':'HAS_CONFIG_REG', 'type':'P', 'val':'1',  'min':'NA', 'max':'1',  'descr':"Is the 'configuration' register implemented?"},
]

ios = \
[
    {'name': 'iob_s_port', 'descr':'CPU native interface', 'ports': [
    ]},
    {'name': 'general', 'descr':'GENERAL INTERFACE SIGNALS', 'ports': [
        {'name':"clk_i" , 'type':"I", 'n_bits':'1', 'descr':"System clock input"},
        {'name':"arst_i", 'type':"I", 'n_bits':'1', 'descr':"System reset, asynchronous and active high"},
        {'name':"cke_i" , 'type':"I", 'n_bits':'1', 'descr':"System reset, asynchronous and active high"}
    ]},
    {'name': 'plic_io', 'descr':'PLIC specific IO.', 'ports': [
        #{'name':'interrupt', 'type':'O', 'n_bits':'1', 'descr':'be done'},
        {'name':'src', 'type':'I', 'n_bits':'N_SOURCES', 'descr':'Interrupt sources'},
        {'name':'irq', 'type':'O', 'n_bits':'N_TARGETS', 'descr':'Interrupt Requests'},
    ]}
]

regs = [
    {'name': 'dummy', 'descr':'Dummy registers to run register setup functions', 'regs': [
        {'name':"DUMMY", 'type':"R", 'n_bits':1, 'rst_val':0, 'addr':-1, 'log2n_items':0, 'autologic':False, 'descr':"Dummy Register"},
    ]}
]

blocks = []

# Main function to setup this core and its components
def main():
    setup.setup(sys.modules[__name__])

if __name__ == "__main__":
    main()
