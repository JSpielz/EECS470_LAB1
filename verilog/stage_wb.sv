/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_wb.sv                                         //
//                                                                     //
//  Description :   writeback (WB) stage of the pipeline;              //
//                  determine the destination register of the          //
//                  instruction and write the result to the register   //
//                  file (if not to the zero register), also reset the //
//                  NPC in the fetch stage to the correct next PC      //
//                  address.                                           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "sys_defs.svh"

module stage_wb (
    input             clock,               // system clock
    input             reset,               // system reset
    input [`XLEN-1:0] mem_wb_NPC,          // incoming instruction PC+4
    input [`XLEN-1:0] mem_wb_result,       // incoming instruction result
    input             mem_wb_take_branch,
    input [4:0]       mem_wb_dest_reg_idx, // dest index (ZERO_REG if no writeback)
    input             mem_wb_valid_inst,

    output logic [`XLEN-1:0] reg_write_data_out, // register writeback data
    output logic [4:0]       reg_write_idx_out,  // register writeback index
    output logic             reg_write_en_out    // register writeback enable
);

    // Select register writeback data:
    // ALU/MEM result, unless taken branch, in which case we write
    // back the old NPC as the return address. Note that ALL branches
    // and jumps write back the 'link' value, but those that don't
    // want it specify ZERO_REG as the destination.
    assign reg_write_data_out = (mem_wb_take_branch) ? mem_wb_NPC : mem_wb_result;

    assign reg_write_idx_out = mem_wb_dest_reg_idx;

    // this enable computation is sort of overkill since the reg file
    // also handles the `ZERO_REG case, but there's no harm in putting this here
    assign reg_write_en_out  = mem_wb_valid_inst && (mem_wb_dest_reg_idx != `ZERO_REG);

endmodule // module stage_wb
