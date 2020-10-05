Make sure to have verilator 4.100 and cocotob 1.4 with Python 3.7+ in PATH, then run

`make`

In Python file look at the bottom.
You can choose either the option where multiple triggers get processed at once
without advancing sim time. The other version with the Timer will freeze the simulation after handing back to verilator,
the other coroutines do not progress anymore. Need to be killed from task manager or CLI, Ctrl+C does not work, it is stuck really firmly.

This repo is an example to address:

https://github.com/cocotb/cocotb/issues/2096#

https://github.com/verilator/verilator/issues/2536