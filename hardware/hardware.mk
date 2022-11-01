include $(PLIC_DIR)/config.mk

#add itself to MODULES list
HW_MODULES+=PLIC

#HARDWARE PATHS
PLIC_INC_DIR:=$(PLIC_HW_DIR)/include
PLIC_SRC_DIR:=$(PLIC_HW_DIR)/src

#INCLUDES
INCLUDE+=$(incdir). $(incdir)$(PLIC_INC_DIR)

#headers
VHDR+=$(wildcard $(PLIC_INC_DIR)/*.vh)

#sources
VSRC+=$(wildcard $(PLIC_SRC_DIR)/*.v)
VSRC+=$(wildcard $(PLIC_SRC_DIR)/*.sv)

#clean general hardware files
plic_hw_clean: plic_gen_clean
	@rm -f *.vh

.PHONY: hw-clean
