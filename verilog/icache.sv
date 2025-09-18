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

    // ---- Cache storage ---- //

    logic valid;
    logic pending;  // Asked for mem[{tag, `CACHE_BLOCK_OFFSET_BITS'h0}] from memory
    logic [$bits(ADDR)-1:`CACHE_BLOCK_OFFSET_BITS] tag;
    MEM_BLOCK data;

    // ---- Addresses ---- //

    logic hit, insert;
    logic [$bits(ADDR)-1:`CACHE_BLOCK_OFFSET_BITS] proc2Icache_tag;
    logic [$bits(ADDR)-1:`CACHE_BLOCK_OFFSET_BITS] mem2Icache_tag;
    assign proc2Icache_tag = proc2Icache_addr[$bits(ADDR)-1:`CACHE_BLOCK_OFFSET_BITS];
    assign mem2Icache_tag  =  mem2Icache_addr[$bits(ADDR)-1:`CACHE_BLOCK_OFFSET_BITS];
    assign hit = valid && tag == proc2Icache_tag && proc2Icache_fetch;
    assign insert = pending && mem2Icache_valid && tag == mem2Icache_tag;

    // ---- Final outputs ---- //

    assign Icache2proc_valid = hit || insert;
    assign Icache2proc_data  = hit ? {96'b0, data.word_level[proc2Icache_addr[`CACHE_BLOCK_OFFSET_BITS-1:2]]}
         : {96'b0, mem2Icache_data.word_level[proc2Icache_addr[`CACHE_BLOCK_OFFSET_BITS-1:2]]}; // 4B instrs
    assign Icache2mem_fetch  = proc2Icache_fetch && !hit && !pending;
    assign Icache2mem_addr   = {proc2Icache_addr[31:`CACHE_BLOCK_OFFSET_BITS], `CACHE_BLOCK_OFFSET_BITS'h0};
    assign Icache2mem_size   = QUAD; // Size of 16B cache block

    // initial begin
    //     $monitor("%x %x %x %x %x %x %x %x %x", 
    //         proc2Icache_fetch, proc2Icache_addr, Icache2proc_valid, data, mem2Icache_data, 
    //         pending, mem2Icache_valid, tag, mem2Icache_tag);
    // end

    // ---- Cache state registers ---- //

    always_ff @(posedge clock) begin
        if (reset) begin
            valid   <= 1'b0;
            pending <= 1'b0;
            tag     <= 'hDEADBEEF;
            data    <= 'hDEADDEADDEADBEEF;
        end else begin
            if (insert) begin
                valid   <= 1'b1;
                data    <= mem2Icache_data;
                pending <= 1'b0;
            end else if (Icache2mem_fetch) begin
                valid   <= 1'b0;
                pending <= 1'b1;
                tag     <= proc2Icache_tag;
            end
        end
    end

endmodule // icache