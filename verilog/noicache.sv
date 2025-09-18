/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  icache.sv                                           //
//                                                                     //
//  Description :  The instruction cache module that reroutes memory   //
//                 accesses to decrease contention.                    //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "mem.svh"

module icache (
    input clock,
    input reset,

    // From memory
    input ADDR      mem2Icache_addr,
    input MEM_BLOCK mem2Icache_data,
    input           mem2Icache_valid,

    // From processor fetch
    input ADDR proc2Icache_addr,
    input      proc2Icache_fetch,

    // To memory
    output ADDR     Icache2mem_addr,
    output          Icache2mem_fetch,
    output MEM_SIZE Icache2mem_size,

    // To processor fetch
    output MEM_BLOCK Icache2proc_data, // mem[proc2Icache_addr]
    output           Icache2proc_valid
);
    // ---- Final outputs ---- //

    assign Icache2proc_valid = mem2Icache_valid;
    assign Icache2proc_data  = mem2Icache_data;
    assign Icache2mem_fetch  = proc2Icache_fetch;
    assign Icache2mem_addr   = proc2Icache_addr;
    assign Icache2mem_size   = WORD;  // instructions are 4B

endmodule // icache