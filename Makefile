PLIC_DIR:=.

include ./config.mk

#
# SIMULATE RTL
#

sim-build:
	make -C $(PLIC_SIM_DIR) build

sim-run: sim-build
	make -C $(PLIC_SIM_DIR) run

sim-clean:
	make -C $(PLIC_SIM_DIR) clean

sim: sim-run sim-clean

.PHONY: sim-build sim-run sim-clean
