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
    cocotb.log.info(f"In write proc.")
    while True:
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
    cocotb.log.info(f"In read proc.")
    while True:
        for _ in range(random.randrange(0, 12)):
            await FallingEdge(dut.clk_r_i)
        if dut.empty_o == 0:
            cocotb.log.info(f"Random read number {r_cnt}.")
            dut.ren_i <= 1
            await RisingEdge(dut.clk_r_i)
            dut.ren_i <= 0
            await FallingEdge(dut.clk_r_i)
            cocotb.log.info(f"Read Data: {dut.rdata_o}")
            r_cnt = r_cnt + 1


@cocotb.test()
async def test_afifo(dut):
    """ Test that data is being passed across clock domains. """

    clk_w = Clock(dut.clk_w_i, 10, units="ns")  # Create a 10ns period clock on port clk
    cocotb.fork(clk_w.start())  # Start the write clock
    clk_r = Clock(dut.clk_r_i, 37, units="ns")  # Create a 37ns period clock on port clk
    cocotb.fork(clk_r.start())  # Start the read clock
    vals = [random.randrange(1, 2**32) for _ in range(2**16)]

    # reset, disable divs
    cocotb.log.info(f"Reset AFIFO on both sides.")
    dut.rst_w_an_i <= 0
    dut.rst_r_an_i <= 0
    await FallingEdge(dut.clk_w_i)

    # deassert reset, check non full, but empty
    dut.rst_w_an_i <= 1
    dut.rst_r_an_i <= 1

    # fill
    cocotb.log.info(f"Fill FIFO with random values.")
    for i in range(4):
        await FallingEdge(dut.clk_w_i)
        assert dut.full_o == 0, f"Status full_o was asserted already after {i} samples."
        dut.wen_i <= 1
        dut.wdata_i <= vals[i]
        await RisingEdge(dut.clk_w_i)
        dut.wen_i <= 0
        if i == 0:
            # check after first write that the empty flag goes low on read side (wait for sync)
            for i in range(3):
                await FallingEdge(dut.clk_r_i)
            assert dut.empty_o == 0, f"Status empty_o was still asserted after {i} writes."
            await FallingEdge(dut.clk_w_i)
    await FallingEdge(dut.clk_w_i)

    # read until empty
    cocotb.log.info(f"Read back previously written data.")
    for i in range(4):
        await FallingEdge(dut.clk_r_i)
        assert dut.empty_o == 0, f"Status empty_o was asserted already after {i} samples."
        dut.ren_i <= 1
        await RisingEdge(dut.clk_r_i)
        dut.ren_i <= 0
        await FallingEdge(dut.clk_r_i)
        assert dut.rdata_o == vals[i], f"Read Data mismatch at read {i}, got {hex(int(dut.rdata_o))} but expected {hex(int(vals[i]))}"
        if i == 0:
            # check after first read that the full flag goes low on write side (wait for sync)
            for i in range(3):
                await FallingEdge(dut.clk_w_i)
            assert dut.full_o == 0, f"Status full_o was still asserted after {i} reads."
            await FallingEdge(dut.clk_r_i)
    await FallingEdge(dut.clk_r_i)

    # randomize
    cocotb.log.info(f"Test random read/write.")
    cocotb.fork(write_fifo(dut, vals))
    cocotb.fork(read_fifo(dut, vals))
    # await ClockCycles(dut.clk_r_i, 1000)  # uncomment this, it will cause to process all 1000 edges at once and exit with pass erroneously
    await Timer(10000, units="us") # uncomment this for second scenario where sim gets stuck without the other forked coroutines progressing








