// +FHDR============================================================================/
// Author       : hjie
// Creat Time   : 2024/10/31 09:46:19
// File Name    : tdpram_core_v01.v
// Module Ver   : Vx.x
//
//
// All Rights Reserved
//
// ---------------------------------------------------------------------------------/
//
// Modification History:
// V1.0         initial
//
// -FHDR============================================================================/
// 
// tdpram_core_v01
//    |---
// 
`timescale 1ns/1ps

module tdpram_core_v01 #
(
    parameter                           DW  = 8                     , // It must be a multiple of 8.
    parameter                           AW = 8                      , // Must not be less than log2(PB_DW/PA_DW).
    parameter                           DEPTH = 2**AW               ,
    parameter                           U_DLY = 1                     // 
)
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    input                               clk_pa                      , 
    input                               clk_pb                      , 
    input                               rst_n                       ,
// ---------------------------------------------------------------------------------
// Port A Write Read
// ---------------------------------------------------------------------------------
    input                               pa_wr                       , 
    input                      [AW-1:0] pa_addr                     , 
    input                      [DW-1:0] pa_wdata                    , 
    output reg                 [DW-1:0] pa_rdata                    , 
// ---------------------------------------------------------------------------------
// Port B Write Read
// ---------------------------------------------------------------------------------
    input                               pb_wr                       , 
    input                      [AW-1:0] pb_addr                     , 
    input                      [DW-1:0] pb_wdata                    , 
    output reg                 [DW-1:0] pb_rdata                      
);

(* ram_style="block" *)reg                            [DW-1:0] mem [DEPTH-1:0]             ; 


always @ (posedge clk_pa) begin
    if(pa_wr)
        mem[pa_addr] <= #U_DLY pa_wdata;
    else
        ;
end

always @ (posedge clk_pb) begin
    if(pb_wr)
        mem[pb_addr] <= #U_DLY pb_wdata;
    else
        ;
end

always @ (posedge clk_pa) begin
    if(~rst_n)
        pa_rdata <= #U_DLY 'd0;
    else
        pa_rdata <= #U_DLY mem[pa_addr];
end
always @ (posedge clk_pb) begin
    if(~rst_n)
        pb_rdata <= #U_DLY 'd0;
    else
        pb_rdata <= #U_DLY mem[pb_addr];
end
endmodule














