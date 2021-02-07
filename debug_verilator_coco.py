# NOT FOR REDISTRIBUTION AND PRACTICAL USE IN ANY DESIGNS, ONLY FOR COCOTB/VERILTOR INTERACTION DEGUGGING

import random
import cocotb
import subprocess
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.triggers import RisingEdge
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer
from cocotb.result import TestError

import asyncio


async def write_fifo(dut, vals):
    w_cnt = 0
    while True:
        cocotb.log.info(f"In write proc.")
        for _ in range(random.randrange(1, 32)):
            await FallingEdge(dut.clk_w_i)
        if dut.full_o == 0:
            cocotb.log.info(f"Random write number {w_cnt}.")
            dut.wen_i <= 1
            dut.wdata_i <= vals[w_cnt]
            await RisingEdge(dut.clk_w_i)
            dut.wen_i <= 0
            w_cnt = w_cnt + 1


async def read_fifo(dut, vals):
    r_cnt = 0
    while True:
        cocotb.log.info(f"In read proc.")
        for _ in range(random.randrange(0, 12)):
            await FallingEdge(dut.clk_r_i)
        if dut.empty_o == 0:
            cocotb.log.info(f"Random read number {r_cnt}.")
            dut.ren_i <= 1
            await RisingEdge(dut.clk_r_i)
            dut.ren_i <= 0
            await FallingEdge(dut.clk_r_i)
            assert dut.rdata_o == vals[r_cnt], f"Read Data mismatch at value {r_cnt}, got {hex(int(dut.rdata_o))} but expected {hex(int(vals[r_cnt]))}"
            r_cnt = r_cnt + 1


@cocotb.test()
async def test_afifo(dut):

    vals = [random.randrange(1, 2**41) for _ in range(2**16)]

    # reset
    cocotb.log.info(f"Reset AFIFO on both sides.")
    dut.rst_w_an_i <= 0
    dut.rst_r_an_i <= 0
    await Timer(1, units='us')
    dut.rst_w_an_i <= 1
    dut.rst_r_an_i <= 1
    await Timer(1, units='us')

    # randomize
    #for w_ns, r_ns in [(3, 7), (20, 20), (50, 11)]:
    for w_ns, r_ns in [(20, 20), (3, 7), (50, 11)]:
    #for w_ns, r_ns in [(50, 11), (3, 7), (20, 20)]:
        cocotb.log.info(f"Test random read/write. Write Period is {w_ns}ns, read period is {r_ns}ns.")
        clk_w = Clock(dut.clk_w_i, w_ns, units="ns")
        clk_w_fork = cocotb.fork(clk_w.start())  # Start the write clock
        clk_r = Clock(dut.clk_r_i, r_ns, units="ns")
        clk_r_fork = cocotb.fork(clk_r.start())  # Start the read clock
        w_fork = cocotb.fork(write_fifo(dut, vals))
        r_fork = cocotb.fork(read_fifo(dut, vals))
        await ClockCycles(dut.clk_r_i, 1000)
        await FallingEdge(dut.clk_w_i)
        clk_w_fork.kill() # enforce reading until empty
        if dut.empty_o != 1:
            await RisingEdge(dut.empty_o)
        clk_r_fork.kill()
        w_fork.kill()
        r_fork.kill()
        await Timer(1, units='us')
