/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_mem.sv                                        //
//                                                                     //
//  Description :  memory access (MEM) stage of the pipeline;          //
//                 this stage accesses memory for stores and loads,    //
//                 and selects the proper next PC value for branches   //
//                 based on the branch condition computed in the       //
//                 previous stage.                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "sys_defs.svh"

module stage_mem (
    input EX_MEM_PACKET ex_mem_reg,
    // the BUS_LOAD response will magically be present in the *same* cycle it's requested (0ns latency)
    // this will not be true in project 4 (100ns latency)
    input [`XLEN-1:0]   Dmem2proc_data,

    output MEM_WB_PACKET     mem_packet,
    output logic [1:0]       proc2Dmem_command, // the memory command
    output MEM_SIZE          proc2Dmem_size,    // size of data to read or write
    output logic [`XLEN-1:0] proc2Dmem_addr,    // Address sent to data-memory
    output logic [`XLEN-1:0] proc2Dmem_data     // Data sent to data-memory
);

    assign mem_packet.NPC          = ex_mem_reg.NPC;
    assign mem_packet.valid        = ex_mem_reg.valid;
    assign mem_packet.halt         = ex_mem_reg.halt;
    assign mem_packet.illegal      = ex_mem_reg.illegal;
    assign mem_packet.dest_reg_idx = ex_mem_reg.dest_reg_idx;
    assign mem_packet.take_branch  = ex_mem_reg.take_branch;

    assign proc2Dmem_command = (ex_mem_reg.valid && ex_mem_reg.wr_mem) ? BUS_STORE :
                               (ex_mem_reg.valid && ex_mem_reg.rd_mem) ? BUS_LOAD : BUS_NONE;
    assign proc2Dmem_size = MEM_SIZE'(ex_mem_reg.mem_size[1:0]);
    assign proc2Dmem_data = ex_mem_reg.rs2_value;
    assign proc2Dmem_addr = ex_mem_reg.alu_result; // memory address is calculated by the ALU

    always_comb begin
        mem_packet.result = ex_mem_reg.alu_result;
        if (ex_mem_reg.rd_mem) begin
            if (~ex_mem_reg.mem_size[2]) begin //is this an signed/unsigned load?
                if (ex_mem_reg.mem_size[1:0] == 2'b0)
                    mem_packet.result = {{(`XLEN-8){Dmem2proc_data[7]}}, Dmem2proc_data[7:0]};
                else if (ex_mem_reg.mem_size[1:0] == 2'b01)
                    mem_packet.result = {{(`XLEN-16){Dmem2proc_data[15]}}, Dmem2proc_data[15:0]};
                else mem_packet.result = Dmem2proc_data;
            end else begin
                if (ex_mem_reg.mem_size[1:0] == 2'b0)
                    mem_packet.result = {{(`XLEN-8){1'b0}}, Dmem2proc_data[7:0]};
                else if (ex_mem_reg.mem_size[1:0] == 2'b01)
                    mem_packet.result = {{(`XLEN-16){1'b0}}, Dmem2proc_data[15:0]};
                else mem_packet.result = Dmem2proc_data;
            end
        end
    end

    // if we are in 32 bit mode, then we should never load a double word sized data
    assert property (@(negedge clock) (`XLEN == 32) && ex_mem_reg.rd_mem |-> proc2Dmem_size != DOUBLE);

endmodule // module stage_mem
