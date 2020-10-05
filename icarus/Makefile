TOPLEVEL_LANG = verilog
VERILOG_SOURCES = \
    $(PWD)/../debug_verilator_coco.v
TOPLEVEL = debug_verilator_coco
MODULE = debug_verilator_coco
export PYTHONPATH=..
SIM = icarus

include $(shell cocotb-config --makefiles)/Makefile.sim
