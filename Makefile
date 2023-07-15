##########################
# ---- Introduction ---- #
##########################

# Welcome to the Project 3 VeriSimpleV Processor makefile!
# this file will build a fully synthesizable RISC-V verilog processor
# and is an extended version of the EECS 470 standard makefile

# NOTE: this file should need no changes for project 3
# but it will be reused for project 4, where you will likely add your own new files and functionality

# reference table of all make targets:

# make  <- runs the default target, set explicitly below as 'make rv32_fib_rec.out'
.DEFAULT_GOAL = rv32_fib_rec.out
# ^ this overrides using the first listed target as the default

# ---- Program Execution ---- #
# these are your main commands for running programs and generating output
# make <my_program>.out     <- run a program on simv and generate .out, .wb, and .ppln files in 'output/'
# make <my_program>.syn.out <- run a program on syn_simv and do the same
# make simulate_all         <- run every program on simv at once (in parallel with -j)
# make simulate_all_syn     <- run every program on syn_simv at once (in parallel with -j)

# ---- Executable Compilation ---- #
# make simv      <- compiles simv from the testbench and SOURCES
# make syn_simv  <- compiles syn_simv from the testbench and *.vg SYNTH_FILES
# make *.vg      <- synthesize the top level module in SOURCES for use in syn_simv
# make slack     <- a phony command to print the slack of any synthesized modules

# ---- Program Memory Compilation ---- #
# NOTE: programs to run are in the programs/ directory
# make <my_program>.mem <- creates the program memory file output/<my_program>.mem for running on simv etc
# make compile_all      <- compile every program at once (in parallel with -j)

# ---- Dump Files ---- #
# make <my_program>.dump_numeric <- creates a numeric dump file for viewing the disassembled source code
# make <my_program>.dump_abi     <- creates an abi dump file for viewing the disassembled source code
# make <my_program>.dump         <- creates both of the above files at once and is easier to type :)
# make <my_program>.debug.dump_* <- creates dump files for C programs that intersperses the C source code
# make dump_all                  <- create all dump files at once (in parallel with -j)

# ---- Verdi ---- #
# make <my_program>.verdi     <- run a program in the verdi debugger via simv
# make <my_program>.syn.verdi <- the same via syn_simv

# ---- Visual Debugger ---- #
# make <my_program>.vis <- run a program on the project 3 vtuber visual debugger!
# make vis_simv         <- compile the vtuber executable from visual_testbench.sv and the SOURCES

# ---- Legacy Build System ---- #
# the legacy system for compiling programs is included
# I discourage using it, but it does exist if needed
# make sim, syn, verdi, verdi_syn, vis <- run as expected, using the program in the SOURCE variable

# ---- Cleanup ---- #
# make clean            <- remove per-run files and compiled executable files
# make nuke             <- remove all files created from make rules
# make clean_run_files  <- remove per-run output files
# make clean_exe        <- remove compiled executable files
# make clean_synth      <- remove generated synthesis files
# make clean_output_dir <- remove the entire output/ directory)
# make clean_programs   <- remove program memory and dump files (implicit in clean_output_dir)

# credits:
# VeriSimpleV was adapted by Jielun Tan for RISC-V from the original 470 VeriSimple Alpha language processor
# however I cannot find the original authors or the major editors of the project :/
# so to everyone I can't credit: thank you!
# the current layout of the Makefile was made by Ian Wrzesinski in 2023
# VeriSimpleV has also been edited by at least:
# Nevil Pooniwala, Xueyang Liu, Cassie Jones, and James Connolly

#########################
# ---- Directories ---- #
#########################

# VPATH is a built-in Make variable that lets Make search folders to find dependencies and targets
# setting it simplifies many of our make rules and increases readability with our new directory format
VPATH = synth:testbench:programs:verilog:output

# some targets in this makefile are built in the 'output/' directory for organization
# this rule creates it if it doesn't exist yet (since the entire directory might be deleted by 'make nuke')
# NOTE: usually placed after the pipe "|" as a dependency to avoid matching the "$^" automatic variable
output:
	mkdir -p output

