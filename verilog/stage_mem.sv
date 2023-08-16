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
    input [`XLEN-1:0]   Dmem2proc_data,

    output logic [`XLEN-1:0] mem_result_out, // outgoing instruction result (to MEM/WB)
    output logic [1:0]       proc2Dmem_command, // the memory command
    output MEM_SIZE          proc2Dmem_size,    // size of data to read or write
    output logic [`XLEN-1:0] proc2Dmem_addr,    // Address sent to data-memory
    output logic [`XLEN-1:0] proc2Dmem_data     // Data sent to data-memory
);

    // Determine the command that must be sent to mem
    assign proc2Dmem_command =
        (ex_mem_reg.wr_mem & ex_mem_reg.valid) ? BUS_STORE :
        (ex_mem_reg.rd_mem & ex_mem_reg.valid) ? BUS_LOAD :
        BUS_NONE;

    // only the 2 LSB to determine the size;
    assign proc2Dmem_size = MEM_SIZE'(ex_mem_reg.mem_size[1:0]);

    // The memory address is calculated by the ALU
    assign proc2Dmem_data = ex_mem_reg.rs2_value;

    assign proc2Dmem_addr = ex_mem_reg.alu_result;
    // Assign the result-out for next stage
    always_comb begin
        mem_result_out = ex_mem_reg.alu_result;
        if (ex_mem_reg.rd_mem) begin
            if (~ex_mem_reg.mem_size[2]) begin //is this an signed/unsigned load?
                if (ex_mem_reg.mem_size[1:0] == 2'b0)
                    mem_result_out = {{(`XLEN-8){Dmem2proc_data[7]}}, Dmem2proc_data[7:0]};
                else if (ex_mem_reg.mem_size[1:0] == 2'b01)
                    mem_result_out = {{(`XLEN-16){Dmem2proc_data[15]}}, Dmem2proc_data[15:0]};
                else mem_result_out = Dmem2proc_data;
            end else begin
                if (ex_mem_reg.mem_size[1:0] == 2'b0)
                    mem_result_out = {{(`XLEN-8){1'b0}}, Dmem2proc_data[7:0]};
                else if (ex_mem_reg.mem_size[1:0] == 2'b01)
                    mem_result_out = {{(`XLEN-16){1'b0}}, Dmem2proc_data[15:0]};
                else mem_result_out = Dmem2proc_data;
            end
        end
    end

    // if we are in 32 bit mode, then we should never load a double word sized data
    assert property (@(negedge clock) (`XLEN == 32) && ex_mem_reg.rd_mem |-> proc2Dmem_size != DOUBLE);

endmodule // module stage_mem
