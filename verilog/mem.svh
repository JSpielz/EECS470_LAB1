/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  mem.svh                                             //
//                                                                     //
//  Description :  This file defines macros and data structures used   //
//                 by the memory hierarchy.                            //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __MEM_SVH__
`define __MEM_SVH__
`timescale 1ns/100ps

//////////////////////////////////
// ---- Memory Definitions ---- //
//////////////////////////////////

// NOTE: the global CLOCK_PERIOD is defined in the Makefile
`define MEM_LATENCY_IN_CYCLES ((100.0-`CLOCK_PERIOD)/`CLOCK_PERIOD+0.49999)

typedef logic [31:0] ADDR;
`define CACHE_BLOCK_SIZE_IN_BYTES 16
`define CACHE_BLOCK_OFFSET_BITS 4 //$clog2(`CACHE_BLOCK_SIZE_IN_BYTES)
`define MEM_SIZE_IN_BYTES (64*1024)
`define MEM_CACHE_LINES   (`MEM_SIZE_IN_BYTES/`CACHE_BLOCK_SIZE_IN_BYTES)

typedef enum logic [2:0] {
    BYTE   = 3'h0,
    HALF   = 3'h1,
    WORD   = 3'h2,
    DOUBLE = 3'h3,
    QUAD   = 3'h4
} MEM_SIZE;

// Memory bus commands
typedef enum logic [1:0] {
    MEM_NONE   = 2'h0,
    MEM_LOAD   = 2'h1,
    MEM_STORE  = 2'h2
} MEM_COMMAND;

// A memory or cache block
typedef union packed {
    logic [`CACHE_BLOCK_SIZE_IN_BYTES   -1:0]  [7:0] byte_level;
    logic [`CACHE_BLOCK_SIZE_IN_BYTES/ 2-1:0] [15:0] half_level;
    logic [`CACHE_BLOCK_SIZE_IN_BYTES/ 4-1:0] [31:0] word_level;
    logic [`CACHE_BLOCK_SIZE_IN_BYTES/ 8-1:0] [63:0] dbbl_level;
    logic [`CACHE_BLOCK_SIZE_IN_BYTES/16-1:0][127:0] quad_level;
} MEM_BLOCK;

// memory tags represent a unique id for outstanding mem transactions
// 0 is a sentinel value and is not a valid tag
`define NUM_MEM_TAGS 15
typedef logic [3:0] MEM_TAG;

`endif // __MEM_SVH__
