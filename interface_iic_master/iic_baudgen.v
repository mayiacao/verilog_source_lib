// +FHDR============================================================================/
// Author       : hjie
// Creat Time   : 2023/10/18 11:46:11
// File Name    : iic_baudgen.v
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
// iic_baudgen
//    |---
// 
`timescale 1ns/1ps

module iic_baudgen #
(
	parameter 						U_DLY = 1	                ,
    parameter                       DW = 16     
)
(
// ---------------------------------------------------------------------------------
// Clock & Reset
// ---------------------------------------------------------------------------------
    input                           clk_sys                     , 
    input                           rst_n                       , 
// ---------------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------------
    input                  [DW-1:0] baud_data                   , 
// ---------------------------------------------------------------------------------
// Baud Pulse
// ---------------------------------------------------------------------------------
    output reg                      baud_en                       
);

reg                        [DW-1:0] baud_cnt                    ; 

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        baud_cnt <= #U_DLY {DW{1'b0}};
    else
        begin
            if(baud_cnt < baud_data)
                baud_cnt <= #U_DLY baud_cnt + {{(DW-1){1'b0}},1'b1};
            else
                baud_cnt <= #U_DLY {DW{1'b0}};
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        baud_en <= #U_DLY 1'b0;
    else
        begin
            if(baud_cnt >= baud_data)
                baud_en <= #U_DLY 1'b1;
            else
                baud_en <= #U_DLY 1'b0;
        end 
end

endmodule 




