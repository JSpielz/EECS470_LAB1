/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename : mem.sv                                                //
//                                                                     //
// Description : This is a clock-based latency, pipelined memory with  //
//               3 buses (address in, data in, data out) and a limit   //
//               on the number of outstanding memory operations        //
//               allowed at any time.                                  //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "mem.svh"

module mem (
    input           clock,         // Memory clock
    input ADDR      proc2mem_addr, // address for current command
                                   // support for memory model with byte level addressing
    input MEM_BLOCK proc2mem_data, // store data for current command
`ifndef CACHE_MODE
    input MEM_SIZE  proc2mem_size, // BYTE, HALF, WORD or DOUBLE
`endif
    input [1:0]     proc2mem_command, // `MEM_NONE `MEM_LOAD or `MEM_STORE

    output MEM_TAG   mem2proc_transaction_tag, // Memory tag for current transaction (0 = can't accept)
    output MEM_BLOCK mem2proc_data,            // Data for a load
    output MEM_TAG   mem2proc_data_tag,        // Tag for finished transactions (0 = no value)
    output ADDR      mem2proc_data_addr        // (fake) address for returned data
);

    logic [63:0] unified_memory [(`MEM_SIZE_IN_BYTES/8)-1:0];

    MEM_BLOCK   next_mem2proc_data;
    MEM_TAG     next_mem2proc_transaction_tag, next_mem2proc_data_tag;
    ADDR        next_mem2proc_addr;

    wire [31:`CACHE_BLOCK_OFFSET_BITS] block_addr = proc2mem_addr[31:`CACHE_BLOCK_OFFSET_BITS];
    wire [`CACHE_BLOCK_OFFSET_BITS-1:0] byte_addr = proc2mem_addr[`CACHE_BLOCK_OFFSET_BITS-1:0];

    ADDR         loaded_addr     [`NUM_MEM_TAGS:1];
    logic [63:0] loaded_data     [`NUM_MEM_TAGS:1];
    logic [15:0] cycles_left     [`NUM_MEM_TAGS:1];
    logic        waiting_for_bus [`NUM_MEM_TAGS:1];

    logic acquire_tag, bus_filled, valid_address;

    MEM_BLOCK load_data;

`ifndef CACHE_MODE
    MEM_BLOCK block;
`endif

    // Implement the Memory function
    always @(negedge clock) begin
        next_mem2proc_transaction_tag = 4'b0;
        next_mem2proc_data            = 64'bx;
        next_mem2proc_data_tag        = 4'b0;

`ifdef CACHE_MODE
        valid_address = (proc2mem_addr[`CACHE_BLOCK_OFFSET_BITS-1:0] == `CACHE_BLOCK_OFFSET_BITS'b0) && (proc2mem_addr < `MEM_SIZE_IN_BYTES);
        if (valid_address) begin
            if (proc2mem_command == MEM_LOAD) begin
                load_data.dbbl_level[0] = unified_memory[{block_addr, 1'h0}];
                load_data.dbbl_level[1] = unified_memory[{block_addr, 1'h1}];
            end else if (proc2mem_command == MEM_STORE) begin
                unified_memory[{block_addr, 1'h0}] = proc2mem_data.dbbl_level[0];
                unified_memory[{block_addr, 1'h1}] = proc2mem_data.dbbl_level[1];
            end
        end
`else
        valid_address = (proc2mem_addr < `MEM_SIZE_IN_BYTES);
        if (valid_address) begin
            // filling up the block data
            block.dbbl_level[0] = unified_memory[{block_addr, 1'h0}];
            block.dbbl_level[1] = unified_memory[{block_addr, 1'h1}];
            if (proc2mem_command == MEM_LOAD) begin
                case (proc2mem_size)
                    BYTE:   load_data = {{(`CACHE_BLOCK_SIZE_IN_BYTES-1){8'b0}}, block.byte_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:0]]};
                    HALF:   load_data = {{(`CACHE_BLOCK_SIZE_IN_BYTES-2){8'b0}}, block.half_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:1]]};
                    WORD:   load_data = {{(`CACHE_BLOCK_SIZE_IN_BYTES-4){8'b0}}, block.word_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:2]]};
                    DOUBLE: load_data = {{(`CACHE_BLOCK_SIZE_IN_BYTES-8){8'b0}}, block.dbbl_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:3]]};
                    QUAD:   load_data = block;
                endcase
            end else if (proc2mem_command == MEM_STORE) begin
                case (proc2mem_size)
                    BYTE:   block.byte_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:0]] = proc2mem_data[7:0];
                    HALF:   block.half_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:1]] = proc2mem_data[15:0];
                    WORD:   block.word_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:2]] = proc2mem_data[31:0];
                    DOUBLE: block.dbbl_level[byte_addr[`CACHE_BLOCK_OFFSET_BITS-1:3]] = proc2mem_data[63:0];
                    QUAD:   block                                                     = proc2mem_data;
                endcase
                unified_memory[{block_addr, 1'h0}] = block.dbbl_level[0];
                unified_memory[{block_addr, 1'h1}] = block.dbbl_level[1];
            end
        end
`endif // CACHE_MODE

        bus_filled  = 1'b0;
        acquire_tag = valid_address && (proc2mem_command == MEM_LOAD ||
                                        proc2mem_command == MEM_STORE);

        for (int i = 1; i <= `NUM_MEM_TAGS; i = i+1) begin
            if (cycles_left[i] > 16'd0) begin
                cycles_left[i] = cycles_left[i] - 16'd1;

            end else if (acquire_tag && !waiting_for_bus[i]) begin
                next_mem2proc_transaction_tag = i;
                acquire_tag    = 1'b0;
                cycles_left[i] = `MEM_LATENCY_IN_CYCLES;
                // must add support for random lantencies though this could be
                // done via a non-number definition for this macro
                if (proc2mem_command == MEM_LOAD) begin
                    waiting_for_bus[i] = 1'b1;
                    loaded_data[i] = load_data;
                    loaded_addr[i] = proc2mem_addr;
                end
            end

            if ((cycles_left[i] == 16'd0) && waiting_for_bus[i] && !bus_filled) begin
                bus_filled         = 1'b1;
                waiting_for_bus[i] = 1'b0;
                next_mem2proc_data_tag = i;
                next_mem2proc_data     = loaded_data[i];
                next_mem2proc_addr     = loaded_addr[i];
            end
        end
        mem2proc_transaction_tag <= next_mem2proc_transaction_tag;
        mem2proc_data            <= next_mem2proc_data;
        mem2proc_data_tag        <= next_mem2proc_data_tag;
        mem2proc_data_addr       <= next_mem2proc_addr;
    end

    // Initialise the entire memory
    initial begin
        // This posedge is very important, it ensures that we don't enter a race
        // condition with the negedge driven block above.
        @(posedge clock);
        for (int i = 0; i < `MEM_CACHE_LINES; i = i+1) begin
            unified_memory[i] = {`CACHE_BLOCK_SIZE_IN_BYTES{8'h0}};
        end
        mem2proc_transaction_tag = 4'd0;
        mem2proc_data_tag  = 4'd0;
        mem2proc_data      = 64'bx;
        mem2proc_data_addr = 'x;
        for (int i = 1; i <= `NUM_MEM_TAGS; i = i+1) begin
            loaded_data[i] = 64'bx;
            cycles_left[i] = 16'd0;
            waiting_for_bus[i] = 1'b0;
        end
    end

endmodule // module mem