######################################################
# ---- Compilation Commands and Other Variables ---- #
######################################################

# these are various build flags for different parts of the makefile, VCS and LIB should be
# familiar, but there are new variables for supporting the compilation of assembly and C
# source programs into riscv machine code files to be loaded into the processor's memory

# don't be afraid to change these, but be diligent about testing changes and using git commits
# there should be no need to change anything for project 3

# this is a global clock period variable used in the tcl script and referenced in testbenches
export CLOCK_PERIOD = 30.0

# the Verilog Compiler command and arguments
VCS = SW_VCS=2020.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 -kdb -lca \
      -debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
# a SYNTH define is added when compiling for synthesis that can be used in testbenches

# remove certain warnings that generate MB of text but can be safely ignored
VCS_BAD_WARNINGS = +warn=noTFIPC +warn=noDEBUG_DEP +warn=noENUMASSIGN

# a reference library of standard structural cells that we link against when synthesizing
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

# the EECS 470 synthesis script
TCL_SCRIPT = 470synth.tcl

# The following are new in project 3:

# C and assembly compilation files. These link and setup the runtime for the programs
CRT = programs/crt.s
LINKERS = programs/linker.lds
ASLINKERS = programs/aslinker.lds

# you might need to update these build flags for project 4, but make sure you know what they do:
# https://gcc.gnu.org/onlinedocs/gcc/RISC-V-Options.html
CFLAGS     = -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -std=gnu11 -mstrict-align -mno-div
# adjust the optimization if you want programs to run faster; this may obfuscate/change their instructions
OFLAGS     = -O0
ASFLAGS    = -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align
OBJFLAGS   = -SD -M no-aliases
OBJCFLAGS  = --set-section-flags .bss=contents,alloc,readonly
OBJDFLAGS  = -SD -M numeric,no-aliases
DEBUG_FLAG = -g

# NOTE: change this and update the below variables if you aren't using a caen machine
CAEN = 1
ifeq (1, $(CAEN))
    GCC     = riscv gcc
    OBJCOPY = riscv objcopy
    OBJDUMP = riscv objdump
    AS      = riscv as
    ELF2HEX = riscv elf2hex
else
    GCC     = riscv64-unknown-elf-gcc
    OBJCOPY = riscv64-unknown-elf-objcopy
    OBJDUMP = riscv64-unknown-elf-objdump
    AS      = riscv64-unknown-elf-as
    ELF2HEX = elf2hex
endif

####################################
# ---- Executable Compilation ---- #
####################################

# NOTE: the executables are not the only things you need to compile
# you must also create a .mem file for each program you run
# which will be loaded into mem.sv by the testbench on startup

# To actually run a program on simv or syn_simv, see the program compilation section below
# you can also use the legacy targets 'sim' and 'syn' that use the legacy program.mem file

# NOTE: we're able to use these filenames without directories due to the VPATH declaration above
# Make will automatically expand these to their actual paths when used as dependencies
HEADERS = sys_defs.svh \
          ISA.svh

TESTBENCH = testbench.sv \
            pipe_print.c \
            mem.sv

# you could simplify this line with $(wildcard verilog/*.sv) - but the manual way is more explicit
SOURCES = pipeline.sv \
          regfile.sv \
          stage_if.sv \
          stage_id.sv \
          stage_ex.sv \
          stage_mem.sv \
          stage_wb.sv

SYNTH_FILES = synth/pipeline.vg

# the normal simulation executable will run your testbench on the original modules
simv: $(TESTBENCH) $(SOURCES) | $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the simulation executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $^ -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)
# NOTE: we reference variables with $(VARIABLE), and can make use of the automatic variables: ^, @, <, etc
# see: https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html for explanations

