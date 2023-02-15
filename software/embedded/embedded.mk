ifeq ($(filter PLIC, $(SW_MODULES)),)

#add itself to MODULES list
SW_MODULES+=PLIC

include $(PLIC_DIR)/software/software.mk

#embeded sources
SRC+=$(PLIC_SW_DIR)/embedded/iob_plic.c

endif
