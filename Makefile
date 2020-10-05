TOPLEVEL_LANG = verilog
VERILOG_SOURCES = \
	$(PWD)/debug_verilator_coco.v
TOPLEVEL = debug_verilator_coco
MODULE = debug_verilator_coco
EXTRA_ARGS += --trace --trace-structs
SIM = verilator
export COCOTB_REDUCED_LOG_FMT = 0
export COCOTB_SCHEDULER_DEBUG = 1
export COCOTB_LOG_LEVEL = DEBUG

include $(shell cocotb-config --makefiles)/Makefile.sim