%.vg: $(SOURCES) $(TCL_SCRIPT) $(HEADERS)
	@$(call PRINT_COLOR, 5, synthesizing the $* module)
	@$(call PRINT_COLOR, 3, this might take a while...)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	# pipefail causes the command to exit on failure even though it's piping to tee
	set -o pipefail; cd synth && MODULE=$* SOURCES="$(SOURCES)" dc_shell-t -f $(TCL_SCRIPT) | tee pipeline_synth.out
	@$(call PRINT_COLOR, 6, finished synthesizing $@)
# this also generates many other files, see the tcl script's introduction for info on each of them

# the synthesis executable runs your testbench on the synthesized versions of your modules
syn_simv: $(TESTBENCH) $(SYNTH_FILES) | $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the synthesis executable $@)
	$(VCS) +define+SYNTH $^ $(LIB) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)
# we need to link the synthesized modules against LIB, so this differs slightly from simv above
# but we still compile with the same non-synthesizable testbench
# NOTE: LIB has to come after the other sources as it doesn't define a timescale, and must inherit it from a previous module

# a phony target to view the slack in the *.rep synthesis report file
slack:
	grep --color=auto "slack" synth/*.rep
.PHONY: slack

########################################
# ---- Program Memory Compilation ---- #
########################################

# this section will compile programs into .mem files to be loaded into memory
# you start with either an assembly or C program in the programs/ directory
# those compile into a .elf link file via the riscv assembler or compiler
# then that link file is converted to a .mem hex file

# find the test program files and separate them based on suffix of .s or .c
# remove crt.s from ASSEMBLY as it is not actually a program
ASSEMBLY := $(filter-out $(CRT),$(wildcard programs/*.s))
C_CODE   := $(wildcard programs/*.c)

# concatenate ASSEMBLY and C_CODE to list every program
PROGRAMS := $(ASSEMBLY:programs/%.s=output/%) $(C_CODE:programs/%.c=output/%)
# NOTE: this is Make's pattern substitution syntax
# see: https://www.gnu.org/software/make/manual/html_node/Text-Functions.html#Text-Functions
# this reads as: $(var:pattern=replacement)
# a percent sign '%' in pattern is as a wildcard, and can be reused in the replacement
# if you don't include the percent it automatically attempts to replace just the suffix of the input

# make link files from assembly code (matches the legacy 'assemble' target)
ASSEMBLY_ELF = $(ASSEMBLY:programs/%.s=output/%.elf)
$(ASSEMBLY_ELF): output/%.elf: programs/%.s | $(ASLINKERS) output
	@$(call PRINT_COLOR, 5, compiling assembly file $*.s)
	$(GCC) $(ASFLAGS) $^ -T $(ASLINKERS) $(CUSTOM_ASM_ARGS) -o $@
# NOTE: this uses a 'static pattern rule' to match a list of known targets to a pattern
# and then generates the correct rule based on the patter, where % and $* match
# so for the target 'output/sampler.elf' the % matches 'sampler' and searches the source 'programs/sampler.s'
# see: https://www.gnu.org/software/make/manual/html_node/Static-Usage.html

# make link files from C source code (matches the legacy 'compile' target)
C_CODE_ELF = $(C_CODE:programs/%.c=output/%.elf)
$(C_CODE_ELF): output/%.elf: $(CRT) programs/%.c | $(LINKERS) output
	@$(call PRINT_COLOR, 5, compiling C code file $*.c)
	$(GCC) $(CFLAGS) $(OFLAGS) $^ -T $(LINKERS) $(CUSTOM_C_ARGS) -o $@

# turn any link file into a hex memory file ready for the testbench (matches the legacy 'hex' target)
%.mem: %.elf
	$(ELF2HEX) 8 8192 $< > $@
	@$(call PRINT_COLOR, 6, created memory file $@)
	@$(call PRINT_COLOR, 3, NOTE - to see the disassembled code)
	@$(call PRINT_COLOR, 3, make $*.dump_numeric or $*.dump_abi)
	@$(call PRINT_COLOR, 3, for .c sources - make .debug.dump_\*)

# NOTE: the .elf commands only compile single file sources, however it's not difficult to add multi-source files
# if you had a file 'programs/multi.c' that needed to compile with 'programs/helper1.c' and
# 'programs/obj_helper2.o', you would uncomment the following line:
#     multi.elf: helper1.c obj_helper2.o
# this adds the dependences to the $^ variable used in the command above (also why LINKERS is after the |)
# NOTE: I've also included CUSTOM_ASM_ARGS and CUSTOM_C_ARGS variables that you can override at
# the command line in case you need more complicated functionality:
# make multi.elf CUSTOM_C_ARGS="programs/helper1.c programs/obj_helper2.o -v -pipe etc"

# NOTE: I declare the .elf files as intermediate files here.
# Make will automatically rm intermediate files after they're used in a recipe
# and it won't remake them until their sources are updated or they're needed again
.INTERMEDIATE: $(ASSEMBLY_ELF) $(C_CODE_ELF)

# this command compiles all the programs at once
# NOTE: use 'make -j' to run multithreaded
compile_all: $(PROGRAMS:=.mem)
.PHONY: compile_all

########################
# ---- Dump Files ---- #
########################

# it can also be useful to look at dump files that represent the compiled riscv assembly code
# there are two types that are useful for debugging different things:
#   1. dump_numeric gives dump files where the registers use their numeric values, better for debugging
#      with verdi in the waveform view
#   2. dump_abi gives dump files where the registers use their named values as written in the sources
#      this is better for testing that your assembly matches a source file you wrote
# these match the legacy 'disassemble' target (dump_abi is .dump, and dump_numeric is .debug.dump)

# this creates the <my_program>.debug.elf targets, which can be used in: 'make <my_program>.debug.dump_*'
# these are useful for the C sources because the debug flag makes the assembly more understandable
# because it includes some of the original C operations and function/variable names
# NOTE: static pattern make rules generally need their dependencies to be above them in the makefile
# otherwise you can get the 'No rule to make target' error, due to being unable to find a dependency
DEBUG_C_PROGRAMS = $(C_CODE:programs/%.c=output/%.debug)
$(DEBUG_C_PROGRAMS:=.elf): output/%.debug.elf: programs/%.c $(CRT) | $(LINKERS) output
	@$(call PRINT_COLOR, 5, making debug C code link file $*.c)
	$(GCC) $(DEBUG_FLAG) $(CFLAGS) $(OFLAGS) $^ -T $(LINKERS) $(CUSTOM_C_ARGS) -o $@

DUMP_PROGRAMS = $(PROGRAMS) $(DEBUG_C_PROGRAMS)

# 'make <my_program>.dump_numeric'
$(DUMP_PROGRAMS:=.dump_numeric): %.dump_numeric: %.elf
	@$(call PRINT_COLOR, 5, disassembling $<)
	$(OBJDUMP) $(OBJDFLAGS) $< > $@
	@$(call PRINT_COLOR, 6, created numeric dump file $@)

# 'make <my_program>.dump_abi'
$(DUMP_PROGRAMS:=.dump_abi): %.dump_abi: %.elf
	@$(call PRINT_COLOR, 5, disassembling $<)
	$(OBJDUMP) $(OBJFLAGS) $< > $@
	@$(call PRINT_COLOR, 6, created abi dump file $@)

# 'make <my_program>.dump' will create both files at once!
$(DUMP_PROGRAMS:=.dump): %.dump: %.dump_numeric %.dump_abi
.PHONY: %.dump

# this command creates all dump files at once
# NOTE: use 'make -j' to run multithreaded
dump_all: $(DUMP_PROGRAMS:=.dump_abi) $(DUMP_PROGRAMS:=.dump_numeric)
.PHONY: dump_all

###############################
# ---- Program Execution ---- #
###############################

# run one of the executables (simv/syn_simv) using the chosen program
# e.g. 'make sampler.out' does the following from a clean directory:
#   1. compiles simv
#   2. compiles programs/sampler.s into its .elf and then .mem files (in output/)
#   3. runs ./simv +MEMORY=output/sampler.mem +WRITEBACK=output/sampler.wb +PIPELINE=output/sampler.ppln
#   4. which creates the sampler.out, sampler.wb, and sampler.ppln files in output/
# the same can be done for synthesis by doing 'make sampler.syn.out'
# which will also create .syn.wb and .syn.ppln files in output/

# NOTE: see the explanation of this syntax above at ASSEMBLY_ELF
$(PROGRAMS:=.out): %.out: simv %.mem
	@$(call PRINT_COLOR, 5, running simv with $*.mem)
	./simv +MEMORY=$*.mem +WRITEBACK=$*.wb +PIPELINE=$*.ppln > $@
	@$(call PRINT_COLOR, 6, finished running $*.mem)
	@$(call PRINT_COLOR, 2, output is in $@ $*.wb and $*.ppln)

# this does the same as simv, but adds .syn to the output files and compiles syn_simv instead
# run synthesis with: 'make <my_program>.syn.out'
$(PROGRAMS:=.syn.out): %.syn.out: syn_simv %.mem
	@$(call PRINT_COLOR, 5, running syn_simv with $*.mem)
	@$(call PRINT_COLOR, 3, this might take a while...)
	./syn_simv +MEMORY=$*.mem +WRITEBACK=$*.syn.wb +PIPELINE=$*.syn.ppln > $@
	@$(call PRINT_COLOR, 6, finished running $*.mem)
	@$(call PRINT_COLOR, 2, "output is in $@ $*.syn.wb and $*.syn.ppln")

# these commands run all the programs on simv or syn_simv in one command
# NOTE: use 'make -j' to run multithreaded
simulate_all: $(PROGRAMS:=.out) | compile_all simv
simulate_all_syn: $(PROGRAMS:=.syn.out) | compile_all syn_simv
.PHONY: simulate_all simulate_all_syn

# NOTE: I'm using ordered prerequisites here (via the | character) so that make first compiles
# everything before it runs anything, otherwise the output is much messier
# see: https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html

###################
# ---- Verdi ---- #
###################

# run verdi on a program with: 'make <my_program>.verdi' or 'make <my_program>.syn.verdi'

# this creates a directory verdi will use if it doesn't exist yet
verdi_dir:
	mkdir -p /tmp/$${USER}470
.PHONY: verdi_dir

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

# these are phony targets because they don't produce output files and should just run every time
$(PROGRAMS:=.verdi): %.verdi: simv %.mem novas.rc verdi_dir
	./simv -gui=verdi +MEMORY=$*.mem +WRITEBACK=/dev/null +PIPELINE=/dev/null

$(PROGRAMS:=.syn.verdi): %.syn.verdi: syn_simv %.mem novas.rc verdi_dir
	./syn_simv -gui=verdi +MEMORY=$*.mem +WRITEBACK=/dev/null +PIPELINE=/dev/null
.PHONY: %.verdi

# these targets use the legacy program.mem system and load the program in SOURCE below
verdi: simv novas.rc verdi_dir program.mem $(SOURCE)
	./simv -gui=verdi
verdi_syn: syn_simv novas.rc verdi_dir program.mem $(SOURCE)
	./syn_simv -gui=verdi
.PHONY: verdi verdi_syn

#############################
# ---- Visual Debugger ---- #
#############################

# this is the visual debugger for project 3, an extremely helpful tool, try it out!
# compile and run the visual debugger on a program with: 'make <my_program>.vis'

# the files to edit this (i.e. for making your own project 4 visual debugger)
# are the visual_testbench.sv and the visual_c_hooks.cpp files

# Don't ask me why we spell VisUal TestBenchER like this...
VTUBER = visual_testbench.v visual_c_hooks.cpp mem.sv
VISFLAGS = -lncurses

vis_simv: $(HEADERS) $(VTUBER) $(SOURCES)
	@$(call PRINT_COLOR, 5, compiling visual debugger testbench)
	$(VCS) $(VISFLAGS) $^ -o vis_simv
	@$(call PRINT_COLOR, 6, finished compiling visual debugger testbench)

# this is a phony target because it doesn't produce output files and should just run every time
$(PROGRAMS:=.vis): %.vis: vis_simv %.mem
	./vis_simv +MEMORY=$*.mem
.PHONY: %.vis

# this target uses the legacy program.mem system and loads the program in SOURCE below
vis: vis_simv program.mem $(SOURCE)
	./vis_simv
.PHONY: vis

###################################################
# ---- Legacy program.mem Compilation System ---- #
###################################################

# This is the old system for compiling programs, it required you to run
# 'make assembly' or 'make program' for Assembly vs C code SOURCE
# in order to to create "program.mem" which would be overwritten every time
# and which was hardcoded in the testbench.sv file for loading into memory.
# It would also create the hardcoded program.out, writeback.out, and pipeline.out
# files which would also be overwritten every time.
# This doesn't follow the way Make is meant to be used for creating files and
# the new compilation system should be used instead.
# However I only have so much time to edit both this and the autograder
# this semester, so I'm leaving this for backwards compatibility.
# running simv or syn_simv with no arguments will still load "program.mem" into memory

# the source program for the legacy system
# NOTE: you can override this at the command line like: 'make SOURCE=programs/<my_program.s/.c>'
# however this always recompiles program.mem which is cumbersome
SOURCE = programs/sampler.s

assemble: $(ASLINKERS)
	@$(call PRINT_COLOR, 5, compiling assembly file $(SOURCE))
	$(GCC) $(ASFLAGS) $(SOURCE) -T $(ASLINKERS) -o program.elf
	cp program.elf program.debug.elf

compile: $(CRT) $(LINKERS)
	@$(call PRINT_COLOR, 5, compiling C code file $(SOURCE))
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.elf
	$(GCC) $(CFLAGS) $(DEBUG_FLAG) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.debug.elf

disassemble: program.debug.elf
	@$(call PRINT_COLOR, 5, disassembling)
	$(OBJCOPY) $(OBJCFLAGS) program.debug.elf
	$(OBJDUMP) $(OBJFLAGS) program.debug.elf > program.dump
	$(OBJDUMP) $(OBJDFLAGS) program.debug.elf > program.debug.dump
	rm program.debug.elf

hex: program.elf
	$(ELF2HEX) 8 8192 program.elf > program.mem
	@$(call PRINT_COLOR, 6, created memory file program.mem)

.PHONY: assemble compile disassemble hex

# these targets combine the above three commands for compiling either an assembly or C code program
assembly: assemble disassemble hex # for an assembly program
program: compile disassemble hex # for a C code program
.PHONY: program assembly

# this allows you to compile SOURCE for running locally to test stdout or use gdb if you want to
debug_program:
	gcc -lm -g -std=gnu11 -DDEBUG $(SOURCE) -o debug_bin
.PHONY: debug_program

###############################################
# ---- Automatic program.mem Compilation ---- #
###############################################

# these targets are not part of the legacy compilation system, but I'm adding
# them here because they're a useful addition even if the new system is better.
# The dependencies on the Makefile itself are so that if you update SOURCE in
# the Makefile, it will still recompile program.mem

ifneq ($(filter %.s,$(SOURCE)),)
program.elf program.debug.elf: Makefile
	@$(call PRINT_COLOR, 5, compiling assembly file $(SOURCE))
	$(GCC) $(ASFLAGS) $(SOURCE) -T $(ASLINKERS) -o program.elf
else ifneq ($(filter %.c,$(SOURCE)),)
program.elf program.debug.elf: Makefile
	@$(call PRINT_COLOR, 5, compiling C code file $(SOURCE))
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.elf
endif
.INTERMEDIATE: program.elf

program.mem: program.elf
	$(ELF2HEX) 8 8192 $< > $@
	@$(call PRINT_COLOR, 6, created memory file $@)

# these two commands run program.mem on the compiled executable
sim: simv program.mem
	@$(call PRINT_COLOR, 5, running simv on $(SOURCE))
	./simv | tee program.out
	@$(call PRINT_COLOR, 6, finished running $(SOURCE))
	@$(call PRINT_COLOR, 2, "output is in program.out writeback.out and pipeline.out")

syn: syn_simv program.mem
	@$(call PRINT_COLOR, 5, running syn_simv on $(SOURCE))
	./syn_simv | tee syn_program.out
	@$(call PRINT_COLOR, 6, finished running $(SOURCE))
	@$(call PRINT_COLOR, 2, "output is in syn_program.out writeback.out and pipeline.out")
.PHONY: sim syn

#####################
# ---- Cleanup ---- #
#####################

# You should only clean your directory if you think something has built incorrectly
# or you want to prepare a clean directory for e.g. git (first check your .gitignore).
# Please avoid cleaning before every build. The point of a makefile is to
# automatically determine which targets have dependencies that are modified,
# and to re-build only those as needed; avoiding re-building everything everytime.

# 'make clean' removes build/output files, 'make nuke' removes all generated files
# 'make clean' does not remove .mem or .dump files
# clean_* commands clean certain groups of files

clean: clean_exe clean_run_files
	@$(call PRINT_COLOR, 6, note: clean is split into multiple commands you can call separately: $^)

# removes all extra synthesis files and the entire output directory
# use cautiously, this can cause hours of recompiling in project 4
nuke: clean clean_output_dir clean_synth
	@$(call PRINT_COLOR, 6, note: nuke is split into multiple commands you can call separately: $^)
	@$(call PRINT_COLOR, 6, you can also call clean_programs to just delete the .mem and .dump files)

clean_exe:
	@$(call PRINT_COLOR, 3, removing compiled executable files)
	rm -rf *simv *.daidir csrc *.key   # created by simv/syn_simv/vis_simv
	rm -rf vcdplus.vpd vc_hdrs.h       # created by simv/syn_simv/vis_simv
	rm -rf verdi* novas* *fsdb*        # verdi files
	rm -rf dve* inter.vpd DVEfiles     # old DVE debugger

clean_run_files:
	@$(call PRINT_COLOR, 3, removing per-run outputs)
	rm -rf output/*.out output/*.wb output/*.ppln
	rm -rf *.elf *.dump *.mem debug_bin # legacy program.mem compilation files
	rm -rf *.out                        # legacy execution outputs

clean_synth:
	@$(call PRINT_COLOR, 1, removing synthesis files)
	cd synth && rm -rf *.vg *_svsim.sv *.res *.rep *.ddc *.chk *.syn *.out *.db *.svf *.mr *.pvl command.log

clean_output_dir:
	@$(call PRINT_COLOR, 1, removing entire output directory)
	rm -rf output/

# implicit in clean_output_dir, and therefore nuke
clean_programs:
	@$(call PRINT_COLOR, 3, removing program memory files)
	rm -rf output/*.mem
	@$(call PRINT_COLOR, 3, removing dump files)
	rm -rf output/*.dump*

.PHONY: clean nuke clean_%

######################
# ---- Printing ---- #
######################

# this is a GNU Make function with two arguments: PRINT_COLOR(color: number, msg: string)
# it does all the color printing throughout the makefile
PRINT_COLOR = if [ -t 0 ]; then tput setaf $(1) ; fi; echo $(2); if [ -t 0 ]; then tput sgr0; fi
# colors: 0:black, 1:red, 2:green, 3:yellow, 4:blue, 5:magenta, 6:cyan, 7:white
# other numbers are valid, but aren't specified in the tput man page

# Make functions are called like this:
# $(call PRINT_COLOR,3,Hello World!)
# NOTE: adding '@' to the start of a line avoids printing the command itself, only the output
