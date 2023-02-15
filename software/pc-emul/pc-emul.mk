ifeq ($(filter PLIC, $(SW_MODULES)),)

#add itself to MODULES list
SW_MODULES+=PLIC

#uart common parameters
include $(PLIC_DIR)/software/software.mk

# add pc-emul sources
SRC+=$(PLIC_SW_DIR)/pc-emul/plic_swreg_pc_emul.c

endif
