######################################################################
#
# PLIC Configuration File
#
######################################################################

SHELL = bash

TOP_MODULE:=iob_plic

#
# PRIMARY PARAMETERS: CAN BE CHANGED BY USERS OR OVERRIDEN BY ENV VARS
#

#CPU ARCHITECTURE
DATA_W ?=32
ADDR_W ?=16
#PLIC ARCHITECTURE
N_SOURCES ?=32
N_TARGETS ?=1

#PLIC DIRECTORY ON REMOTE MACHINES
REMOTE_PLIC_DIR ?=sandbox/iob_plic

#SIMULATION
#default simulator running locally or remotely
#check the respective Makefile in hardware/simulation/$(SIMULATOR) for specific settings
SIMULATOR ?=verilator

####################################################################
# DERIVED FROM PRIMARY PARAMETERS: DO NOT CHANGE BELOW THIS POINT
####################################################################

#sw paths
PLIC_SW_DIR=$(PLIC_DIR)/software

#hw paths
PLIC_HW_DIR=$(PLIC_DIR)/hardware
PLIC_SIM_DIR=$(PLIC_HW_DIR)/simulation/$(SIMULATOR)


#RULES
plic_gen_clean:
	@rm -f *# *~

.PHONY: gen-clean
