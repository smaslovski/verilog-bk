# verilog-bk
Small project to emulate a few behavioral aspects of the 1801BM1 CPU and the Soviet computers BK-0010/0011M.

This is a small and lightweight Verilog-based project that emulates some behavioral aspects
of the 1801BM1 CPU and the components found on the PCB of "БК-0011М" (BK-0011M) computer.
BK-0011M was a popular PDP-compatible 16-bit home computer produced in the U.S.S.R. in 1980s.

The purpose of this project is to test extension circuits for this computer at early design stages.
Currently (June 12, 2020), only the code for the CPU bus write cycle is implemented in the CPU emulator,
and the only extensions being tested are 3 variants of AY-3-8910/YM2149 interface circuits.

Yes, I am well aware of the great projects put forward by Viacheslav (Slava) 1801BM1
(https://github.com/1801BM1/cpu11) and by lvd2 (https://github.com/lvd2/ay-3-8910_reverse_engineered),
but my point here is not to reinvent the weel: it is just to have fun!

It is possible that some of the modules from this project could be later included in other
projects that deal with emulation of old computers (both in software and in hardware).
