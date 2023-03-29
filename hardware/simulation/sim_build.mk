# SOURCES
SIMULATOR:=verilator
ifeq ($(SIMULATOR),verilator)
# verilator top module
VTOP:=iob_plic_sim_wrapper
endif

#tests
TEST_LIST+=test1
test1:
	make run SIMULATOR=$(SIMULATOR)
