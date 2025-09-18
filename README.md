# EECS 470

Welcome to the EECS 470 VeriSimpleV Processor!

This is the repository for a 5-stage, pipelined, synthesizable, RISC-V 
processor. VeriSimpleV is based on the common 5-stage pipeline mentioned 
in class and the text.

The processor is unfinished! The provided implementation
*has no hazard detection logic!* To accommodate this, the provided
processor only allows one instruction in the pipeline at a time, to be
absolutely certain there are no hazards. The provided processor is
correct, and it will produce the correct output for all programs, but
it has a miserable CPI of ~4.0.

RISC-V assembly instructions look like:  
```
addi x1, x0, 5    # register 1 = register 0 + 5
```

You should reference our sample assembly programs in `programs/` to
write test cases which expose a buggy processor via either memory
correctness or CPI.

### Files

In this folder, you are provided with most of the code and the entire
build and test system. This is a quick overview of the Makefile and the
verilog files you will be editing. See the lab slides for an extended
discussion.

The VeriSimpleV pipeline is broken up into 9 files in the `verilog/`
folder. There are 3 headers: `sys_defs.svh` defines data structures and
typedefs, `mem.svh` defines memory-specific types, and `ISA.svh` defines 
decoding information used by the ID stage. There are 5 files for the 
pipeline stages: `stage_{if,id,ex,mem,wb}.sv`. The register file is in 
`regfile.sv` and is instantiated inside the ID stage. Finally, the stages 
are tied together by the cpu module in `cpu.sv`.

The `sys_defs.svh` file contains all of the `typedef`s and `define`s
that are used in the pipeline and testbench. The testbench and
associated non-synthesizable verilog can be found in the `test/`
folder. Note that the memory module defined in `test/mem.sv` is
**not synthesizable**.

### Getting Started

Start by removing the provided stalling behavior, then
implement the structural hazard logic.

The stalling behavior is set in the `verilog/cpu.sv` file. You should
open the file and find the `assign` statement where the `if_valid`
signal is set. This is the start of a `valid` bit which is passed
through the stages along with the instruction, and it starts at 1 in the
IF stage due to the `start_valid_on_reset` register. After reset
`if_valid` just reads the valid bit that cycles through to the WB stage,
causing us to insert 4 invalid instructions between every valid one.

Start by assigning `if_valid` to always equal 1.

## Makefile Target Reference

To run a program on the processor, run `make <my_program>.out`. This
will assemble a RISC-V `*.mem` file which will be loaded into `mem.sv`
by the testbench, and will also compile the processor and run the
program.

All of the "`<my_program>.abc`" targets are linked to do both the
executable compilation step and the `.mem` compilation steps if
necessary, so you can run each without needing to run anything else
first.

`make <my_program>.out` should be your main command for running
programs: it creates the `<my_program>.out`, `<my_program>.cpi`,
`<my_program>.wb`, and `<my_program>.ppln` output, CPI, writeback, and
pipeline output files in the `output/` directory. The output file
includes the processor status and the final state of memory, the CPI
file contains the total runtime and CPI calculation, the writeback file
is the list of writes to registers done by the program, and the pipeline
file is the state of each of the pipeline stages as the program is run.

The following Makefile rules are available to run programs on the
processor:

```
# ---- Program Execution ---- #
# These are your main commands for running programs and generating output
make <my_program>.out      <- run a program on simv
                              output *.out, *.cpi, *.wb, and *.ppln files
make <my_program>.syn      <- run a program on syn.simv and do the same

# ---- Executable Compilation ---- #
make build/simv      <- compiles simv from the TESTBENCH and SOURCES
make build/syn.simv  <- compiles syn.simv from TESTBENCH and SYNTH_FILES
make synth/cpu.vg    <- synthesize modules in SOURCES for use in syn.simv
make slack           <- grep the slack status of any synthesized modules

# ---- Program Memory Compilation ---- #
# Programs to run are in the programs/ directory
make programs/mem/<my_program>.mem  <- compile a program to a RISC-V memory file
make compile_all                    <- compile every program at once (in parallel with -j)

# ---- Dump Files ---- #
make <my_program>.dump  <- disassembles compiled memory into RISC-V assembly dump files
make *.debug.dump       <- for a .c program, creates dump files with a debug flag
make dump_all           <- create all dump files at once (in parallel with -j)

# ---- Verdi ---- #
make <my_program>.verdi     <- run a program in verdi via simv
make <my_program>.syn.verdi <- run a program in verdi via syn.simv

# ---- Cleanup ---- #
make clean            <- remove per-run files and compiled executable files
make nuke             <- remove all files created from make rules
```
