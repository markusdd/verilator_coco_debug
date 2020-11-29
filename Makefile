TOPLEVEL_LANG = verilog
VERILOG_SOURCES = \
	$(PWD)/debug_verilator_coco.v
TOPLEVEL = debug_verilator_coco
MODULE = debug_verilator_coco
EXTRA_ARGS += --trace-fst --trace-structs -CFLAGS -DTRACE_FST

SIM = verilator
export COCOTB_REDUCED_LOG_FMT = 1
# export COCOTB_SCHEDULER_DEBUG = 1
export COCOTB_LOG_LEVEL = INFO

include $(shell cocotb-config --makefiles)/Makefile.sim
